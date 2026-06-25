/**
 * Notices module (Phase 4, capabilities 43–49).
 * Notices are tenant-scoped announcements with a draft/scheduled/published/archived
 * lifecycle, immutable version snapshots, audience targeting and per-user read
 * receipts / acknowledgements. Times are UTC timestamps.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("notices", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("title").notNullable();
    t.text("body").notNullable();
    t.enu("type", ["general", "event", "maintenance", "festival", "governance"]).notNullable().defaultTo("general");
    t.text("category");
    t.enu("priority", ["low", "medium", "high", "critical"]).notNullable().defaultTo("medium");
    t.enu("status", ["draft", "scheduled", "published", "archived"]).notNullable().defaultTo("draft");
    t.boolean("ack_required").notNullable().defaultTo(false);
    t.text("author_id");
    t.text("author_name");
    t.timestamp("scheduled_at");
    t.timestamp("published_at");
    t.timestamp("expires_at");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("deleted_at");
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("notice_versions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("notice_id").notNullable().references("id").inTable("notices").onDelete("CASCADE");
    t.integer("version").notNullable();
    t.text("title").notNullable();
    t.text("body").notNullable();
    t.text("edited_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "notice_id"]);
  });

  await knex.schema.createTable("notice_audiences", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("notice_id").notNullable().references("id").inTable("notices").onDelete("CASCADE");
    t.enu("audience_type", ["all", "role", "wing", "block", "unit", "ownership", "custom"]).notNullable();
    t.text("audience_value");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "notice_id"]);
  });

  await knex.schema.createTable("notice_reads", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("notice_id").notNullable().references("id").inTable("notices").onDelete("CASCADE");
    t.text("user_id").notNullable();
    t.timestamp("read_at").notNullable().defaultTo(knex.fn.now());
    t.boolean("acknowledged").notNullable().defaultTo(false);
    t.timestamp("acknowledged_at");
    t.unique(["notice_id", "user_id"]);
    t.index(["society_id", "notice_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("notice_reads");
  await knex.schema.dropTableIfExists("notice_audiences");
  await knex.schema.dropTableIfExists("notice_versions");
  await knex.schema.dropTableIfExists("notices");
};
