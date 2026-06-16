import { Pool, PoolConfig } from "pg";
import { logger } from "../shared/Logger";
import { requestContextStore } from "./RequestContext";

class Database {
  private static instance: Database;
  private pool: Pool;
  private isConnected: boolean = false;

  private constructor() {
    const connStr = process.env.DATABASE_URL;

    if (!connStr) {
      console.error("\n❌ CRITICAL ERROR: DATABASE_URL environment variable is missing!");
      throw new Error("Targeted Failure: Database Configuration Incomplete");
    }

    const config: PoolConfig = {
      connectionString: connStr,
      max: 10, // Hardened pool cap
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
      keepAlive: true,
      ssl: connStr.includes("localhost") ? false : { rejectUnauthorized: false },
    };


    this.pool = new Pool(config);

    this.pool.on("error", (err) => {
      logger.error({ error: err.message }, "PostgreSQL Pool Error - Global Connection Impacted");
      this.isConnected = false;
    });

    // Initial heartbeat
    this.checkConnection();

    // Periodic heartbeat every 60s. unref so it never keeps the process alive.
    setInterval(() => this.checkConnection(), 60000).unref();
  }

  public static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  public getPool(): Pool {
    // V3.14: Observability Wrapper (Slow Query Tracking) + RLS Context Injection
    this.pool.query = (async (text: any, params: any) => {
      const start = Date.now();
      const client = await this.pool.connect();
      try {
        // RLS tenant context. set_config(..., false) sets it at SESSION scope on
        // this checked-out connection, applied BEFORE the wrapped query runs.
        const context = requestContextStore.getStore();
        const societyId = context && context.societyId ? context.societyId : "";
        await client.query(`SELECT set_config('app.society_id', $1, false)`, [societyId]);

        const result = await client.query(text, params);
        const duration = Date.now() - start;

        if (duration > 500) {
          logger.warn({
            duration,
            query: typeof text === 'string' ? text.substring(0, 200) : 'complex_query'
          }, "⚠️ Slow Database Query Detected");
        }

        return result;
      } finally {
        // Reset tenant context BEFORE returning the connection to the pool so no
        // pooled client ever carries a stale society_id to its next checkout.
        try {
          await client.query(`SELECT set_config('app.society_id', '', false)`);
        } catch {
          /* ignore reset failures (e.g. aborted txn / dead conn) — release anyway */
        }
        client.release();
      }
    }) as any;

    return this.pool;
  }


  private async checkConnection() {
    try {
      await this.pool.query("SELECT 1");
      if (!this.isConnected) {
        logger.info("✅ PostgreSQL connection established (Singleton)");
        this.isConnected = true;
      }
    } catch (err: any) {
      logger.warn({ error: err.message }, "PostgreSQL Heartbeat Failed");
      this.isConnected = false;
    }
  }

  public async close() {
    await this.pool.end();
    logger.info("PostgreSQL Pool closed");
  }
}

export const db = Database.getInstance().getPool();
export const dbManager = Database.getInstance();
