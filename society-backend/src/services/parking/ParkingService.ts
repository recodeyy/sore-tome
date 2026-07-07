import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { Recipients } from "../notifications/Recipients";

/**
 * Parking (Phase 5, capabilities 86–88).
 *
 * Integrity guarantees:
 *  - At most ONE active allocation per slot (partial unique index). Concurrent
 *    allocations to the same slot: exactly one wins (23505 -> SLOT_TAKEN).
 *  - A vehicle plate is unique within a society.
 *  - Allocation flips slot.status to 'allocated'; release frees it and can promote
 *    the oldest waiting request.
 *  - Visitor passes expire by valid_until (sweep marks them expired).
 * Tenant-scoped by society_id. Money in integer minor units.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const ParkingService = {
  // ---- Slots & vehicles -------------------------------------------------
  async createSlot(
    societyId: string,
    input: { code: string; type?: string; location?: string; isEv?: boolean; isAccessible?: boolean; isReserved?: boolean }
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO parking_slots (society_id, code, type, location, is_ev, is_accessible, is_reserved)
         VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
        [societyId, input.code, input.type || "car", input.location || null,
         input.isEv || false, input.isAccessible || false, input.isReserved || false]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Slot code already exists", "ALREADY_EXISTS");
      throw e;
    }
  },

  async listSlots(societyId: string, opts: { status?: string } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    const { rows } = await db.query(`SELECT * FROM parking_slots WHERE ${where} ORDER BY code ASC`, params);
    return rows;
  },

  /**
   * Resident-facing: the active parking allocations that belong to [userId] —
   * either allocated directly to them (`allocated_to`) or to any unit they
   * occupy (via `members` / `unit_occupancies`, mirroring Recipients.unitResidentUserIds).
   * Joins the slot so the client can show code/type/location, and the vehicle
   * plate when one is attached. This is the read side of the cross-role flow:
   * admin allocates (POST /allocations) → resident sees it here.
   */
  async listForResident(societyId: string, userId: string) {
    const { rows } = await db.query(
      `SELECT a.id, a.slot_id, a.unit_id, a.allocated_to, a.status, a.allocated_at,
              s.code AS slot_code, s.type AS slot_type, s.location AS slot_location,
              v.plate AS vehicle_plate, v.type AS vehicle_type, v.make_model
         FROM parking_allocations a
         JOIN parking_slots s ON s.id = a.slot_id
         LEFT JOIN vehicles v ON v.id = a.vehicle_id
        WHERE a.society_id = $1 AND a.status = 'active'
          AND (
            a.allocated_to = $2
            OR a.unit_id::text IN (
              SELECT unit_id::text FROM members
                WHERE society_id = $1 AND user_id = $2 AND unit_id IS NOT NULL
              UNION
              SELECT unit_id::text FROM unit_occupancies
                WHERE society_id = $1 AND resident_id = $2 AND to_date IS NULL AND unit_id IS NOT NULL
            )
          )
        ORDER BY a.allocated_at DESC`,
      [societyId, userId]
    );
    return rows;
  },

  /**
   * Admin/committee-facing: all allocations for the society (MR-004 — the
   * Flutter admin app GETs /parking/allocations). Joined to slot + vehicle so
   * the client can render code/location/plate without extra round-trips.
   */
  async listAllocations(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `a.society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND a.status = $${params.length}`; }
    params.push(Math.min(opts.limit || 200, 500));
    const { rows } = await db.query(
      `SELECT a.id, a.slot_id, a.vehicle_id, a.unit_id, a.allocated_to, a.allocated_by,
              a.status, a.allocated_at, a.released_at,
              s.code AS slot_code, s.type AS slot_type, s.location AS slot_location,
              v.plate AS vehicle_plate, v.type AS vehicle_type, v.make_model,
              u.number AS unit_number
         FROM parking_allocations a
         JOIN parking_slots s ON s.id = a.slot_id
         LEFT JOIN vehicles v ON v.id = a.vehicle_id
         LEFT JOIN units u ON u.id::text = a.unit_id::text
        WHERE ${where}
        ORDER BY a.allocated_at DESC
        LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  async registerVehicle(
    societyId: string,
    input: { plate: string; type?: string; unitId?: string; ownerId?: string; makeModel?: string }
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO vehicles (society_id, plate, type, unit_id, owner_id, make_model)
         VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
        [societyId, input.plate.toUpperCase().replace(/\s+/g, ""), input.type || "car",
         input.unitId || null, input.ownerId || null, input.makeModel || null]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Vehicle already registered in this society", "ALREADY_EXISTS");
      throw e;
    }
  },

  // ---- Allocation -------------------------------------------------------
  /** Allocate a slot. The partial unique index guarantees one active allocation. */
  async allocate(
    societyId: string,
    input: { slotId: string; vehicleId?: string; unitId?: string; allocatedTo?: string; allocatedBy?: string }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM parking_slots WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [input.slotId, societyId]
      );
      const slot = rows[0];
      if (!slot) throw err("Slot not found", "NOT_FOUND");
      if (slot.status === "maintenance") throw err("Slot is under maintenance", "INVALID_STATE");

      try {
        const ins = await client.query(
          `INSERT INTO parking_allocations (society_id, slot_id, vehicle_id, unit_id, allocated_to, allocated_by)
           VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
          [societyId, input.slotId, input.vehicleId || null, input.unitId || null, input.allocatedTo || null, input.allocatedBy || null]
        );
        await client.query(`UPDATE parking_slots SET status = 'allocated' WHERE id = $1`, [input.slotId]);

        // Cross-role: notify the allocated unit's resident(s) only (tenant isolation).
        const residents = await Recipients.unitResidentUserIds(client, societyId, ins.rows[0].unit_id);
        const notified = await Recipients.fanOut(client, {
          societyId,
          eventType: "parking.allocated",
          payload: { id: ins.rows[0].id, slotId: input.slotId, unitId: ins.rows[0].unit_id },
          recipients: residents,
          notification: {
            title: "Parking slot allocated",
            body: `Parking slot ${slot.code} has been allocated to your unit.`,
            type: "parking",
            data: { allocationId: ins.rows[0].id, slotId: input.slotId, slotCode: slot.code, deepLink: `sero://parking/${ins.rows[0].id}` },
          },
        });
        logger.info({ societyId, slotId: input.slotId, notified }, "Parking slot allocated + residents notified");
        return ins.rows[0];
      } catch (e: any) {
        if (e.code === "23505") throw err("Slot already has an active allocation", "SLOT_TAKEN");
        throw e;
      }
    });
  },

  /** Release an active allocation; frees the slot and promotes the oldest waiting request. */
  async release(societyId: string, allocationId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM parking_allocations WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [allocationId, societyId]
      );
      const alloc = rows[0];
      if (!alloc) throw err("Allocation not found", "NOT_FOUND");
      if (alloc.status !== "active") throw err("Allocation already released", "INVALID_STATE");

      await client.query(
        `UPDATE parking_allocations SET status = 'released', released_at = now() WHERE id = $1`,
        [allocationId]
      );
      await client.query(`UPDATE parking_slots SET status = 'available' WHERE id = $1 AND society_id = $2`, [alloc.slot_id, societyId]);

      // Promote oldest waiting request to this freed slot, if any.
      const wait = await client.query(
        `SELECT * FROM parking_requests WHERE society_id = $1 AND status = 'waiting' ORDER BY created_at ASC LIMIT 1`,
        [societyId]
      );
      let promoted = null;
      if (wait.rows[0]) {
        const reqRow = wait.rows[0];
        const newAlloc = await client.query(
          `INSERT INTO parking_allocations (society_id, slot_id, unit_id, allocated_to, allocated_by)
           VALUES ($1,$2,$3,$4,'system:waitlist') RETURNING *`,
          [societyId, alloc.slot_id, reqRow.unit_id, reqRow.requested_by]
        );
        await client.query(`UPDATE parking_slots SET status = 'allocated' WHERE id = $1`, [alloc.slot_id]);
        await client.query(
          `UPDATE parking_requests SET status = 'allocated', allocation_id = $2, updated_at = now() WHERE id = $1`,
          [reqRow.id, newAlloc.rows[0].id]
        );
        promoted = { requestId: reqRow.id, allocation: newAlloc.rows[0] };
      }
      logger.info({ societyId, allocationId, promoted: !!promoted }, "Parking slot released");
      return { released: alloc.id, promoted };
    });
  },

  /** Transfer an active allocation to a different slot atomically. */
  async transfer(societyId: string, allocationId: string, toSlotId: string, by?: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM parking_allocations WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [allocationId, societyId]
      );
      const alloc = rows[0];
      if (!alloc) throw err("Allocation not found", "NOT_FOUND");
      if (alloc.status !== "active") throw err("Allocation not active", "INVALID_STATE");

      const slot = await client.query(`SELECT * FROM parking_slots WHERE id = $1 AND society_id = $2 FOR UPDATE`, [toSlotId, societyId]);
      if (!slot.rows[0]) throw err("Target slot not found", "NOT_FOUND");

      await client.query(`UPDATE parking_allocations SET status = 'released', released_at = now() WHERE id = $1`, [allocationId]);
      await client.query(`UPDATE parking_slots SET status = 'available' WHERE id = $1`, [alloc.slot_id]);
      try {
        const ins = await client.query(
          `INSERT INTO parking_allocations (society_id, slot_id, vehicle_id, unit_id, allocated_to, allocated_by)
           VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
          [societyId, toSlotId, alloc.vehicle_id, alloc.unit_id, alloc.allocated_to, by || alloc.allocated_by]
        );
        await client.query(`UPDATE parking_slots SET status = 'allocated' WHERE id = $1`, [toSlotId]);

        // Cross-role: notify the unit's resident(s) the slot was updated/moved.
        const residents = await Recipients.unitResidentUserIds(client, societyId, ins.rows[0].unit_id);
        await Recipients.fanOut(client, {
          societyId,
          eventType: "parking.updated",
          payload: { id: ins.rows[0].id, slotId: toSlotId, unitId: ins.rows[0].unit_id },
          recipients: residents,
          notification: {
            title: "Parking slot updated",
            body: `Your parking allocation has been moved to a new slot.`,
            type: "parking",
            data: { allocationId: ins.rows[0].id, slotId: toSlotId, deepLink: `sero://parking/${ins.rows[0].id}` },
          },
        });
        return ins.rows[0];
      } catch (e: any) {
        if (e.code === "23505") throw err("Target slot already allocated", "SLOT_TAKEN");
        throw e;
      }
    });
  },

  // ---- Requests / waitlist ---------------------------------------------
  async requestSlot(societyId: string, input: { requestedBy: string; unitId?: string; vehicleType?: "car" | "bike" | "ev" }) {
    const { rows } = await db.query(
      `INSERT INTO parking_requests (society_id, requested_by, unit_id, vehicle_type)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [societyId, input.requestedBy, input.unitId || null, input.vehicleType || "car"]
    );
    return rows[0];
  },

  async listRequests(societyId: string, opts: { status?: string } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    const { rows } = await db.query(`SELECT * FROM parking_requests WHERE ${where} ORDER BY created_at ASC`, params);
    return rows;
  },

  // ---- Visitor parking --------------------------------------------------
  async createVisitorPass(
    societyId: string,
    input: { plate: string; visitingUnitId?: string; slotId?: string; validUntil: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO visitor_parking (society_id, slot_id, plate, visiting_unit_id, valid_until)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [societyId, input.slotId || null, input.plate.toUpperCase(), input.visitingUnitId || null, input.validUntil]
    );
    return rows[0];
  },

  /** Sweep: mark expired visitor passes (run by a cron worker). */
  async expireVisitorPasses(societyId: string) {
    const { rows } = await db.query(
      `UPDATE visitor_parking SET status = 'expired'
        WHERE society_id = $1 AND status = 'active' AND valid_until < now() RETURNING id`,
      [societyId]
    );
    return rows.length;
  },

  // ---- Violations -------------------------------------------------------
  async recordViolation(
    societyId: string,
    input: { slotId?: string; plate?: string; description: string; evidenceUrl?: string; fineMinor?: number },
    reportedBy?: string
  ) {
    const { rows } = await db.query(
      `INSERT INTO parking_violations (society_id, slot_id, plate, description, evidence_url, fine_minor, reported_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [societyId, input.slotId || null, input.plate || null, input.description, input.evidenceUrl || null, input.fineMinor || 0, reportedBy || null]
    );
    return rows[0];
  },

  async resolveViolation(societyId: string, violationId: string, status: "waived" | "paid" | "disputed") {
    const { rows } = await db.query(
      `UPDATE parking_violations SET status = $3, updated_at = now() WHERE id = $1 AND society_id = $2 RETURNING *`,
      [violationId, societyId, status]
    );
    if (!rows[0]) throw err("Violation not found", "NOT_FOUND");
    return rows[0];
  },

  async listViolations(societyId: string, opts: { status?: string } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    const { rows } = await db.query(`SELECT * FROM parking_violations WHERE ${where} ORDER BY created_at DESC LIMIT 200`, params);
    return rows;
  },
};
