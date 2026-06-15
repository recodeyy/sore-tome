import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { assertTransition, isReopen, type ComplaintStatus } from "./ComplaintStateMachine";
import { computeDueAtWithPauses, type SlaConfig } from "../sla/SlaCalculator";
import { OutboxService } from "../outbox/OutboxService";

/**
 * Phase 4 complaints workflow (capabilities 59–69).
 *
 * Design rules enforced here:
 *  - SLA policy is SNAPSHOTTED on the complaint at creation (sla_config + sla_minutes)
 *    so later policy edits never move an open complaint's due time.
 *  - Status changes go through the pure state machine; every change is recorded in
 *    complaint_status_history inside the same transaction.
 *  - Pauses stop the SLA clock; due_at is recomputed from pause events.
 *  - Internal vs resident-visible comments are separated by `visibility`.
 *  - All reads/writes are tenant-scoped by society_id.
 */

const DEFAULT_SLA: SlaConfig = {
  tzOffsetMinutes: 330,
  workdays: [1, 2, 3, 4, 5, 6],
  dayStartMinutes: 540,
  dayEndMinutes: 1080,
  holidays: [],
};

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

/** Load active SLA policy for a society, falling back to sane defaults. */
async function loadSlaConfig(societyId: string): Promise<{ cfg: SlaConfig; slaMinutes: number }> {
  const { rows } = await db.query(
    `SELECT tz_offset_minutes, workdays, day_start_minutes, day_end_minutes, holidays
       FROM sla_policies WHERE society_id = $1 AND is_active = true
       ORDER BY created_at DESC LIMIT 1`,
    [societyId]
  );
  if (!rows[0]) return { cfg: DEFAULT_SLA, slaMinutes: 1440 };
  const p = rows[0];
  return {
    cfg: {
      tzOffsetMinutes: p.tz_offset_minutes,
      workdays: p.workdays,
      dayStartMinutes: p.day_start_minutes,
      dayEndMinutes: p.day_end_minutes,
      holidays: p.holidays || [],
    },
    slaMinutes: 1440,
  };
}

/** Recompute due_at for a complaint from its snapshot config + recorded pauses. */
async function recomputeDueAt(client: any, societyId: string, complaintId: string): Promise<Date> {
  const { rows } = await client.query(
    `SELECT created_at, sla_minutes, sla_config FROM complaints WHERE id = $1 AND society_id = $2`,
    [complaintId, societyId]
  );
  const c = rows[0];
  const cfg: SlaConfig = c.sla_config;
  const ev = await client.query(
    `SELECT event, occurred_at FROM complaint_sla_events
       WHERE complaint_id = $1 AND event IN ('pause','resume') ORDER BY occurred_at ASC`,
    [complaintId]
  );
  // Pair pause→resume into intervals; an unclosed pause runs to "now".
  const pauses: { from: Date; to: Date }[] = [];
  let openFrom: Date | null = null;
  for (const e of ev.rows) {
    if (e.event === "pause" && !openFrom) openFrom = new Date(e.occurred_at);
    else if (e.event === "resume" && openFrom) {
      pauses.push({ from: openFrom, to: new Date(e.occurred_at) });
      openFrom = null;
    }
  }
  if (openFrom) pauses.push({ from: openFrom, to: new Date() });

  const due = computeDueAtWithPauses(new Date(c.created_at), c.sla_minutes, pauses, cfg);
  await client.query(
    `UPDATE complaints SET due_at = $3, updated_at = now() WHERE id = $1 AND society_id = $2`,
    [complaintId, societyId, due]
  );
  return due;
}

