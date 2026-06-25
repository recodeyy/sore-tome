const cron = require('node-cron');
const { getDb, getAdmin } = require('../../../config/firebase');
const { logger } = require('../../shared/Logger');

class VisitorCronJob {
  static init() {
    // Run every day at 23:59 (11:59 PM) Server Time
    cron.schedule('59 23 * * *', async () => {
      logger.info('Running Auto-Checkout Cron Job for Visitors...');
      await this.runAutoCheckout();
    });
  }

  static async runAutoCheckout() {
    try {
      const db = getDb();

      // ✅ BUG-05 FIX: Scope by society — fetch all distinct society IDs first
      // This prevents cross-tenant auto-checkout and allows per-society timezone handling
      const societiesSnap = await db.collection('visitors')
        .where('status', 'in', ['pending', 'approved'])
        .get();

      if (societiesSnap.empty) {
        logger.info('Auto-Checkout: No active visitors found.');
        return { checkedOutCount: 0 };
      }

      // Group visitor docs by society_id
      const bySociety = new Map();
      societiesSnap.docs.forEach((doc) => {
        const sid = doc.data().society_id;
        if (!bySociety.has(sid)) bySociety.set(sid, []);
        bySociety.get(sid).push(doc);
      });

      let totalCount = 0;

      for (const [societyId, docs] of bySociety) {
        logger.info({ societyId }, `Auto-Checkout: Processing ${docs.length} visitors`);

        // ✅ BUG-04 FIX: Use for...of with proper await so each batch is committed
        // before the next one is created — no fire-and-forget race conditions
        let batch = db.batch();
        let batchCount = 0;

        for (const doc of docs) {
          batch.update(doc.ref, {
            status: 'checked_out',
            autoCheckoutReason: 'system_auto_checkout',
            exitTime: getAdmin().firestore.FieldValue.serverTimestamp(),
            updatedBy: 'system',
          });
          batchCount++;
          totalCount++;

          // Firestore batch limit is 500 operations — commit and reset at 450
          if (batchCount % 450 === 0) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }

        // Commit the remaining batch for this society
        if (batchCount > 0) {
          await batch.commit();
        }

        logger.info({ societyId, count: docs.length }, 'Auto-Checkout: Society processed');
      }

      logger.info(`Auto-Checkout Complete. Checked out ${totalCount} visitors across ${bySociety.size} societies.`);
      return { checkedOutCount: totalCount };

    } catch (error) {
      logger.error({ error: error.message }, 'Auto-Checkout Cron Job Failed');
      throw error;
    }
  }
}

module.exports = { VisitorCronJob };

