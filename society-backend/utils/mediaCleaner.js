const { getDb } = require("../config/firebase");

/**
 * Periodically fails stuck "uploading" messages older than 10 mins
 */
function startMediaCleaner() {
  setInterval(async () => {
    try {
      const db = getDb();
      const tenMinsAgo = new Date(Date.now() - 10 * 60 * 1000);
      
      // Auto-Index Optimized: Firestore automatically indexes single fields like 'status'
      // By looping through channels and filtering 'createdAt' in-memory, we skip 
      // the need for manual composite index configuration.
      const channels = await db.collection("channels").get();
      
      for (const chan of channels.docs) {
        const stuckMsgs = await chan.ref.collection("messages")
          .where("status", "==", "uploading")
          .limit(20)
          .get();

        if (stuckMsgs.size > 0) {
          const batch = db.batch();
          let count = 0;
          
          stuckMsgs.forEach(doc => {
            const data = doc.data();
            const createdAt = data.createdAt?.toDate?.() || new Date(data.createdAt);
            
            if (createdAt < tenMinsAgo) {
              batch.update(doc.ref, { 
                status: "failed",
                error: "Upload timed out" 
              });
              count++;
            }
          });

          if (count > 0) {
            await batch.commit();
            console.log(`[BACKEND] Cleaned ${count} stuck uploads in channel ${chan.id}`);
          }
        }
      }
    } catch (err) {
      console.error("[BACKEND] Media Cleaner Error:", err);
    }
  }, 5 * 60 * 1000); // Run every 5 minutes
}

module.exports = { startMediaCleaner };
