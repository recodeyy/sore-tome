// Polls the outbox_events table and republishes unpublished rows onto the
// in-process EventBus, which the SSE gateway fans out to connected clients.

import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { eventBus } from "./EventBus";

const POLL_INTERVAL_MS = 1000;
const BATCH_SIZE = 100;

let timer: NodeJS.Timeout | null = null;

async function tick(): Promise<void> {
  try {
    const { rows } = await db.query(
      `SELECT id, topic, type, payload
         FROM outbox_events
        WHERE published = false
        ORDER BY created_at
        LIMIT $1`,
      [BATCH_SIZE]
    );

    if (rows.length === 0) return;

    const ids = rows.map((r: any) => r.id);
    await db.query(
      `UPDATE outbox_events SET published = true WHERE id = ANY($1::int[])`,
      [ids]
    );

    for (const row of rows) {
      eventBus.publish(row.topic, {
        type: row.type,
        payload: row.payload,
        id: row.id,
      });
    }

    logger.debug({ count: rows.length }, "Outbox events published");
  } catch (err: any) {
    // Guard: outbox_events may not exist yet — no-op rather than crash the loop.
    logger.warn({ error: err.message }, "Outbox publisher tick failed");
  }
}

export function startOutboxPublisher(): void {
  if (timer) return;
  timer = setInterval(() => {
    void tick();
  }, POLL_INTERVAL_MS);
  timer.unref();
  logger.info("Outbox publisher started");
}

export function stopOutboxPublisher(): void {
  if (timer) {
    clearInterval(timer);
    timer = null;
    logger.info("Outbox publisher stopped");
  }
}
