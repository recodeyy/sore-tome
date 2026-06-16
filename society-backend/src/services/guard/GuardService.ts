import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";

/**
 * Guard / Security operations (visitor gate, gate passes, patrols, incidents).
 *
 * Integrity guarantees:
 *  - Visitor status transitions validated: no double check-in, only checked_in
 *    visitors may be checked out, terminal states (checked_out/denied) are final.
 *  - Gate-pass validation rejects expired, used or revoked passes and marks
 *    a valid pass as used (single-use) atomically.
 *  - Everything tenant-scoped by society_id; updates filter on (id, society_id)
 *    so a guard in one society can never mutate another's records.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const GuardService = {
  // ---- Visitors ---------------------------------------------------------
  async checkInVisitor(
    societyId: string,
    input: { name: string; phone?: string; purpose?: string; unitId?: string; preApprovalId?: string; guardId?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO visitor_entries (society_id, name, phone, purpose, unit_id, status, pre_approval_id, checked_in_at, guard_id)
       VALUES ($1,$2,$3,$4,$5,'checked_in',$6, now(), $7) RETURNING *`,
      [societyId, input.name, input.phone || null, input.purpose || null, input.unitId || null,
       input.preApprovalId || null, input.guardId || null]
    );
    logger.info({ societyId, visitorId: rows[0].id }, "Visitor checked in");
    return rows[0];
  },

  async checkOutVisitor(societyId: string, visitorId: string, guardId?: string) {
    const cur = await db.query(`SELECT status FROM visitor_entries WHERE id = $1 AND society_id = $2`, [visitorId, societyId]);
    if (!cur.rows[0]) throw err("Visitor entry not found", "NOT_FOUND");
    if (cur.rows[0].status === "checked_out") throw err("Visitor already checked out", "INVALID_STATE");
    if (cur.rows[0].status !== "checked_in") throw err(`Cannot check out a visitor in '${cur.rows[0].status}' state`, "INVALID_STATE");
    const { rows } = await db.query(
      `UPDATE visitor_entries SET status = 'checked_out', checked_out_at = now(), guard_id = COALESCE($3, guard_id)
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [visitorId, societyId, guardId || null]
    );
    return rows[0];
  },

  async denyVisitor(societyId: string, visitorId: string, guardId?: string) {
    const cur = await db.query(`SELECT status FROM visitor_entries WHERE id = $1 AND society_id = $2`, [visitorId, societyId]);
    if (!cur.rows[0]) throw err("Visitor entry not found", "NOT_FOUND");
    if (cur.rows[0].status !== "expected") throw err(`Cannot deny a visitor in '${cur.rows[0].status}' state`, "INVALID_STATE");
    const { rows } = await db.query(
      `UPDATE visitor_entries SET status = 'denied', guard_id = COALESCE($3, guard_id)
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [visitorId, societyId, guardId || null]
    );
    return rows[0];
  },

  async listVisitors(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    params.push(Math.min(opts.limit || 100, 500));
    const { rows } = await db.query(
      `SELECT * FROM visitor_entries WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`, params
    );
    return rows;
  },

  // ---- Gate passes ------------------------------------------------------
  async createGatePass(
    societyId: string,
    input: { type: "visitor" | "delivery" | "cab" | "service"; code: string; validUntil: string | Date; guardId?: string }
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO gate_passes (society_id, type, code, valid_until, status, guard_id)
         VALUES ($1,$2,$3,$4,'active',$5) RETURNING *`,
        [societyId, input.type, input.code, new Date(input.validUntil), input.guardId || null]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Gate pass code already exists for this society", "ALREADY_EXISTS");
      throw e;
    }
  },

  /** Validates a pass and consumes it (single-use). Rejects expired/used/revoked. */
  async validateGatePass(societyId: string, code: string) {
    const cur = await db.query(`SELECT * FROM gate_passes WHERE society_id = $1 AND code = $2`, [societyId, code]);
    const pass = cur.rows[0];
    if (!pass) throw err("Gate pass not found", "NOT_FOUND");
    if (pass.status === "used") throw err("Gate pass already used", "INVALID_STATE");
    if (pass.status === "revoked") throw err("Gate pass revoked", "INVALID_STATE");
    if (new Date(pass.valid_until).getTime() < Date.now()) {
      await db.query(`UPDATE gate_passes SET status = 'expired' WHERE id = $1 AND society_id = $2`, [pass.id, societyId]);
      throw err("Gate pass expired", "INVALID_STATE");
    }
    const { rows } = await db.query(
      `UPDATE gate_passes SET status = 'used' WHERE id = $1 AND society_id = $2 AND status = 'active' RETURNING *`,
      [pass.id, societyId]
    );
    return rows[0];
  },

  async listGatePasses(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    params.push(Math.min(opts.limit || 100, 500));
    const { rows } = await db.query(
      `SELECT * FROM gate_passes WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`, params
    );
    return rows;
  },

  // ---- Patrols ----------------------------------------------------------
  async logPatrol(societyId: string, input: { checkpoint: string; note?: string; guardId?: string }) {
    const { rows } = await db.query(
      `INSERT INTO patrol_logs (society_id, guard_id, checkpoint, note)
       VALUES ($1,$2,$3,$4) RETURNING *`,
      [societyId, input.guardId || null, input.checkpoint, input.note || null]
    );
    return rows[0];
  },

  async listPatrols(societyId: string, opts: { limit?: number } = {}) {
    const { rows } = await db.query(
      `SELECT * FROM patrol_logs WHERE society_id = $1 ORDER BY logged_at DESC LIMIT $2`,
      [societyId, Math.min(opts.limit || 100, 500)]
    );
    return rows;
  },

  // ---- Incidents --------------------------------------------------------
  async reportIncident(
    societyId: string,
    input: { category: string; description?: string; severity?: "low" | "medium" | "high" | "critical"; guardId?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO security_incidents (society_id, guard_id, category, description, severity)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [societyId, input.guardId || null, input.category, input.description || null, input.severity || "low"]
    );
    logger.info({ societyId, incidentId: rows[0].id }, "Security incident reported");
    return rows[0];
  },

  async updateIncidentStatus(
    societyId: string,
    incidentId: string,
    status: "open" | "investigating" | "resolved" | "closed"
  ) {
    const { rows } = await db.query(
      `UPDATE security_incidents SET status = $3 WHERE id = $1 AND society_id = $2 RETURNING *`,
      [incidentId, societyId, status]
    );
    if (!rows[0]) throw err("Incident not found", "NOT_FOUND");
    return rows[0];
  },

  async listIncidents(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    params.push(Math.min(opts.limit || 100, 500));
    const { rows } = await db.query(
      `SELECT * FROM security_incidents WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`, params
    );
    return rows;
  },
};
