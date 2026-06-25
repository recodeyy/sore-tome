/**
 * Admin Society Setup (capabilities 9, 10, 21, 22): society profile, logo/branding,
 * society settings, and onboarding checklist. Tenant-scoped by society_id (one row
 * per society for profile/settings/logo). Logo keeps version history.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("society_profiles", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable().unique();
    t.text("name");
    t.text("registration_no");
    t.text("address");
    t.text("timezone").notNullable().defaultTo("Asia/Kolkata");
    t.text("currency").notNullable().defaultTo("INR");
    t.text("financial_year_start").defaultTo("04-01"); // MM-DD
    t.jsonb("contacts").notNullable().defaultTo("[]");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.integer("version").notNullable().defaultTo(0);
  });

  await knex.schema.createTable("society_settings", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable().unique();
    t.jsonb("numbering").notNullable().defaultTo("{}");
    t.jsonb("billing_defaults").notNullable().defaultTo("{}");
    t.jsonb("notification_prefs").notNullable().defaultTo("{}");
    t.jsonb("booking_policy").notNullable().defaultTo("{}");
    t.jsonb("feature_flags").notNullable().defaultTo("{}");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.integer("version").notNullable().defaultTo(0);
  });

  await knex.schema.createTable("society_logos", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("file_url").notNullable();
    t.integer("version").notNullable().defaultTo(1);
    t.boolean("is_current").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("deleted_at");
    t.index(["society_id", "is_current"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("society_logos");
  await knex.schema.dropTableIfExists("society_settings");
  await knex.schema.dropTableIfExists("society_profiles");
};
