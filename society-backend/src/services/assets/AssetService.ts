import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Assets & maintenance (Phase 5, capabilities 89–92).
 *
 * Integrity guarantees:
 *  - Asset tag unique per society.
 *  - One open/in-progress work order per schedule occurrence (partial unique index)
 *    -> generating a preventive WO twice for the same schedule fails (DUPLICATE_WO).
 *  - Completing a preventive WO advances the schedule's next_due_on by interval_days.
 *  - Breakdown WO opens downtime; completion closes it and restores the asset.
 * Tenant-scoped by society_id. Money in integer minor units.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const AssetService = {
  // ---- Registry ---------------------------------------------------------
  async createAsset(
    societyId: string,
    input: { tag: string; name: string; type?: string; categoryId?: string; location?: string; commissionedOn?: string; purchaseCostMinor?: number }
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO assets (society_id, tag, name, type, category_id, location, commissioned_on, purchase_cost_minor)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
        [societyId, input.tag, input.name, input.type || "other", input.categoryId || null,
         input.location || null, input.commissionedOn || null, input.purchaseCostMinor || 0]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Asset tag already exists", "ALREADY_EXISTS");
      throw e;
    }
  },

  /**
   * Aggregated assets dashboard for the admin overview screen.
   * All counts are computed in Postgres (no client-side totals from list
   * responses). Tenant-scoped by society_id.
   */
  async getDashboard(societyId: string) {
    const [counts, byCategory, upcoming, recent] = await Promise.all([
      db.query(
        `SELECT
           COUNT(*)::int AS total,
           COUNT(*) FILTER (WHERE status = 'operational')::int AS operational,
           COUNT(*) FILTER (WHERE status = 'down')::int AS down,
           COUNT(*) FILTER (WHERE status = 'retired')::int AS retired
         FROM assets WHERE society_id = $1`,
        [societyId]
      ),
      db.query(
        `SELECT type,
                COUNT(*)::int AS count,
                COUNT(*) FILTER (WHERE status = 'operational')::int AS operational
         FROM assets WHERE society_id = $1 GROUP BY type ORDER BY type`,
        [societyId]
      ),
      db.query(
        `SELECT s.id, s.title, s.next_due_on, a.name AS asset_name, a.type AS asset_type
         FROM maintenance_schedules s
         JOIN assets a ON a.id = s.asset_id
         WHERE s.society_id = $1 AND s.is_active = true
         ORDER BY s.next_due_on ASC LIMIT 10`,
        [societyId]
      ),
      db.query(
        `SELECT w.id, w.title, w.kind, w.status, w.updated_at, a.name AS asset_name
         FROM maintenance_work_orders w
         JOIN assets a ON a.id = w.asset_id
         WHERE w.society_id = $1
         ORDER BY w.updated_at DESC LIMIT 10`,
        [societyId]
      ),
    ]);
    const c = counts.rows[0] || { total: 0, operational: 0, down: 0, retired: 0 };
    return {
      totals: {
        total: c.total,
        operational: c.operational,
        underMaintenance: c.down,
        outOfService: c.retired,
        categories: byCategory.rows.length,
      },
      categories: byCategory.rows,
      upcomingMaintenance: upcoming.rows,
      recentActivity: recent.rows,
    };
  },

  async listAssets(societyId: string, opts: { status?: string } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    const { rows } = await db.query(`SELECT * FROM assets WHERE ${where} ORDER BY name ASC`, params);
    return rows;
  },

  async getAsset(societyId: string, assetId: string) {
    const { rows } = await db.query(`SELECT * FROM assets WHERE id = $1 AND society_id = $2`, [assetId, societyId]);
    if (!rows[0]) return null;
    const [schedules, workOrders, downtime, amc] = await Promise.all([
      db.query(`SELECT * FROM maintenance_schedules WHERE asset_id = $1 AND society_id = $2 ORDER BY next_due_on ASC`, [assetId, societyId]),
      db.query(`SELECT * FROM maintenance_work_orders WHERE asset_id = $1 AND society_id = $2 ORDER BY created_at DESC LIMIT 50`, [assetId, societyId]),
      db.query(`SELECT * FROM asset_downtime WHERE asset_id = $1 AND society_id = $2 ORDER BY started_at DESC LIMIT 50`, [assetId, societyId]),
      db.query(`SELECT * FROM amc_contracts WHERE asset_id = $1 AND society_id = $2 ORDER BY end_date DESC`, [assetId, societyId]),
    ]);
    return { asset: rows[0], schedules: schedules.rows, workOrders: workOrders.rows, downtime: downtime.rows, amc: amc.rows };
  },

  async createVendor(societyId: string, input: { name: string; contact?: string; speciality?: string }) {
    const { rows } = await db.query(
      `INSERT INTO maintenance_vendors (society_id, name, contact, speciality) VALUES ($1,$2,$3,$4) RETURNING *`,
      [societyId, input.name, input.contact || null, input.speciality || null]
    );
    return rows[0];
  },

  // ---- Preventive maintenance ------------------------------------------
  async createSchedule(
    societyId: string,
    input: { assetId: string; title: string; intervalDays: number; firstDueOn: string }
  ) {
    const owns = await db.query(`SELECT id FROM assets WHERE id = $1 AND society_id = $2`, [input.assetId, societyId]);
    if (!owns.rows[0]) throw err("Asset not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO maintenance_schedules (society_id, asset_id, title, interval_days, next_due_on)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [societyId, input.assetId, input.title, input.intervalDays, input.firstDueOn]
    );
    return rows[0];
  },

  /** Generate a preventive work order from a schedule. Duplicate-protected. */
  async generateWorkOrderFromSchedule(societyId: string, scheduleId: string, vendorId?: string, createdBy?: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM maintenance_schedules WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [scheduleId, societyId]
      );
      const sch = rows[0];
      if (!sch) throw err("Schedule not found", "NOT_FOUND");
      try {
        const ins = await client.query(
          `INSERT INTO maintenance_work_orders (society_id, asset_id, schedule_id, vendor_id, kind, title, created_by)
           VALUES ($1,$2,$3,$4,'preventive',$5,$6) RETURNING *`,
          [societyId, sch.asset_id, scheduleId, vendorId || null, sch.title, createdBy || null]
        );
        return ins.rows[0];
      } catch (e: any) {
        if (e.code === "23505") throw err("An open work order already exists for this schedule", "DUPLICATE_WO");
        throw e;
      }
    });
  },

  // ---- Work orders ------------------------------------------------------
  async createWorkOrder(
    societyId: string,
    input: { assetId: string; kind?: "preventive" | "breakdown" | "inspection"; title: string; description?: string; vendorId?: string },
    createdBy?: string
  ) {
    return withTx(async (client) => {
      const asset = await client.query(`SELECT * FROM assets WHERE id = $1 AND society_id = $2 FOR UPDATE`, [input.assetId, societyId]);
      if (!asset.rows[0]) throw err("Asset not found", "NOT_FOUND");
      const ins = await client.query(
        `INSERT INTO maintenance_work_orders (society_id, asset_id, vendor_id, kind, title, description, created_by)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
        [societyId, input.assetId, input.vendorId || null, input.kind || "breakdown", input.title, input.description || null, createdBy || null]
      );
      // A breakdown marks the asset down and opens a downtime record.
      if ((input.kind || "breakdown") === "breakdown") {
        await client.query(`UPDATE assets SET status = 'down', updated_at = now() WHERE id = $1`, [input.assetId]);
        await client.query(
          `INSERT INTO asset_downtime (society_id, asset_id, work_order_id, reason) VALUES ($1,$2,$3,$4)`,
          [societyId, input.assetId, ins.rows[0].id, input.title]
        );
      }
      return ins.rows[0];
    });
  },

  async startWorkOrder(societyId: string, workOrderId: string) {
    return this.transitionWO(societyId, workOrderId, ["open"], "in_progress");
  },

  /**
   * Complete a work order: closes downtime, restores the asset, advances the
   * linked schedule, and records cost + completion proof.
   */
  async completeWorkOrder(societyId: string, workOrderId: string, input: { costMinor?: number; proofUrl?: string } = {}) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM maintenance_work_orders WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [workOrderId, societyId]
      );
      const wo = rows[0];
      if (!wo) throw err("Work order not found", "NOT_FOUND");
      if (wo.status === "completed" || wo.status === "cancelled") {
        throw err(`Work order already ${wo.status}`, "INVALID_STATE");
      }

      const upd = await client.query(
        `UPDATE maintenance_work_orders
            SET status = 'completed', completed_at = now(), cost_minor = $3,
                completion_proof_url = $4, version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [workOrderId, societyId, input.costMinor || 0, input.proofUrl || null]
      );

      // Close any open downtime for this WO and restore the asset.
      const dt = await client.query(
        `UPDATE asset_downtime
            SET ended_at = now(), minutes = GREATEST(0, EXTRACT(EPOCH FROM (now() - started_at)) / 60)::int
          WHERE work_order_id = $1 AND ended_at IS NULL RETURNING id`,
        [workOrderId]
      );
      if (dt.rows.length > 0) {
        await client.query(`UPDATE assets SET status = 'operational', updated_at = now() WHERE id = $1`, [wo.asset_id]);
      }

      // Advance the preventive schedule. Date math is done in SQL with an interval
      // so it is timezone-safe (pg returns DATE columns as local-midnight Dates).
      if (wo.schedule_id) {
        await client.query(
          `UPDATE maintenance_schedules
              SET next_due_on = next_due_on + (interval_days || ' days')::interval
            WHERE id = $1`,
          [wo.schedule_id]
        );
      }
      logger.info({ societyId, workOrderId }, "Work order completed");
      return upd.rows[0];
    });
  },

  async transitionWO(societyId: string, workOrderId: string, fromAllowed: string[], to: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM maintenance_work_orders WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [workOrderId, societyId]
      );
      const wo = rows[0];
      if (!wo) throw err("Work order not found", "NOT_FOUND");
      if (!fromAllowed.includes(wo.status)) throw err(`Cannot move work order from ${wo.status} to ${to}`, "INVALID_STATE");
      const upd = await client.query(
        `UPDATE maintenance_work_orders SET status = $3, version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [workOrderId, societyId, to]
      );
      return upd.rows[0];
    });
  },

  // ---- AMC --------------------------------------------------------------
  async createAmc(
    societyId: string,
    input: { assetId?: string; vendorId?: string; contractNo?: string; startDate: string; endDate: string; valueMinor?: number }
  ) {
    const { rows } = await db.query(
      `INSERT INTO amc_contracts (society_id, asset_id, vendor_id, contract_no, start_date, end_date, value_minor)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [societyId, input.assetId || null, input.vendorId || null, input.contractNo || null,
       input.startDate, input.endDate, input.valueMinor || 0]
    );
    return rows[0];
  },

  /** Sweep expired AMC contracts; returns count (cron). */
  async expireAmc(societyId: string) {
    const { rows } = await db.query(
      `UPDATE amc_contracts SET status = 'expired'
        WHERE society_id = $1 AND status = 'active' AND end_date < current_date RETURNING id`,
      [societyId]
    );
    return rows.length;
  },

  /** AMC contracts expiring within `days` — for reminder workers. */
  async amcExpiringSoon(societyId: string, days = 30) {
    const { rows } = await db.query(
      `SELECT * FROM amc_contracts
        WHERE society_id = $1 AND status = 'active'
          AND end_date BETWEEN current_date AND current_date + ($2 || ' days')::interval
        ORDER BY end_date ASC`,
      [societyId, days]
    );
    return rows;
  },

  // ---- Spare parts ------------------------------------------------------
  async upsertSparePart(societyId: string, input: { name: string; quantity: number; unitCostMinor?: number }) {
    const { rows } = await db.query(
      `INSERT INTO spare_parts (society_id, name, quantity, unit_cost_minor)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (society_id, name) DO UPDATE SET quantity = EXCLUDED.quantity, unit_cost_minor = EXCLUDED.unit_cost_minor
       RETURNING *`,
      [societyId, input.name, input.quantity, input.unitCostMinor || 0]
    );
    return rows[0];
  },
};
