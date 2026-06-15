import { Pool, PoolConfig } from "pg";
import { logger } from "../shared/Logger";

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

    // Periodic heartbeat every 60s
    setInterval(() => this.checkConnection(), 60000);
  }

  public static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  public getPool(): Pool {
    const originalQuery = this.pool.query.bind(this.pool);

    // V3.14: Observability Wrapper (Slow Query Tracking)
    this.pool.query = (async (text: any, params: any) => {
      const start = Date.now();
      try {
        const result = await originalQuery(text, params);
        const duration = Date.now() - start;

        if (duration > 500) {
          logger.warn({ 
            duration, 
            query: typeof text === 'string' ? text.substring(0, 200) : 'complex_query'
          }, "⚠️ Slow Database Query Detected");
        }

        return result;
      } catch (err) {
        throw err;
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
