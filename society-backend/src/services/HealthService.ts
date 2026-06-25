// @ts-ignore
import { getAdmin } from "../../config/firebase.js";
import { logger } from "../shared/Logger.js";
import { firebaseBreaker } from "../shared/CircuitBreaker.js";

export class HealthService {
  public static async performDeepCheck() {
    const results: any = {};
    // ... (DB and Redis checks remain same)

    // 3. Firebase Check (Protected by Circuit Breaker)
    try {
      await firebaseBreaker.execute(async () => {
        await getAdmin().firestore().collection("_health").doc("ping").set({
          timestamp: new Date().toISOString()
        });
      });
      results.firebase = "ok";
    } catch (err: any) {
      logger.error({ error: err.message }, "HealthCheck: Firebase failed or Circuit Open");
    }


    const allHealthy = Object.values(results).every((v) => v === "ok");

    return {
      status: allHealthy ? "ok" : "partially_degraded",
      services: results,
      timestamp: new Date().toISOString()
    };
  }
}
