/**
 * Polls & voting. Tenant-scoped by society_id; times are UTC timestamps.
 *
 * Vote integrity: a generated-in-app `vote_key` (unit_id when vote_scope='unit',
 * else voter_id) plus a UNIQUE(poll_id, vote_key) constraint enforces exactly one
 * eligible vote per user OR per unit, atomically at the DB layer.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("polls", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("title").notNullable();
    t.text("description");
    t.enu("status", ["draft", "open", "closed"]).notNullable().defaultTo("draft");
    t.boolean("is_anonymous").notNullable().defaultTo(false);
    t.enu("vote_scope", ["user", "unit"]).notNullable().defaultTo("user");
    t.enu("results_visibility", ["always", "after_close", "admins_only"]).notNullable().defaultTo("after_close");
    t.timestamp("starts_at");
    t.timestamp("ends_at");
    t.text("created_by");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("poll_options", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("poll_id").notNullable().references("id").inTable("polls").onDelete("CASCADE");
    t.text("label").notNullable();
    t.integer("position").notNullable().defaultTo(0);
    t.index(["society_id", "poll_id"]);
  });

  await knex.schema.createTable("poll_eligibility", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("poll_id").notNullable().references("id").inTable("polls").onDelete("CASCADE");
    t.enu("audience_type", ["all", "role", "wing", "block", "unit"]).notNullable();
    t.text("audience_value");
    t.index(["society_id", "poll_id"]);
  });

  await knex.schema.createTable("votes", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("poll_id").notNullable().references("id").inTable("polls").onDelete("CASCADE");
    t.uuid("option_id").notNullable().references("id").inTable("poll_options");
    t.text("voter_id").notNullable();
    t.text("unit_id");
    // vote_key is computed in the app layer = (scope==='unit' ? unit_id : voter_id).
    t.text("vote_key").notNullable();
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    // CRITICAL: one vote per poll per voter (or per unit) — atomic at DB layer.
    t.unique(["poll_id", "vote_key"]);
    t.index(["society_id", "poll_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("votes");
  await knex.schema.dropTableIfExists("poll_eligibility");
  await knex.schema.dropTableIfExists("poll_options");
  await knex.schema.dropTableIfExists("polls");
};
