/**
 * Per-admin dashboard preferences (capability 8): configurable widgets and
 * saved filters. One row per (society_id, user_id); upserted. Tenant-scoped.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("dashboard_preferences", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("user_id").notNullable();
    t.jsonb("widgets").notNullable().defaultTo(knex.raw("'[]'::jsonb"));
    t.jsonb("saved_filters").notNullable().defaultTo(knex.raw("'[]'::jsonb"));
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "user_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("dashboard_preferences");
};
