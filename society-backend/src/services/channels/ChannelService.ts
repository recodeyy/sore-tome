import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Channels / messaging + moderation (Phase 4, capabilities 50–51).
 *
 * - Read-only channels: only admins may post (enforced by the route passing
 *   `isAdmin`); members may always read.
 * - Cursor pagination over messages by (created_at, id).
 * - Read receipts via message_reads (last_read_message_id); unread = messages
 *   newer than the user's last read.
 * - Abuse reports + admin moderation: messages are SOFT-deleted (deleted_at) so
 *   history/retention is preserved; every action is recorded in moderation_actions.
 * All reads/writes are tenant-scoped by society_id.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const ChannelService = {
  async createChannel(
    societyId: string,
    input: { name: string; description?: string; type?: "community" | "announcement" | "committee" | "support"; isReadOnly?: boolean },
    createdBy?: string
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO channels (society_id, name, description, type, is_read_only, created_by)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [societyId, input.name, input.description || null, input.type || "community", input.isReadOnly || false, createdBy || null]
      );
      logger.info({ societyId, channelId: rows[0].id }, "Channel created");
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("A channel with this name already exists", "ALREADY_EXISTS");
      throw e;
    }
  },

  async listChannels(societyId: string, opts: { includeArchived?: boolean } = {}) {
    const { rows } = await db.query(
      `SELECT c.*,
              (SELECT count(*)::int FROM channel_members m WHERE m.channel_id = c.id) AS member_count
         FROM channels c
        WHERE c.society_id = $1 ${opts.includeArchived ? "" : "AND c.is_archived = false"}
        ORDER BY c.updated_at DESC`,
      [societyId]
    );
    return rows;
  },

  async addMember(societyId: string, channelId: string, userId: string, role: "member" | "moderator" = "member") {
    await this.requireChannel(societyId, channelId);
    const { rows } = await db.query(
      `INSERT INTO channel_members (society_id, channel_id, user_id, role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (channel_id, user_id) DO UPDATE SET role = EXCLUDED.role
       RETURNING *`,
      [societyId, channelId, userId, role]
    );
    return rows[0];
  },

  async isMember(societyId: string, channelId: string, userId: string) {
    const { rows } = await db.query(
      `SELECT 1 FROM channel_members WHERE society_id = $1 AND channel_id = $2 AND user_id = $3 LIMIT 1`,
      [societyId, channelId, userId]
    );
    return rows.length > 0;
  },

  /**
   * Post a message. Read-only channels reject non-admins. Posting auto-joins the
   * author as a member for convenience.
   */
  async postMessage(
    societyId: string,
    channelId: string,
    input: { body: string; authorId: string; authorName?: string; isOfficial?: boolean; isAdmin?: boolean }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM channels WHERE id = $1 AND society_id = $2 FOR SHARE`,
        [channelId, societyId]
      );
      const channel = rows[0];
      if (!channel) throw err("Channel not found", "NOT_FOUND");
      if (channel.is_archived) throw err("Channel is archived", "INVALID_STATE");
      if (channel.is_read_only && !input.isAdmin) throw err("This channel is read-only", "READ_ONLY");

      await client.query(
        `INSERT INTO channel_members (society_id, channel_id, user_id, role)
         VALUES ($1, $2, $3, 'member') ON CONFLICT (channel_id, user_id) DO NOTHING`,
        [societyId, channelId, input.authorId]
      );

      const ins = await client.query(
        `INSERT INTO messages (society_id, channel_id, author_id, author_name, body, is_official)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [societyId, channelId, input.authorId, input.authorName || null, input.body, (input.isOfficial && input.isAdmin) || false]
      );
      await client.query(`UPDATE channels SET updated_at = now() WHERE id = $1`, [channelId]);
      return ins.rows[0];
    });
  },

  /**
   * Cursor-paginated messages, newest first. `cursor` is the created_at ISO of the
   * last seen message; rows strictly older are returned. Soft-deleted messages are
   * returned with body masked unless `includeDeleted` (admin view).
   */
  async listMessages(
    societyId: string,
    channelId: string,
    opts: { limit?: number; cursor?: string; includeDeleted?: boolean } = {}
  ) {
    await this.requireChannel(societyId, channelId);
    const limit = Math.min(opts.limit || 30, 100);
    const params: any[] = [societyId, channelId];
    let where = `society_id = $1 AND channel_id = $2`;
    if (opts.cursor) {
      params.push(opts.cursor);
      where += ` AND created_at < $${params.length}`;
    }
    params.push(limit + 1);
    const { rows } = await db.query(
      `SELECT * FROM messages WHERE ${where} ORDER BY created_at DESC, id DESC LIMIT $${params.length}`,
      params
    );
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit).map((m: any) => {
      if (m.deleted_at && !opts.includeDeleted) return { ...m, body: "[removed by moderator]" };
      return m;
    });
    const nextCursor = hasMore ? page[page.length - 1].created_at : null;
    return { messages: page, nextCursor };
  },

  /** Mark messages read up to a given message; updates the read receipt. */
  async markRead(societyId: string, channelId: string, userId: string, lastReadMessageId?: string) {
    await this.requireChannel(societyId, channelId);
    const { rows } = await db.query(
      `INSERT INTO message_reads (society_id, channel_id, user_id, last_read_message_id, last_read_at)
       VALUES ($1, $2, $3, $4, now())
       ON CONFLICT (channel_id, user_id)
       DO UPDATE SET last_read_message_id = EXCLUDED.last_read_message_id, last_read_at = now()
       RETURNING *`,
      [societyId, channelId, userId, lastReadMessageId || null]
    );
    return rows[0];
  },

  /** Unread count for a user in a channel (messages newer than last_read_at). */
  async unreadCount(societyId: string, channelId: string, userId: string) {
    const { rows } = await db.query(
      `SELECT count(*)::int AS n
         FROM messages msg
         LEFT JOIN message_reads r
           ON r.channel_id = msg.channel_id AND r.user_id = $3
        WHERE msg.society_id = $1 AND msg.channel_id = $2
          AND msg.deleted_at IS NULL
          AND msg.created_at > COALESCE(r.last_read_at, 'epoch')`,
      [societyId, channelId, userId]
    );
    return rows[0].n;
  },

  /** File an abuse report against a message. */
  async reportMessage(societyId: string, messageId: string, reporterId: string, reason: string) {
    const msg = await db.query(`SELECT id FROM messages WHERE id = $1 AND society_id = $2`, [messageId, societyId]);
    if (!msg.rows[0]) throw err("Message not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO moderation_reports (society_id, message_id, target_type, reporter_id, reason)
       VALUES ($1, $2, 'message', $3, $4) RETURNING *`,
      [societyId, messageId, reporterId, reason]
    );
    logger.info({ societyId, messageId, reporterId }, "Message reported");
    return rows[0];
  },

  async listReports(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM moderation_reports WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /**
   * Admin moderation. soft_delete masks the message and records the action; the
   * linked report (if any) is marked actioned. dismiss closes a report with no
   * content change.
   */
  async moderate(
    societyId: string,
    input: { messageId?: string; reportId?: string; action: "soft_delete" | "dismiss" | "warn"; actorId: string; note?: string }
  ) {
    return withTx(async (client) => {
      let messageId = input.messageId || null;

      if (input.reportId) {
        const rep = await client.query(
          `SELECT * FROM moderation_reports WHERE id = $1 AND society_id = $2 FOR UPDATE`,
          [input.reportId, societyId]
        );
        if (!rep.rows[0]) throw err("Report not found", "NOT_FOUND");
        if (!messageId) messageId = rep.rows[0].message_id;
        await client.query(
          `UPDATE moderation_reports SET status = $3 WHERE id = $1 AND society_id = $2`,
          [input.reportId, societyId, input.action === "dismiss" ? "dismissed" : "actioned"]
        );
      }

      if (input.action === "soft_delete") {
        if (!messageId) throw err("messageId required to delete", "INVALID_INPUT");
        const upd = await client.query(
          `UPDATE messages SET deleted_at = now(), deleted_by = $3
             WHERE id = $1 AND society_id = $2 AND deleted_at IS NULL RETURNING *`,
          [messageId, societyId, input.actorId]
        );
        if (!upd.rows[0]) throw err("Message not found or already removed", "NOT_FOUND");
      }

      const act = await client.query(
        `INSERT INTO moderation_actions (society_id, report_id, message_id, action, actor_id, note)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [societyId, input.reportId || null, messageId, input.action, input.actorId, input.note || null]
      );
      logger.info({ societyId, messageId, action: input.action, actorId: input.actorId }, "Moderation action taken");
      return act.rows[0];
    });
  },

  async requireChannel(societyId: string, channelId: string) {
    const { rows } = await db.query(`SELECT * FROM channels WHERE id = $1 AND society_id = $2`, [channelId, societyId]);
    if (!rows[0]) throw err("Channel not found", "NOT_FOUND");
    return rows[0];
  },
};
