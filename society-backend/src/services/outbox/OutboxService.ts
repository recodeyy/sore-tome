import type { PoolClient } from "pg";
import { withTx } from "../finance/ledger";

/**
 * Transactional OUTBOX. Domain events are enqueued via `emit` using the SAME
 * transaction client that mutates business state, so an event is persisted iff
 * its state change commits (no dual-write race). A publisher loop drains rows
 * via `fetchUnpublished`, which atomically claims and marks them published using
 * FOR UPDATE SKIP LOCKED so multiple workers don't double-publish.
 *
 * All rows are tenant-scoped by society_id.
 */
export const OutboxService = {
  /**
   * Enqueue an event on the caller's transaction client. Commits atomically with
   * the surrounding business write.
   */
  async emit(
    client: PoolClient,
    args: { societyId: string; topic: string; type: string; payload?: Record<string, unknown> }
  ) {
    const { rows } = await client.query(
      `INSERT INTO outbox_events (society_id, topic, type, payload)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [args.societyId, args.topic, args.type, JSON.stringify(args.payload || {})]
    );
    return rows[0];
  },

  /**
   * Claim up to `limit` unpublished events oldest-first, mark them published, and
   * return them. Uses FOR UPDATE SKIP LOCKED inside a single transaction so
   * concurrent publishers each take a disjoint batch.
   */
  async fetchUnpublished(limit = 100) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT id FROM outbox_events
          WHERE published = false
          ORDER BY created_at ASC
          LIMIT $1
          FOR UPDATE SKIP LOCKED`,
        [limit]
      );
      if (rows.length === 0) return [];
      const ids = rows.map((r) => r.id);
      const upd = await client.query(
        `UPDATE outbox_events
            SET published = true, published_at = now()
          WHERE id = ANY($1::uuid[])
          RETURNING *`,
        [ids]
      );
      return upd.rows;
    });
  },
};
