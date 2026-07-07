import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Society structure (Phase 2, capabilities 11–16): wings, blocks, floors, units,
 * and unit occupancy history. Tenant-scoped by society_id.
 *
 * Integrity:
 *  - Unit number is unique within a society.
 *  - At most one CURRENT occupancy per (unit, relation) — partial unique index.
 *  - Setting an occupancy closes any prior current occupancy of the same relation
 *    and updates the unit's occupancy/ownership status.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const StructureService = {
  // ---- Wings ------------------------------------------------------------
  async createWing(societyId: string, input: { name: string; position?: number }) {
    try {
      const { rows } = await db.query(
        `INSERT INTO wings (society_id, name, position) VALUES ($1,$2,$3) RETURNING *`,
        [societyId, input.name, input.position || 0]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Wing name already exists", "ALREADY_EXISTS");
      throw e;
    }
  },
  async listWings(societyId: string) {
    const { rows } = await db.query(
      `SELECT * FROM wings WHERE society_id = $1 ORDER BY position ASC, name ASC`, [societyId]
    );
    return rows;
  },
  async updateWing(societyId: string, wingId: string, patch: { name?: string; position?: number; isActive?: boolean }) {
    const { rows } = await db.query(
      `UPDATE wings SET name = COALESCE($3, name), position = COALESCE($4, position),
              is_active = COALESCE($5, is_active), updated_at = now()
        WHERE id = $1 AND society_id = $2 RETURNING *`,
      [wingId, societyId, patch.name ?? null, patch.position ?? null, patch.isActive ?? null]
    );
    if (!rows[0]) throw err("Wing not found", "NOT_FOUND");
    return rows[0];
  },

  // ---- Blocks -----------------------------------------------------------
  async createBlock(societyId: string, input: { name: string; wingId?: string; position?: number }) {
    try {
      const { rows } = await db.query(
        `INSERT INTO blocks (society_id, wing_id, name, position) VALUES ($1,$2,$3,$4) RETURNING *`,
        [societyId, input.wingId || null, input.name, input.position || 0]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Block name already exists", "ALREADY_EXISTS");
      if (e.code === "23503") throw err("Wing not found", "NOT_FOUND");
      throw e;
    }
  },
  async listBlocks(societyId: string, opts: { wingId?: string } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.wingId) { params.push(opts.wingId); where += ` AND wing_id = $${params.length}`; }
    const { rows } = await db.query(`SELECT * FROM blocks WHERE ${where} ORDER BY position ASC, name ASC`, params);
    return rows;
  },

  // ---- Floors -----------------------------------------------------------
  async createFloor(societyId: string, input: { blockId?: string; label: string; position?: number }) {
    const { rows } = await db.query(
      `INSERT INTO floors (society_id, block_id, label, position) VALUES ($1,$2,$3,$4) RETURNING *`,
      [societyId, input.blockId || null, input.label, input.position || 0]
    );
    return rows[0];
  },
  async listFloors(societyId: string, opts: { blockId?: string } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.blockId) { params.push(opts.blockId); where += ` AND block_id = $${params.length}`; }
    const { rows } = await db.query(`SELECT * FROM floors WHERE ${where} ORDER BY position ASC`, params);
    return rows;
  },

  // ---- Units ------------------------------------------------------------
  async createUnit(
    societyId: string,
    input: {
      number: string; wingId?: string; blockId?: string; floorId?: string;
      unitType?: string; areaSqft?: number; maintenanceWeight?: number; ownershipStatus?: string;
    }
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO units (society_id, wing_id, block_id, floor_id, number, unit_type, area_sqft, maintenance_weight, ownership_status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`,
        [societyId, input.wingId || null, input.blockId || null, input.floorId || null, input.number,
         input.unitType || null, input.areaSqft ?? null, input.maintenanceWeight ?? 1, input.ownershipStatus || "vacant"]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Unit number already exists", "ALREADY_EXISTS");
      throw e;
    }
  },
  async listUnits(societyId: string, opts: { occupancyStatus?: string; blockId?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.occupancyStatus) { params.push(opts.occupancyStatus); where += ` AND occupancy_status = $${params.length}`; }
    if (opts.blockId) { params.push(opts.blockId); where += ` AND block_id = $${params.length}`; }
    params.push(Math.min(opts.limit || 200, 1000));
    const { rows } = await db.query(`SELECT * FROM units WHERE ${where} ORDER BY number ASC LIMIT $${params.length}`, params);
    return rows;
  },
  async updateUnit(
    societyId: string,
    unitId: string,
    patch: { unitType?: string; areaSqft?: number; maintenanceWeight?: number; ownershipStatus?: string; isActive?: boolean }
  ) {
    const { rows } = await db.query(
      `UPDATE units SET unit_type = COALESCE($3, unit_type), area_sqft = COALESCE($4, area_sqft),
              maintenance_weight = COALESCE($5, maintenance_weight), ownership_status = COALESCE($6, ownership_status),
              is_active = COALESCE($7, is_active), version = version + 1, updated_at = now()
        WHERE id = $1 AND society_id = $2 RETURNING *`,
      [unitId, societyId, patch.unitType ?? null, patch.areaSqft ?? null, patch.maintenanceWeight ?? null,
       patch.ownershipStatus ?? null, patch.isActive ?? null]
    );
    if (!rows[0]) throw err("Unit not found", "NOT_FOUND");
    return rows[0];
  },

  /**
   * Assign a current occupancy. Closes any existing current occupancy of the same
   * relation (e.g. previous owner) and refreshes the unit's occupancy status.
   */
  async setOccupancy(
    societyId: string,
    unitId: string,
    input: { residentId: string; relation?: "owner" | "tenant" | "co_owner" | "family"; fromDate?: string }
  ) {
    return withTx(async (client) => {
      const unit = await client.query(`SELECT * FROM units WHERE id = $1 AND society_id = $2 FOR UPDATE`, [unitId, societyId]);
      if (!unit.rows[0]) throw err("Unit not found", "NOT_FOUND");
      const relation = input.relation || "owner";

      // Close any current occupancy of the same relation.
      await client.query(
        `UPDATE unit_occupancies SET to_date = current_date
          WHERE unit_id = $1 AND relation = $2 AND to_date IS NULL`,
        [unitId, relation]
      );
      const ins = await client.query(
        `INSERT INTO unit_occupancies (society_id, unit_id, resident_id, relation, from_date)
         VALUES ($1,$2,$3,$4, COALESCE($5::date, current_date)) RETURNING *`,
        [societyId, unitId, input.residentId, relation, input.fromDate || null]
      );

      const ownership = relation === "tenant" ? "rented" : relation === "co_owner" ? "jointly_owned" : "owned";
      await client.query(
        `UPDATE units SET occupancy_status = 'occupied', ownership_status = $3, version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2`,
        [unitId, societyId, ownership]
      );
      logger.info({ societyId, unitId, relation }, "Unit occupancy set");
      return ins.rows[0];
    });
  },

  /** End the current occupancy and mark the unit vacant if no current occupant remains. */
  async vacateUnit(societyId: string, unitId: string, relation: "owner" | "tenant" | "co_owner" | "family" = "owner") {
    return withTx(async (client) => {
      const upd = await client.query(
        `UPDATE unit_occupancies SET to_date = current_date
          WHERE unit_id = $1 AND relation = $2 AND to_date IS NULL AND society_id = $3 RETURNING id`,
        [unitId, relation, societyId]
      );
      const remaining = await client.query(
        `SELECT count(*)::int n FROM unit_occupancies WHERE unit_id = $1 AND to_date IS NULL`, [unitId]
      );
      if (remaining.rows[0].n === 0) {
        await client.query(
          `UPDATE units SET occupancy_status = 'vacant', ownership_status = 'vacant', version = version + 1, updated_at = now()
            WHERE id = $1 AND society_id = $2`,
          [unitId, societyId]
        );
      }
      return { closed: upd.rows.length, vacant: remaining.rows[0].n === 0 };
    });
  },

  async unitOccupancyHistory(societyId: string, unitId: string) {
    const { rows } = await db.query(
      `SELECT * FROM unit_occupancies WHERE unit_id = $1 AND society_id = $2 ORDER BY from_date DESC`,
      [unitId, societyId]
    );
    return rows;
  },

  /** Structure summary counts for dashboards/onboarding checklist. */
  async summary(societyId: string) {
    const { rows } = await db.query(
      `SELECT
         (SELECT count(*)::int FROM wings WHERE society_id = $1) AS wings,
         (SELECT count(*)::int FROM blocks WHERE society_id = $1) AS blocks,
         (SELECT count(*)::int FROM units WHERE society_id = $1) AS units,
         (SELECT count(*)::int FROM units WHERE society_id = $1 AND occupancy_status = 'occupied') AS occupied,
         (SELECT count(*)::int FROM units WHERE society_id = $1 AND occupancy_status = 'vacant') AS vacant`,
      [societyId]
    );
    return rows[0];
  },
};
