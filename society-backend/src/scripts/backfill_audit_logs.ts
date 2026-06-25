import { db } from "../shared/Database.js";
import { logger } from "../shared/Logger.js";
import crypto from "crypto";

async function backfill() {
  const BATCH_START_SIZE = 500;
  const BATCH_MAX_SIZE = 1000;
  const DELAY_MS = 100;

  let currentBatchSize = BATCH_START_SIZE;
  let offset = 0;
  let totalMigrated = 0;

  logger.info("Starting Adaptive Backfill: ai_audit_logs -> ai_audit_logs_partitioned");

  while (true) {
    try {
      // 1. Fetch Batch
      const res = await db.query(
        `SELECT * FROM ai_audit_logs ORDER BY created_at ASC LIMIT $1 OFFSET $2`,
        [currentBatchSize, offset]
      );

      if (res.rows.length === 0) break;

      // 2. Insert Batch (Using UUID V4 if missing)
      for (const row of res.rows) {
        try {
          // Check if already exists to ensure idempotency
          const check = await db.query(
            `SELECT id FROM ai_audit_logs_partitioned WHERE action_id = $1`,
            [row.action_id]
          );

          if (check.rows.length === 0) {
            await db.query(`
              INSERT INTO ai_audit_logs_partitioned 
              (id, action_id, tool_id, user_id, society_id, action, params, status, error_message, created_at, expires_at)
              VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            `, [
              crypto.randomUUID(), row.action_id, row.tool_id, row.user_id, row.society_id, 
              row.action, row.params, row.status, row.error_message, row.created_at, row.expires_at
            ]);
            totalMigrated++;
          }
        } catch (err: any) {
          logger.error({ action_id: row.action_id, error: err.message }, "Row migration failed");
        }
      }

      logger.info({ offset, batchSize: currentBatchSize, totalMigrated }, "Batch Migrated");

      // 3. Adaptive Scaling (Simplistic)
      if (currentBatchSize < BATCH_MAX_SIZE) currentBatchSize += 50;
      
      offset += res.rows.length;
      await new Promise(resolve => setTimeout(resolve, DELAY_MS));

    } catch (err: any) {
      logger.fatal({ error: err.message }, "Backfill Batch Failed - Scaling Down");
      currentBatchSize = BATCH_START_SIZE; // Reset on failure
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }

  // 4. Final Checkpoint
  const legacyCount = await db.query("SELECT COUNT(*) FROM ai_audit_logs");
  const newCount = await db.query("SELECT COUNT(*) FROM ai_audit_logs_partitioned");

  logger.info({ 
    legacy: legacyCount.rows[0].count, 
    partitioned: newCount.rows[0].count 
  }, "Backfill Complete - Verification Checkpoint");

  if (legacyCount.rows[0].count === newCount.rows[0].count) {
    logger.info("VERIFICATION SUCCESS: Data parity achieved.");
  } else {
    logger.warn("VERIFICATION WARNING: Data parity mismatch. Manual audit required.");
  }
}

backfill().catch(err => logger.error({ error: err.message }, "Critical Backfill Failure"));
