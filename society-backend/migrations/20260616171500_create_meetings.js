/**
 * Meetings & Governance (AGM / committee / general). Tenant-scoped by society_id.
 * Covers calendar (scheduled_at), agenda, attendance, proxies, quorum,
 * resolutions + voting outcome, minutes, and action items with owners/deadlines.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("meetings", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("title").notNullable();
    t.enu("type", ["agm", "committee", "general"]).notNullable().defaultTo("committee");
    t.timestamp("scheduled_at");
    t.text("location");
    t.enu("status", ["scheduled", "in_progress", "completed", "cancelled"]).notNullable().defaultTo("scheduled");
    t.integer("quorum_required").notNullable().defaultTo(0);
    t.text("created_by");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("meeting_agenda_items", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("meeting_id").notNullable().references("id").inTable("meetings").onDelete("CASCADE");
    t.integer("position").notNullable().defaultTo(0);
    t.text("title").notNullable();
    t.text("description");
  });

  await knex.schema.createTable("meeting_attendance", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("meeting_id").notNullable().references("id").inTable("meetings").onDelete("CASCADE");
    t.text("user_id").notNullable();
    t.boolean("present").notNullable().defaultTo(false);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["meeting_id", "user_id"]);
  });

  await knex.schema.createTable("proxies", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("meeting_id").notNullable().references("id").inTable("meetings").onDelete("CASCADE");
    t.text("grantor_id").notNullable();
    t.text("proxy_holder_id").notNullable();
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["meeting_id", "grantor_id"]);
  });

  await knex.schema.createTable("resolutions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("meeting_id").notNullable().references("id").inTable("meetings").onDelete("CASCADE");
    t.text("title").notNullable();
    t.text("text");
    t.enu("outcome", ["pending", "passed", "failed"]).notNullable().defaultTo("pending");
    t.integer("votes_for").notNullable().defaultTo(0);
    t.integer("votes_against").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable("minutes", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("meeting_id").notNullable().references("id").inTable("meetings").onDelete("CASCADE");
    t.text("body").notNullable();
    t.text("recorded_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable("action_items", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("meeting_id").notNullable().references("id").inTable("meetings").onDelete("CASCADE");
    t.text("description").notNullable();
    t.text("owner_id");
    t.date("due_date");
    t.enu("status", ["open", "in_progress", "done"]).notNullable().defaultTo("open");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("action_items");
  await knex.schema.dropTableIfExists("minutes");
  await knex.schema.dropTableIfExists("resolutions");
  await knex.schema.dropTableIfExists("proxies");
  await knex.schema.dropTableIfExists("meeting_attendance");
  await knex.schema.dropTableIfExists("meeting_agenda_items");
  await knex.schema.dropTableIfExists("meetings");
};
