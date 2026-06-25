import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { OutboxService } from "../outbox/OutboxService";

/**
 * Phase 4 notices workflow (capabilities 43–49).
 *
 * Design rules enforced here:
 *  - Lifecycle: draft -> scheduled -> published -> archived. An archived notice
 *    is terminal and may not be edited.
 *  - Every meaningful edit and every publish snapshots title/body into
 *    notice_versions and bumps the notice version counter (in one transaction).
 *  - Audience targeting is a set of rows in notice_audiences; setAudiences
 *    replaces the whole set atomically.
 *  - Read receipts and acknowledgements are per-user in notice_reads; acknowledge
 *    is only permitted when the notice requires it (ack_required).
 *  - Soft delete via deleted_at; deleted rows are excluded from every read.
 *  - All reads/writes are tenant-scoped by society_id.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

type AudienceType = "all" | "role" | "wing" | "block" | "unit" | "ownership" | "custom";

export const NoticeService = {
  async createNotice(
    societyId: string,
    input: {
      title: string;
      body: string;
      type?: "general" | "event" | "maintenance" | "festival" | "governance";
      category?: string;
      priority?: "low" | "medium" | "high" | "critical";
      ackRequired?: boolean;
      expiresAt?: string;
    },
    author?: { id?: string; name?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO notices
         (society_id, title, body, type, category, priority, status, ack_required,
          author_id, author_name, expires_at)
       VALUES ($1,$2,$3,$4,$5,$6,'draft',$7,$8,$9,$10)
       RETURNING *`,
      [
        societyId, input.title, input.body, input.type || "general", input.category || null,
        input.priority || "medium", input.ackRequired || false,
        author?.id || null, author?.name || null, input.expiresAt || null,
      ]
    );
    logger.info({ societyId, noticeId: rows[0].id }, "Notice created (draft)");
    return rows[0];
  },

  /**
   * Edit a notice. Bumps version + snapshots the new title/body into
   * notice_versions. Editing an archived notice is rejected.
   */
  async updateNotice(
    societyId: string,
    noticeId: string,
    input: {
      title?: string;
      body?: string;
      type?: "general" | "event" | "maintenance" | "festival" | "governance";
      category?: string;
      priority?: "low" | "medium" | "high" | "critical";
      ackRequired?: boolean;
      expiresAt?: string | null;
    },
    editedBy?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL FOR UPDATE`,
        [noticeId, societyId]
      );
      const notice = rows[0];
      if (!notice) throw err("Notice not found", "NOT_FOUND");
      if (notice.status === "archived") throw err("Archived notice cannot be edited", "INVALID_STATE");

      const sets: string[] = ["version = version + 1", "updated_at = now()"];
      const params: any[] = [noticeId, societyId];
      const setCol = (col: string, val: any) => {
        params.push(val);
        sets.push(`${col} = $${params.length}`);
      };
      if (input.title !== undefined) setCol("title", input.title);
      if (input.body !== undefined) setCol("body", input.body);
      if (input.type !== undefined) setCol("type", input.type);
      if (input.category !== undefined) setCol("category", input.category);
      if (input.priority !== undefined) setCol("priority", input.priority);
      if (input.ackRequired !== undefined) setCol("ack_required", input.ackRequired);
      if (input.expiresAt !== undefined) setCol("expires_at", input.expiresAt);

      const upd = await client.query(
        `UPDATE notices SET ${sets.join(", ")} WHERE id = $1 AND society_id = $2 RETURNING *`,
        params
      );
      const next = upd.rows[0];

      await client.query(
        `INSERT INTO notice_versions (society_id, notice_id, version, title, body, edited_by)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [societyId, noticeId, next.version, next.title, next.body, editedBy || null]
      );

      logger.info({ societyId, noticeId, version: next.version }, "Notice updated + version snapshotted");
      return next;
    });
  },

  /** Replace the full audience set for a notice in one transaction. */
  async setAudiences(
    societyId: string,
    noticeId: string,
    audiences: { type: AudienceType; value?: string }[]
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT id, status FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL FOR UPDATE`,
        [noticeId, societyId]
      );
      if (!rows[0]) throw err("Notice not found", "NOT_FOUND");

      await client.query(`DELETE FROM notice_audiences WHERE notice_id = $1 AND society_id = $2`, [noticeId, societyId]);
      for (const a of audiences) {
        await client.query(
          `INSERT INTO notice_audiences (society_id, notice_id, audience_type, audience_value)
           VALUES ($1,$2,$3,$4)`,
          [societyId, noticeId, a.type, a.value || null]
        );
      }
      const out = await client.query(
        `SELECT * FROM notice_audiences WHERE notice_id = $1 ORDER BY created_at ASC`,
        [noticeId]
      );
      logger.info({ societyId, noticeId, count: audiences.length }, "Notice audiences set");
      return out.rows;
    });
  },

  /** Schedule a draft for future publication at publishAt (UTC). */
  async schedule(societyId: string, noticeId: string, publishAt: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL FOR UPDATE`,
        [noticeId, societyId]
      );
      const notice = rows[0];
      if (!notice) throw err("Notice not found", "NOT_FOUND");
      if (notice.status === "archived") throw err("Archived notice cannot be scheduled", "INVALID_STATE");
      if (notice.status === "published") throw err("Published notice cannot be scheduled", "INVALID_STATE");

      const upd = await client.query(
        `UPDATE notices SET status = 'scheduled', scheduled_at = $3, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [noticeId, societyId, publishAt]
      );
      logger.info({ societyId, noticeId, publishAt }, "Notice scheduled");
      return upd.rows[0];
    });
  },

  /**
   * Publish a notice. Snapshots the current title/body as a version. If the
   * notice carries a future scheduled_at it stays "scheduled"; otherwise it
   * becomes "published" with published_at = now().
   */
  async publish(societyId: string, noticeId: string, actorId?: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL FOR UPDATE`,
        [noticeId, societyId]
      );
      const notice = rows[0];
      if (!notice) throw err("Notice not found", "NOT_FOUND");
      if (notice.status === "archived") throw err("Archived notice cannot be published", "INVALID_STATE");

      // A future schedule keeps the notice queued rather than going live now.
      const future = notice.scheduled_at && new Date(notice.scheduled_at).getTime() > Date.now();
      const nextVersion = notice.version + 1;

      let upd;
      if (future) {
        upd = await client.query(
          `UPDATE notices SET status = 'scheduled', version = $3, updated_at = now()
           WHERE id = $1 AND society_id = $2 RETURNING *`,
          [noticeId, societyId, nextVersion]
        );
      } else {
        upd = await client.query(
          `UPDATE notices SET status = 'published', published_at = now(), version = $3, updated_at = now()
           WHERE id = $1 AND society_id = $2 RETURNING *`,
          [noticeId, societyId, nextVersion]
        );
      }
      const next = upd.rows[0];

      await client.query(
        `INSERT INTO notice_versions (society_id, notice_id, version, title, body, edited_by)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [societyId, noticeId, next.version, next.title, next.body, actorId || null]
      );

      // Fan-out side-effects only when the notice actually goes live now (a future
      // schedule keeps it queued and will be (re)published by the scheduler later).
      if (next.status === "published") {
        // 1) Realtime/outbox event — same transactional outbox the SSE gateway drains.
        await OutboxService.emit(client, {
          societyId,
          topic: `society:${societyId}`,
          type: "notice.published",
          payload: { id: next.id, title: next.title, priority: next.priority },
        });

        // 2) Per-recipient in-app notification rows. Default audience is every
        //    approved member of the society that has a linked login (user_id).
        const recipients = await client.query(
          `SELECT DISTINCT user_id FROM members
            WHERE society_id = $1 AND status = 'approved' AND user_id IS NOT NULL`,
          [societyId]
        );
        for (const r of recipients.rows) {
          await client.query(
            `INSERT INTO notifications (society_id, user_id, title, body, type, data)
             VALUES ($1,$2,$3,$4,'notice',$5)`,
            [
              societyId,
              r.user_id,
              next.title,
              next.body,
              JSON.stringify({ noticeId: next.id, priority: next.priority, deepLink: `sero://notices/${next.id}` }),
            ]
          );
        }
        logger.info(
          { societyId, noticeId, recipients: recipients.rows.length },
          "Notice publish side-effects emitted (outbox + notifications)"
        );
      }

      logger.info({ societyId, noticeId, status: next.status, version: next.version }, "Notice published");
      return next;
    });
  },

  /** Revert a published notice back to draft (e.g. to fix an error). */
  async unpublish(societyId: string, noticeId: string) {
    const { rows } = await db.query(
      `SELECT status FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL`,
      [noticeId, societyId]
    );
    if (!rows[0]) throw err("Notice not found", "NOT_FOUND");
    if (!["published", "scheduled"].includes(rows[0].status)) {
      throw err(`Cannot unpublish a ${rows[0].status} notice`, "INVALID_STATE");
    }
    const upd = await db.query(
      `UPDATE notices SET status = 'draft', published_at = NULL, scheduled_at = NULL, updated_at = now()
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [noticeId, societyId]
    );
    logger.info({ societyId, noticeId }, "Notice unpublished");
    return upd.rows[0];
  },

  /** Archive a notice (terminal state). */
  async archive(societyId: string, noticeId: string) {
    const { rows } = await db.query(
      `SELECT status FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL`,
      [noticeId, societyId]
    );
    if (!rows[0]) throw err("Notice not found", "NOT_FOUND");
    if (rows[0].status === "archived") throw err("Notice already archived", "INVALID_STATE");
    const upd = await db.query(
      `UPDATE notices SET status = 'archived', updated_at = now()
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [noticeId, societyId]
    );
    logger.info({ societyId, noticeId }, "Notice archived");
    return upd.rows[0];
  },

  async listNotices(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1 AND deleted_at IS NULL`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM notices WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /** Full detail: notice + audiences + read/ack statistics. */
  async getNotice(societyId: string, noticeId: string) {
    const { rows } = await db.query(
      `SELECT * FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL`,
      [noticeId, societyId]
    );
    const notice = rows[0];
    if (!notice) return null;

    const [audiences, stats] = await Promise.all([
      db.query(`SELECT * FROM notice_audiences WHERE notice_id = $1 ORDER BY created_at ASC`, [noticeId]),
      db.query(
        `SELECT
           count(*)::int AS read_count,
           count(*) FILTER (WHERE acknowledged)::int AS ack_count
         FROM notice_reads WHERE notice_id = $1 AND society_id = $2`,
        [noticeId, societyId]
      ),
    ]);

    return {
      notice,
      audiences: audiences.rows,
      readStats: stats.rows[0],
    };
  },

  /** Record (idempotently) that a user has read a notice. */
  async markRead(societyId: string, noticeId: string, userId: string) {
    const owns = await db.query(
      `SELECT id FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL`,
      [noticeId, societyId]
    );
    if (!owns.rows[0]) throw err("Notice not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO notice_reads (society_id, notice_id, user_id)
       VALUES ($1,$2,$3)
       ON CONFLICT (notice_id, user_id) DO UPDATE SET read_at = notice_reads.read_at
       RETURNING *`,
      [societyId, noticeId, userId]
    );
    return rows[0];
  },

  /** Acknowledge a notice. Only permitted when the notice requires acknowledgement. */
  async acknowledge(societyId: string, noticeId: string, userId: string) {
    const { rows } = await db.query(
      `SELECT ack_required FROM notices WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL`,
      [noticeId, societyId]
    );
    if (!rows[0]) throw err("Notice not found", "NOT_FOUND");
    if (!rows[0].ack_required) throw err("Notice does not require acknowledgement", "INVALID_STATE");

    const upd = await db.query(
      `INSERT INTO notice_reads (society_id, notice_id, user_id, acknowledged, acknowledged_at)
       VALUES ($1,$2,$3,true,now())
       ON CONFLICT (notice_id, user_id)
         DO UPDATE SET acknowledged = true, acknowledged_at = now()
       RETURNING *`,
      [societyId, noticeId, userId]
    );
    logger.info({ societyId, noticeId, userId }, "Notice acknowledged");
    return upd.rows[0];
  },

  /** Count published, non-expired notices the user has not yet read. */
  async unreadCountForUser(societyId: string, userId: string) {
    const { rows } = await db.query(
      `SELECT count(*)::int AS unread
         FROM notices n
        WHERE n.society_id = $1
          AND n.deleted_at IS NULL
          AND n.status = 'published'
          AND (n.expires_at IS NULL OR n.expires_at > now())
          AND NOT EXISTS (
            SELECT 1 FROM notice_reads r
             WHERE r.notice_id = n.id AND r.user_id = $2
          )`,
      [societyId, userId]
    );
    return rows[0].unread;
  },
};
