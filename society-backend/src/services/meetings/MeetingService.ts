import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Meetings & Governance. Tenant-scoped by society_id; all timestamps are UTC.
 * Covers meeting creation + calendar, agenda, attendance, proxies, quorum,
 * resolutions + voting outcome, minutes, and action items with owners/deadlines.
 *
 * Status lifecycle: scheduled -> in_progress -> completed; scheduled -> cancelled.
 */
export const MeetingService = {
  async createMeeting(
    societyId: string,
    input: {
      title: string;
      type?: "agm" | "committee" | "general";
      scheduledAt?: string | null;
      location?: string | null;
      quorumRequired?: number;
      agendaItems?: { title: string; description?: string | null }[];
    },
    createdBy?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO meetings (society_id, title, type, scheduled_at, location, quorum_required, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [
          societyId,
          input.title,
          input.type || "committee",
          input.scheduledAt || null,
          input.location || null,
          input.quorumRequired || 0,
          createdBy || null,
        ]
      );
      const meeting = rows[0];

      const agenda: any[] = [];
      const items = input.agendaItems || [];
      for (let i = 0; i < items.length; i++) {
        const a = await client.query(
          `INSERT INTO meeting_agenda_items (society_id, meeting_id, position, title, description)
           VALUES ($1, $2, $3, $4, $5) RETURNING *`,
          [societyId, meeting.id, i, items[i].title, items[i].description || null]
        );
        agenda.push(a.rows[0]);
      }

      logger.info({ societyId, meetingId: meeting.id, type: meeting.type }, "Meeting created");
      return { ...meeting, agenda };
    });
  },

  async addAgendaItem(
    societyId: string,
    meetingId: string,
    input: { title: string; description?: string | null; position?: number }
  ) {
    const meeting = await this.requireMeeting(societyId, meetingId);
    let position = input.position;
    if (position === undefined || position === null) {
      const { rows } = await db.query(
        `SELECT COALESCE(MAX(position), -1) + 1 AS next FROM meeting_agenda_items WHERE society_id = $1 AND meeting_id = $2`,
        [societyId, meeting.id]
      );
      position = Number(rows[0].next);
    }
    const { rows } = await db.query(
      `INSERT INTO meeting_agenda_items (society_id, meeting_id, position, title, description)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [societyId, meeting.id, position, input.title, input.description || null]
    );
    return rows[0];
  },

  /** Upsert attendance for a (meeting, user). */
  async recordAttendance(societyId: string, meetingId: string, userId: string, present: boolean) {
    await this.requireMeeting(societyId, meetingId);
    const { rows } = await db.query(
      `INSERT INTO meeting_attendance (society_id, meeting_id, user_id, present)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (meeting_id, user_id)
       DO UPDATE SET present = EXCLUDED.present
       RETURNING *`,
      [societyId, meetingId, userId, present]
    );
    return rows[0];
  },

  /** Upsert a proxy. A grantor may proxy only once per meeting. */
  async grantProxy(societyId: string, meetingId: string, grantorId: string, proxyHolderId: string) {
    await this.requireMeeting(societyId, meetingId);
    const { rows } = await db.query(
      `INSERT INTO proxies (society_id, meeting_id, grantor_id, proxy_holder_id)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (meeting_id, grantor_id)
       DO UPDATE SET proxy_holder_id = EXCLUDED.proxy_holder_id
       RETURNING *`,
      [societyId, meetingId, grantorId, proxyHolderId]
    );
    return rows[0];
  },

  /** Present headcount counts present attendees plus granted proxies. */
  async quorumStatus(societyId: string, meetingId: string) {
    const meeting = await this.requireMeeting(societyId, meetingId);
    const att = await db.query(
      `SELECT COUNT(*)::int AS n FROM meeting_attendance WHERE society_id = $1 AND meeting_id = $2 AND present = true`,
      [societyId, meetingId]
    );
    const prox = await db.query(
      `SELECT COUNT(*)::int AS n FROM proxies WHERE society_id = $1 AND meeting_id = $2`,
      [societyId, meetingId]
    );
    const present = Number(att.rows[0].n) + Number(prox.rows[0].n);
    const required = Number(meeting.quorum_required);
    return { present, required, met: present >= required };
  },

  async addResolution(
    societyId: string,
    meetingId: string,
    input: { title: string; text?: string | null }
  ) {
    await this.requireMeeting(societyId, meetingId);
    const { rows } = await db.query(
      `INSERT INTO resolutions (society_id, meeting_id, title, text)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [societyId, meetingId, input.title, input.text || null]
    );
    return rows[0];
  },

  async recordResolutionOutcome(
    societyId: string,
    resolutionId: string,
    outcome: "pending" | "passed" | "failed",
    votesFor: number,
    votesAgainst: number
  ) {
    const { rows } = await db.query(
      `UPDATE resolutions SET outcome = $3, votes_for = $4, votes_against = $5
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [resolutionId, societyId, outcome, votesFor || 0, votesAgainst || 0]
    );
    if (!rows[0]) throw Object.assign(new Error("Resolution not found"), { code: "NOT_FOUND" });
    return rows[0];
  },

  async addMinutes(
    societyId: string,
    meetingId: string,
    input: { body: string },
    recordedBy?: string
  ) {
    await this.requireMeeting(societyId, meetingId);
    const { rows } = await db.query(
      `INSERT INTO minutes (society_id, meeting_id, body, recorded_by)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [societyId, meetingId, input.body, recordedBy || null]
    );
    return rows[0];
  },

  async addActionItem(
    societyId: string,
    meetingId: string,
    input: { description: string; ownerId?: string | null; dueDate?: string | null }
  ) {
    await this.requireMeeting(societyId, meetingId);
    const { rows } = await db.query(
      `INSERT INTO action_items (society_id, meeting_id, description, owner_id, due_date)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [societyId, meetingId, input.description, input.ownerId || null, input.dueDate || null]
    );
    return rows[0];
  },

  async updateActionItem(societyId: string, actionItemId: string, status: "open" | "in_progress" | "done") {
    const { rows } = await db.query(
      `UPDATE action_items SET status = $3, updated_at = now()
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [actionItemId, societyId, status]
    );
    if (!rows[0]) throw Object.assign(new Error("Action item not found"), { code: "NOT_FOUND" });
    return rows[0];
  },

  async startMeeting(societyId: string, meetingId: string) {
    return this.transition(societyId, meetingId, "scheduled", "in_progress");
  },

  async completeMeeting(societyId: string, meetingId: string) {
    return this.transition(societyId, meetingId, "in_progress", "completed");
  },

  async cancelMeeting(societyId: string, meetingId: string) {
    return this.transition(societyId, meetingId, "scheduled", "cancelled");
  },

  async transition(societyId: string, meetingId: string, from: string, to: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM meetings WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [meetingId, societyId]
      );
      const meeting = rows[0];
      if (!meeting) throw Object.assign(new Error("Meeting not found"), { code: "NOT_FOUND" });
      if (meeting.status !== from) {
        throw Object.assign(
          new Error(`Cannot move meeting from ${meeting.status} to ${to}`),
          { code: "INVALID_STATE" }
        );
      }
      const upd = await client.query(
        `UPDATE meetings SET status = $3, version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [meetingId, societyId, to]
      );
      logger.info({ societyId, meetingId, from, to }, "Meeting status changed");
      return upd.rows[0];
    });
  },

  async listMeetings(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM meetings WHERE ${where} ORDER BY COALESCE(scheduled_at, created_at) DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  async getMeeting(societyId: string, meetingId: string) {
    const { rows } = await db.query(
      `SELECT * FROM meetings WHERE id = $1 AND society_id = $2`,
      [meetingId, societyId]
    );
    const meeting = rows[0];
    if (!meeting) return null;

    const [agenda, attendance, resolutions, minutes, actionItems] = await Promise.all([
      db.query(
        `SELECT * FROM meeting_agenda_items WHERE society_id = $1 AND meeting_id = $2 ORDER BY position ASC`,
        [societyId, meetingId]
      ),
      db.query(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE present = true)::int AS present
         FROM meeting_attendance WHERE society_id = $1 AND meeting_id = $2`,
        [societyId, meetingId]
      ),
      db.query(
        `SELECT * FROM resolutions WHERE society_id = $1 AND meeting_id = $2 ORDER BY created_at ASC`,
        [societyId, meetingId]
      ),
      db.query(
        `SELECT * FROM minutes WHERE society_id = $1 AND meeting_id = $2 ORDER BY created_at ASC`,
        [societyId, meetingId]
      ),
      db.query(
        `SELECT * FROM action_items WHERE society_id = $1 AND meeting_id = $2 ORDER BY created_at ASC`,
        [societyId, meetingId]
      ),
    ]);

    return {
      meeting,
      agenda: agenda.rows,
      attendance: { total: Number(attendance.rows[0].total), present: Number(attendance.rows[0].present) },
      resolutions: resolutions.rows,
      minutes: minutes.rows,
      actionItems: actionItems.rows,
    };
  },

  async requireMeeting(societyId: string, meetingId: string) {
    const { rows } = await db.query(
      `SELECT * FROM meetings WHERE id = $1 AND society_id = $2`,
      [meetingId, societyId]
    );
    if (!rows[0]) throw Object.assign(new Error("Meeting not found"), { code: "NOT_FOUND" });
    return rows[0];
  },
};