export const ComplaintService = {
  async createComplaint(
    societyId: string,
    input: {
      title: string;
      description: string;
      categoryId?: string;
      unitId?: string;
      location?: string;
      priority?: "low" | "medium" | "high" | "critical";
      isPrivate?: boolean;
    },
    createdBy?: string
  ) {
    return withTx(async (client) => {
      const { cfg } = await loadSlaConfig(societyId);

      // Category drives default priority + SLA minutes when provided.
      let priority = input.priority || "medium";
      let slaMinutes = 1440;
      if (input.categoryId) {
        const cat = await client.query(
          `SELECT default_priority, sla_minutes FROM complaint_categories WHERE id = $1 AND society_id = $2`,
          [input.categoryId, societyId]
        );
        if (cat.rows[0]) {
          if (!input.priority) priority = cat.rows[0].default_priority;
          slaMinutes = cat.rows[0].sla_minutes;
        }
      }

      // Per-society monotonic reference: CMP-0001, CMP-0002, ...
      const cnt = await client.query(
        `SELECT count(*)::int n FROM complaints WHERE society_id = $1`,
        [societyId]
      );
      const ref = `CMP-${String(cnt.rows[0].n + 1).padStart(4, "0")}`;

      const due = computeDueAtWithPauses(new Date(), slaMinutes, [], cfg);

      const { rows } = await client.query(
        `INSERT INTO complaints
           (society_id, ref, title, description, category_id, unit_id, location,
            priority, status, is_private, created_by, sla_minutes, sla_config, due_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'open',$9,$10,$11,$12,$13)
         RETURNING *`,
        [societyId, ref, input.title, input.description, input.categoryId || null,
         input.unitId || null, input.location || null, priority, input.isPrivate || false,
         createdBy || null, slaMinutes, JSON.stringify(cfg), due]
      );

      await client.query(
        `INSERT INTO complaint_status_history (society_id, complaint_id, from_status, to_status, actor_id, note)
         VALUES ($1, $2, NULL, 'open', $3, 'created')`,
        [societyId, rows[0].id, createdBy || null]
      );

      await OutboxService.emit(client, {
        societyId,
        topic: `society:${societyId}`,
        type: "complaint.created",
        payload: { id: rows[0].id, ref },
      });

      logger.info({ societyId, complaintId: rows[0].id, ref, priority, dueAt: due }, "Complaint created");
      return rows[0];
    });
  },

  async assign(
    societyId: string,
    complaintId: string,
    assigneeId: string,
    assigneeType: "staff" | "committee" | "vendor",
    assignedBy?: string,
    reason?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM complaints WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [complaintId, societyId]
      );
      if (!rows[0]) throw err("Complaint not found", "NOT_FOUND");

      await client.query(
        `INSERT INTO complaint_assignments (society_id, complaint_id, assignee_id, assignee_type, assigned_by, reason)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [societyId, complaintId, assigneeId, assigneeType, assignedBy || null, reason || null]
      );

      // Assignment moves an untouched complaint into progress + records first response.
      const nextStatus = rows[0].status === "open" ? "in_progress" : rows[0].status;
      const upd = await client.query(
        `UPDATE complaints
            SET assigned_to = $3, status = $4,
                first_response_at = COALESCE(first_response_at, now()),
                version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [complaintId, societyId, assigneeId, nextStatus]
      );
      if (nextStatus !== rows[0].status) {
        await client.query(
          `INSERT INTO complaint_status_history (society_id, complaint_id, from_status, to_status, actor_id, note)
           VALUES ($1,$2,$3,$4,$5,'auto: assigned')`,
          [societyId, complaintId, rows[0].status, nextStatus, assignedBy || null]
        );
      }
      logger.info({ societyId, complaintId, assigneeId, assigneeType }, "Complaint assigned");
      return upd.rows[0];
    });
  },

  async changeStatus(
    societyId: string,
    complaintId: string,
    to: ComplaintStatus,
    actorId?: string,
    note?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM complaints WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [complaintId, societyId]
      );
      const c = rows[0];
      if (!c) throw err("Complaint not found", "NOT_FOUND");

      const from = c.status as ComplaintStatus;
      assertTransition(from, to); // throws INVALID_TRANSITION
      if (from === to) return c; // idempotent

      const reopen = isReopen(from, to);
      const sets: string[] = ["status = $3", "version = version + 1", "updated_at = now()"];
      const params: any[] = [complaintId, societyId, to];

      if (to === "resolved") {
        params.push(note || null);
        sets.push(`resolved_at = now()`, `resolution_note = $${params.length}`);
      }
      if (to === "closed") sets.push(`closed_at = now()`);
      if (reopen) sets.push(`reopen_count = reopen_count + 1`, `resolved_at = NULL`, `closed_at = NULL`);

      const upd = await client.query(
        `UPDATE complaints SET ${sets.join(", ")} WHERE id = $1 AND society_id = $2 RETURNING *`,
        params
      );

      await client.query(
        `INSERT INTO complaint_status_history (society_id, complaint_id, from_status, to_status, actor_id, note)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [societyId, complaintId, from, to, actorId || null, note || (reopen ? "reopened" : null)]
      );

      // Reopening restarts the SLA clock from now with a fresh due time.
      if (reopen) await recomputeDueAt(client, societyId, complaintId);

      logger.info({ societyId, complaintId, from, to, reopen }, "Complaint status changed");
      return upd.rows[0];
    });
  },

  /** Pause/resume the SLA clock and recompute due_at. */
  async setSlaPause(societyId: string, complaintId: string, pause: boolean, reason?: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT id FROM complaints WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [complaintId, societyId]
      );
      if (!rows[0]) throw err("Complaint not found", "NOT_FOUND");
      await client.query(
        `INSERT INTO complaint_sla_events (society_id, complaint_id, event, reason)
         VALUES ($1,$2,$3,$4)`,
        [societyId, complaintId, pause ? "pause" : "resume", reason || null]
      );
      const due = await recomputeDueAt(client, societyId, complaintId);
      logger.info({ societyId, complaintId, pause, dueAt: due }, "Complaint SLA pause toggled");
      return { dueAt: due };
    });
  },

  async addComment(
    societyId: string,
    complaintId: string,
    input: { body: string; visibility: "internal" | "resident"; authorId: string; authorName?: string }
  ) {
    const owns = await db.query(
      `SELECT id FROM complaints WHERE id = $1 AND society_id = $2`,
      [complaintId, societyId]
    );
    if (!owns.rows[0]) throw err("Complaint not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO complaint_comments (society_id, complaint_id, visibility, author_id, author_name, body)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [societyId, complaintId, input.visibility, input.authorId, input.authorName || null, input.body]
    );
    return rows[0];
  },

  /** Submit CSAT once. Unique(complaint_id) enforces single rating. */
  async submitFeedback(
    societyId: string,
    complaintId: string,
    rating: number,
    comment?: string,
    submittedBy?: string
  ) {
    const c = await db.query(
      `SELECT status FROM complaints WHERE id = $1 AND society_id = $2`,
      [complaintId, societyId]
    );
    if (!c.rows[0]) throw err("Complaint not found", "NOT_FOUND");
    if (!["resolved", "closed"].includes(c.rows[0].status)) {
      throw err("Feedback allowed only after resolution", "INVALID_STATE");
    }
    try {
      const { rows } = await db.query(
        `INSERT INTO complaint_feedback (society_id, complaint_id, rating, comment, submitted_by)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [societyId, complaintId, rating, comment || null, submittedBy || null]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Feedback already submitted", "ALREADY_EXISTS");
      throw e;
    }
  },

  async listComplaints(
    societyId: string,
    opts: { status?: string; assignedTo?: string; overdue?: boolean; limit?: number } = {}
  ) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    if (opts.assignedTo) {
      params.push(opts.assignedTo);
      where += ` AND assigned_to = $${params.length}`;
    }
    if (opts.overdue) where += ` AND due_at IS NOT NULL AND due_at < now() AND status NOT IN ('resolved','closed')`;
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM complaints WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /**
   * Full detail. `includeInternal` gates internal notes — residents must never
   * see internal comments, so callers pass false for resident audiences.
   */
  async getComplaint(societyId: string, complaintId: string, includeInternal: boolean) {
    const { rows } = await db.query(
      `SELECT * FROM complaints WHERE id = $1 AND society_id = $2`,
      [complaintId, societyId]
    );
    const complaint = rows[0];
    if (!complaint) return null;

    const commentWhere = includeInternal ? `` : ` AND visibility = 'resident'`;
    const [assignments, comments, history, sla, feedback] = await Promise.all([
      db.query(`SELECT * FROM complaint_assignments WHERE complaint_id = $1 ORDER BY created_at ASC`, [complaintId]),
      db.query(`SELECT * FROM complaint_comments WHERE complaint_id = $1${commentWhere} ORDER BY created_at ASC`, [complaintId]),
      db.query(`SELECT * FROM complaint_status_history WHERE complaint_id = $1 ORDER BY created_at ASC`, [complaintId]),
      db.query(`SELECT * FROM complaint_sla_events WHERE complaint_id = $1 ORDER BY occurred_at ASC`, [complaintId]),
      db.query(`SELECT * FROM complaint_feedback WHERE complaint_id = $1`, [complaintId]),
    ]);

    return {
      complaint,
      assignments: assignments.rows,
      comments: comments.rows,
      statusHistory: history.rows,
      slaEvents: sla.rows,
      feedback: feedback.rows[0] || null,
    };
  },

  /**
   * Capability 65 — Escalation ladder WORKER.
   * Finds breached complaints (due_at < now, not resolved/closed), records an
   * escalation event + bumps the breach flag. Idempotent: the unique constraint
   * on (complaint_id, level, due_at_at_escalation) prevents duplicate rows for the
   * same complaint+level within the same breach window. Returns count escalated.
   */
  async runEscalations(societyId?: string) {
    const params: any[] = [];
    let scope = ``;
    if (societyId) {
      params.push(societyId);
      scope = ` AND society_id = $1`;
    }
    const { rows } = await db.query(
      `SELECT id, society_id, due_at FROM complaints
        WHERE due_at IS NOT NULL AND due_at < now()
          AND status NOT IN ('resolved','closed')${scope}`,
      params
    );

    let escalated = 0;
    for (const c of rows) {
      await withTx(async (client) => {
        // One escalation per breach window (per distinct due_at). Re-running the
        // worker for the same breached due_at is a no-op. The ladder level advances
        // across distinct breaches (e.g. after a reopen recomputes a new due_at).
        const existing = await client.query(
          `SELECT 1 FROM complaint_escalations
            WHERE complaint_id = $1 AND due_at_at_escalation = $2 LIMIT 1`,
          [c.id, c.due_at]
        );
        if (existing.rows[0]) return; // already escalated for this breach — idempotent
        const priorLevels = await client.query(
          `SELECT count(DISTINCT due_at_at_escalation)::int n FROM complaint_escalations
            WHERE complaint_id = $1`,
          [c.id]
        );
        const level = priorLevels.rows[0].n + 1;
        const ins = await client.query(
          `INSERT INTO complaint_escalations
             (society_id, complaint_id, level, due_at_at_escalation, reason)
           VALUES ($1,$2,$3,$4,$5)
           ON CONFLICT (complaint_id, level, due_at_at_escalation) DO NOTHING
           RETURNING id`,
          [c.society_id, c.id, level, c.due_at, `sla_breach_level_${level}`]
        );
        if (!ins.rows[0]) return; // already escalated at this level — idempotent no-op
        await client.query(
          `INSERT INTO complaint_sla_events (society_id, complaint_id, event, reason)
           VALUES ($1,$2,'escalate',$3)`,
          [c.society_id, c.id, `level_${level}`]
        );
        await client.query(
          `UPDATE complaints SET sla_breached = true, updated_at = now()
            WHERE id = $1 AND society_id = $2`,
          [c.id, c.society_id]
        );
        escalated++;
      });
    }
    logger.info({ societyId: societyId || "all", escalated }, "Complaint escalations run");
    return { scanned: rows.length, escalated };
  },

  /** Capability 67 — attach evidence to a complaint (tenant-scoped). */
  async addAttachment(
    societyId: string,
    complaintId: string,
    input: { fileUrl: string; mime?: string; kind?: string; uploadedBy?: string }
  ) {
    const owns = await db.query(
      `SELECT id FROM complaints WHERE id = $1 AND society_id = $2`,
      [complaintId, societyId]
    );
    if (!owns.rows[0]) throw err("Complaint not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO complaint_attachments (society_id, complaint_id, file_url, mime, kind, uploaded_by)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [societyId, complaintId, input.fileUrl, input.mime || null, input.kind || null, input.uploadedBy || null]
    );
    return rows[0];
  },

  /** Capability 67 — list a complaint's attachments (tenant-scoped). */
  async listAttachments(societyId: string, complaintId: string) {
    const owns = await db.query(
      `SELECT id FROM complaints WHERE id = $1 AND society_id = $2`,
      [complaintId, societyId]
    );
    if (!owns.rows[0]) throw err("Complaint not found", "NOT_FOUND");
    const { rows } = await db.query(
      `SELECT * FROM complaint_attachments
        WHERE complaint_id = $1 AND society_id = $2 ORDER BY created_at ASC`,
      [complaintId, societyId]
    );
    return rows;
  },

  /** SLA/resolution analytics for dashboards (capability 69). */
  async analytics(societyId: string) {
    const { rows } = await db.query(
      `SELECT
         count(*)::int AS total,
         count(*) FILTER (WHERE status IN ('open','in_progress'))::int AS open,
         count(*) FILTER (WHERE status IN ('resolved','closed'))::int AS resolved,
         count(*) FILTER (WHERE due_at IS NOT NULL AND due_at < now() AND status NOT IN ('resolved','closed'))::int AS overdue,
         count(*) FILTER (WHERE sla_breached)::int AS breached
       FROM complaints WHERE society_id = $1`,
      [societyId]
    );
    const csat = await db.query(
      `SELECT round(avg(rating)::numeric, 2) AS avg_rating, count(*)::int AS responses
         FROM complaint_feedback WHERE society_id = $1`,
      [societyId]
    );
    return { ...rows[0], csat: csat.rows[0] };
  },
};
