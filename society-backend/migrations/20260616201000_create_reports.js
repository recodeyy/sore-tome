/**
 * Phase 6 — Reports module (capability 91): report templates, generation jobs,
 * and scheduled reports. Tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("report_templates", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.enu("kind", ["finance", "complaints", "staff", "occupancy", "custom"]).notNullable().defaultTo("custom");
    t.enu("format", ["pdf", "excel", "csv"]).notNullable().defaultTo("pdf");
    t.jsonb("config").notNullable().defaultTo("{}");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
  });

  await knex.schema.createTable("report_jobs", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("template_id").references("id").inTable("report_templates").onDelete("SET NULL");
    t.enu("kind", ["finance", "complaints", "staff", "occupancy", "custom"]).notNullable().defaultTo("custom");
    t.enu("status", ["queued", "running", "completed", "failed"]).notNullable().defaultTo("queued");
    t.jsonb("params").notNullable().defaultTo("{}");
    t.text("file_url");
    t.text("error");
    t.text("requested_by");
    t.timestamp("scheduled_for").nullable();
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("report_schedules", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("template_id").notNullable().references("id").inTable("report_templates").onDelete("CASCADE");
    t.text("cron").notNullable();
    t.timestamp("next_run_at");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "next_run_at"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("report_schedules");
  await knex.schema.dropTableIfExists("report_jobs");
  await knex.schema.dropTableIfExists("report_templates");
};
