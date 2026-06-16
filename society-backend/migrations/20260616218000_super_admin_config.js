/**
 * Super Admin platform configuration (pack group D, caps 20-23).
 *  - cap 20 feature_rollouts: cohort + percentage gated rollouts.
 *  - cap 21 white_label_profiles: per-society branding with version bump + publish.
 *  - cap 22 api_clients: API keys (sha256 hash only) with scopes + quota.
 *  - cap 23 webhook_endpoints + integration_connections: outbound integrations,
 *    secrets stored hashed, integration config holds non-secret values only.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  if (!(await knex.schema.hasTable("feature_rollouts"))) {
    await knex.schema.createTable("feature_rollouts", (t) => {
      t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
      t.text("feature_key").notNullable().unique();
      t.jsonb("cohort").notNullable().defaultTo(knex.raw("'{}'::jsonb"));
      t.integer("percentage").notNullable().defaultTo(0);
      t.text("status").notNullable().defaultTo("draft");
      t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
      t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    });
  }

  if (!(await knex.schema.hasTable("white_label_profiles"))) {
    await knex.schema.createTable("white_label_profiles", (t) => {
      t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
      t.text("society_id").notNullable().unique();
      t.text("brand_name");
      t.jsonb("colors").notNullable().defaultTo(knex.raw("'{}'::jsonb"));
      t.text("logo_url");
      t.integer("version").notNullable().defaultTo(1);
      t.text("status").notNullable().defaultTo("draft");
      t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
      t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    });
  }

  if (!(await knex.schema.hasTable("api_clients"))) {
    await knex.schema.createTable("api_clients", (t) => {
      t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
      t.text("society_id").notNullable();
      t.text("name").notNullable();
      t.text("key_hash").notNullable();
      t.jsonb("scopes").notNullable().defaultTo(knex.raw("'[]'::jsonb"));
      t.integer("quota_per_day").notNullable().defaultTo(10000);
      t.boolean("is_active").notNullable().defaultTo(true);
      t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
      t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
      t.index(["society_id"]);
    });
  }

  if (!(await knex.schema.hasTable("webhook_endpoints"))) {
    await knex.schema.createTable("webhook_endpoints", (t) => {
      t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
      t.text("society_id").notNullable();
      t.text("url").notNullable();
      t.jsonb("events").notNullable().defaultTo(knex.raw("'[]'::jsonb"));
      t.text("secret_hash").notNullable();
      t.boolean("is_active").notNullable().defaultTo(true);
      t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
      t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
      t.index(["society_id"]);
    });
  }

  if (!(await knex.schema.hasTable("integration_connections"))) {
    await knex.schema.createTable("integration_connections", (t) => {
      t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
      t.text("society_id").notNullable();
      t.text("provider").notNullable();
      t.jsonb("config").notNullable().defaultTo(knex.raw("'{}'::jsonb"));
      t.text("status").notNullable().defaultTo("connected");
      t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
      t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
      t.unique(["society_id", "provider"]);
    });
  }
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("integration_connections");
  await knex.schema.dropTableIfExists("webhook_endpoints");
  await knex.schema.dropTableIfExists("api_clients");
  await knex.schema.dropTableIfExists("white_label_profiles");
  await knex.schema.dropTableIfExists("feature_rollouts");
};
