require("dotenv").config();

/**
 * @type { Object.<string, import("knex").Knex.Config> }
 */
module.exports = {
  development: {
    client: "postgresql",
    connection: process.env.DATABASE_URL,
    pool: {
      min: 2,
      max: Number(process.env.DB_POOL_MAX) || 20,
      acquireTimeoutMillis: 30000
    },
    migrations: {
      tableName: "knex_migrations",
      disableMigrationsListValidation: true
    }
  },
  production: {
    client: "postgresql",
    connection: {
      connectionString: process.env.DATABASE_URL,
      // Verify the server cert unless explicitly disabled for a managed provider.
      ssl: process.env.DB_SSL_REJECT_UNAUTHORIZED === "false"
        ? { rejectUnauthorized: false }
        : true
    },
    pool: {
      min: 2,
      max: Number(process.env.DB_POOL_MAX) || 20,
      acquireTimeoutMillis: 30000
    },
    migrations: {
      tableName: "knex_migrations",
      disableMigrationsListValidation: true
    }
  }

};
