const cron = require("node-cron");
const { getDb, getAdmin } = require("../../../config/firebase");
const { logger } = require("../../shared/Logger");

class FinanceReportCronJob {
  static init() {
    // Run at 00:01 on the 1st day of every month
    // Syntax: 'minute hour dayOfMonth month dayOfWeek'
    cron.schedule("1 0 1 * *", async () => {
      logger.info("Starting monthly Auto-Generated Financial Reports CRON...");
      await this.generateMonthlyReports();
    }, {
      timezone: "Asia/Kolkata"
    });
  }

  static async generateMonthlyReports() {
    try {
      const db = getDb();
      const now = new Date();
      // Calculate previous month
      const startOfPrevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      const endOfPrevMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
      
      const monthName = startOfPrevMonth.toLocaleString('default', { month: 'long' });
      const year = startOfPrevMonth.getFullYear();

      // Get all unique societies
      const societiesSnap = await db.collection("transactions").select("society_id").get();
      const societyIds = [...new Set(societiesSnap.docs.map(doc => doc.data().society_id))];

      for (const societyId of societyIds) {
        if (!societyId) continue;
        
        // 1. Fetch transactions for the previous month
        const txSnap = await db.collection("transactions")
          .where("society_id", "==", societyId)
          .where("createdAt", ">=", getAdmin().firestore.Timestamp.fromDate(startOfPrevMonth))
          .where("createdAt", "<=", getAdmin().firestore.Timestamp.fromDate(endOfPrevMonth))
          .get();

        if (txSnap.empty) continue; // No transactions, skip report

        let totalIncome = 0;
        let totalExpense = 0;

        txSnap.docs.forEach(doc => {
          const data = doc.data();
          if (data.type === "credit") totalIncome += data.amount;
          if (data.type === "debit") totalExpense += data.amount;
        });

        const reportBody = `Dear Residents,\n\nHere is the financial summary for ${monthName} ${year}:\n\n` +
          `• Total Income Collected: ₹${totalIncome.toLocaleString()}\n` +
          `• Total Expenses: ₹${totalExpense.toLocaleString()}\n` +
          `• Net Balance for Month: ₹${(totalIncome - totalExpense).toLocaleString()}\n\n` +
          `Detailed ledger is available in the Treasury section.`;

        // 2. Automatically post a Notice
        await db.collection("notices").add({
          title: `Financial Report: ${monthName} ${year}`,
          body: reportBody,
          type: "general",
          society_id: societyId,
          postedBy: "system",
          postedByName: "Auto-Generated Report",
          createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
        });

        logger.info(`Generated report for society ${societyId}: Income=${totalIncome}, Expense=${totalExpense}`);
      }
    } catch (err) {
      logger.error({ error: err.message }, "CRON ERROR: generateMonthlyReports failed");
    }
  }
}

module.exports = { FinanceReportCronJob };
