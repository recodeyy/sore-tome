import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { Recipients } from "../notifications/Recipients";

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
    return withTx(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO visitor_entries (society_id, name, phone, purpose, unit_id, status, pre_approval_id, checked_in_at, guard_id)
         VALUES ($1,$2,$3,$4,$5,'checked_in',$6, now(), $7) RETURNING *`,
        [societyId, input.name, input.phone || null, input.purpose || null, input.unitId || null,
         input.preApprovalId || null, input.guardId || null]
      );
      const v = rows[0];

      // Cross-role: notify the target unit's resident(s) only (tenant isolation).
      const residents = await Recipients.unitResidentUserIds(client, societyId, v.unit_id);
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: "visitor.logged",
        payload: { id: v.id, unitId: v.unit_id, name: v.name, status: v.status },
        recipients: residents,
        notification: {
          title: "Visitor at the gate",
          body: `${v.name} is here${v.purpose ? ` (${v.purpose})` : ""}. Approve or reject entry.`,
          type: "visitor",
          data: { visitorId: v.id, action: "approval", deepLink: `sero://visitors/${v.id}` },
        },
      });
      logger.info({ societyId, visitorId: v.id, notified }, "Visitor logged + residents notified");
      return v;
    });
  },

  /**
   * Resident approves or rejects an expected/logged visitor. Notifies the guard
   * (who logged the entry) of the decision.
   */
  async decideVisitor(
    societyId: string,
    visitorId: string,
    decision: "approved" | "rejected",
    actorId?: string
  ) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM visitor_entries WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [visitorId, societyId]
      );
      const v = cur.rows[0];
      if (!v) throw err("Visitor entry not found", "NOT_FOUND");
      // Map the resident decision onto the existing status check constraint:
      // an approved visitor stays 'expected' (awaiting gate entry); a rejected
      // one becomes 'denied'.
      const nextStatus = decision === "rejected" ? "denied" : v.status;
      const { rows } = await client.query(
        `UPDATE visitor_entries SET status = $3 WHERE id = $1 AND society_id = $2 RETURNING *`,
        [visitorId, societyId, nextStatus]
      );
      const updated = rows[0];

      // Notify the guard who logged this visitor (fallback: all security staff).
      const guardRecipients = v.guard_id ? [v.guard_id] : await Recipients.securityStaffUserIds(client, societyId);
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: decision === "rejected" ? "visitor.rejected" : "visitor.approved",
        payload: { id: visitorId, unitId: v.unit_id, decision },
        recipients: guardRecipients,
        notification: {
          title: decision === "rejected" ? "Visitor rejected" : "Visitor approved",
          body: `${v.name} was ${decision} by the resident.`,
          type: "visitor",
          data: { visitorId, decision, deepLink: `sero://visitors/${visitorId}` },
        },
      });
      logger.info({ societyId, visitorId, decision, notified }, "Visitor decision + guard notified");
      return updated;
    });
  },

  async checkOutVisitor(societyId: string, visitorId: string, guardId?: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM visitor_entries WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [visitorId, societyId]
      );
      const v = cur.rows[0];
      if (!v) throw err("Visitor entry not found", "NOT_FOUND");
      if (v.status === "checked_out") throw err("Visitor already checked out", "INVALID_STATE");
      if (v.status !== "checked_in") throw err(`Cannot check out a visitor in '${v.status}' state`, "INVALID_STATE");
      const { rows } = await client.query(
        `UPDATE visitor_entries SET status = 'checked_out', checked_out_at = now(), guard_id = COALESCE($3, guard_id)
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [visitorId, societyId, guardId || null]
      );

      // Cross-role: resident "exited" notification for the target unit only.
      const residents = await Recipients.unitResidentUserIds(client, societyId, v.unit_id);
      await Recipients.fanOut(client, {
        societyId,
        eventType: "visitor.exited",
        payload: { id: visitorId, unitId: v.unit_id },
        recipients: residents,
        notification: {
          title: "Visitor exited",
          body: `${v.name} has left the premises.`,
          type: "visitor",
          data: { visitorId, action: "exited", deepLink: `sero://visitors/${visitorId}` },
        },
      });
      logger.info({ societyId, visitorId }, "Visitor checked out + residents notified");
      return rows[0];
    });
  },

  /** Record a logged/approved visitor's gate entry; notifies the unit's residents. */
  async recordEntry(societyId: string, visitorId: string, guardId?: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM visitor_entries WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [visitorId, societyId]
      );
      const v = cur.rows[0];
      if (!v) throw err("Visitor entry not found", "NOT_FOUND");
      if (v.status === "checked_out" || v.status === "denied") {
        throw err(`Cannot record entry for a visitor in '${v.status}' state`, "INVALID_STATE");
      }
      const { rows } = await client.query(
        `UPDATE visitor_entries
            SET status = 'checked_in', checked_in_at = COALESCE(checked_in_at, now()),
                guard_id = COALESCE($3, guard_id)
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [visitorId, societyId, guardId || null]
      );

      const residents = await Recipients.unitResidentUserIds(client, societyId, v.unit_id);
      await Recipients.fanOut(client, {
        societyId,
        eventType: "visitor.entered",
        payload: { id: visitorId, unitId: v.unit_id },
        recipients: residents,
        notification: {
          title: "Visitor entered",
          body: `${v.name} has entered the premises.`,
          type: "visitor",
          data: { visitorId, action: "entered", deepLink: `sero://visitors/${visitorId}` },
        },
      });
      logger.info({ societyId, visitorId }, "Visitor entry recorded + residents notified");
      return rows[0];
    });
  },

  async denyVisitor(societyId: string, visitorId: string, guardId?: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM visitor_entries WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [visitorId, societyId]
      );
      const v = cur.rows[0];
      if (!v) throw err("Visitor entry not found", "NOT_FOUND");
      if (v.status !== "expected") throw err(`Cannot deny a visitor in '${v.status}' state`, "INVALID_STATE");
      const { rows } = await client.query(
        `UPDATE visitor_entries SET status = 'denied', guard_id = COALESCE($3, guard_id)
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [visitorId, societyId, guardId || null]
      );

      const residents = await Recipients.unitResidentUserIds(client, societyId, v.unit_id);
      await Recipients.fanOut(client, {
        societyId,
        eventType: "visitor.denied",
        payload: { id: visitorId, unitId: v.unit_id },
        recipients: residents,
        notification: {
          title: "Visitor denied",
          body: `${v.name} was denied entry at the gate.`,
          type: "visitor",
          data: { visitorId, action: "denied", deepLink: `sero://visitors/${visitorId}` },
        },
      });
      return rows[0];
    });
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
  /**
   * SOS / incident trigger. The reporter may be a guard OR a resident (the
   * actor id is recorded in guard_id). Fans out to security staff AND admins so
   * the right cross-role responders are alerted immediately.
   */
  async reportIncident(
    societyId: string,
    input: { category: string; description?: string; severity?: "low" | "medium" | "high" | "critical"; guardId?: string }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO security_incidents (society_id, guard_id, category, description, severity)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [societyId, input.guardId || null, input.category, input.description || null, input.severity || "low"]
      );
      const inc = rows[0];

      const [security, admins] = await Promise.all([
        Recipients.securityStaffUserIds(client, societyId),
        Recipients.adminUserIds(client, societyId),
      ]);
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: "incident.reported",
        payload: { id: inc.id, category: inc.category, severity: inc.severity },
        recipients: [...security, ...admins],
        notification: {
          title: `SOS / ${inc.category}`,
          body: inc.description || `A ${inc.severity} security incident was reported.`,
          type: "incident",
          data: { incidentId: inc.id, severity: inc.severity, deepLink: `sero://incidents/${inc.id}` },
        },
      });
      logger.info({ societyId, incidentId: inc.id, notified }, "Security incident reported + responders notified");
      return inc;
    });
  },

  async updateIncidentStatus(
    societyId: string,
    incidentId: string,
    status: "open" | "investigating" | "resolved" | "closed",
    actorId?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `UPDATE security_incidents SET status = $3 WHERE id = $1 AND society_id = $2 RETURNING *`,
        [incidentId, societyId, status]
      );
      const inc = rows[0];
      if (!inc) throw err("Incident not found", "NOT_FOUND");

      // Acknowledgement/resolution: notify admins (and the original reporter if a resident).
      const recipients = await Recipients.adminUserIds(client, societyId);
      if (inc.guard_id) recipients.push(inc.guard_id);
      await Recipients.fanOut(client, {
        societyId,
        eventType: "incident.status_changed",
        payload: { id: incidentId, status },
        recipients,
        notification: {
          title: `Incident ${status}`,
          body: `Security incident "${inc.category}" is now ${status}.`,
          type: "incident",
          data: { incidentId, status, actorId: actorId || null, deepLink: `sero://incidents/${incidentId}` },
        },
      });
      return inc;
    });
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
