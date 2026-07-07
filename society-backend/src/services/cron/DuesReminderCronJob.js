const cron = require("node-cron");
const { logger } = require("../../shared/Logger");

/**
 * §13 — Daily dues reminder job. Delegates to
 * FinanceService.runDuesRemindersAll(), which finds published invoices past
 * their due date with an outstanding balance in every society and pushes a
 * "dues reminder" billing notification (deeplink /resident/payments) — at most
 * once per invoice per day (invoices.last_reminded_at guard).
 *
 * Also invocable on demand via POST /api/v1/finance/reminders/run (admin).
 * Uses node-cron to match the existing cron infra (VisitorCronJob,
 * FinanceReportCronJob); the BullMQ queues in this repo are AI-pipeline
 * specific, so a repeatable BullMQ job would have needed new worker wiring.
 */
class DuesReminderCronJob {
  static init() {
    // Every day at 09:00 IST.
    cron.schedule(
      "0 9 * * *",
      async () => {
        logger.info("Starting daily dues reminder CRON...");
        try {
          const { FinanceService } = require("../finance/FinanceService");
          const result = await FinanceService.runDuesRemindersAll();
          logger.info({ societies: Object.keys(result).length }, "Dues reminder CRON completed");
        } catch (err) {
          logger.error({ error: err.message }, "CRON ERROR: dues reminders failed");
        }
      },
      { timezone: "Asia/Kolkata" }
    );
  }
}

module.exports = { DuesReminderCronJob };
