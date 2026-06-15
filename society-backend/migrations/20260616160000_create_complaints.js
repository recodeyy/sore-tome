/**
 * Phase 4 — Complaints + SLA engine (capabilities 59–69).
 * Every row is tenant-scoped by society_id. Time stored UTC; SLA math uses the
 * society timezone snapshotted on the complaint. Status changes are auditable
 * via complaint_status_history; SLA pause/resume captured in complaint_sla_events.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  // Categories + their default SLA target (in business minutes) and priority.
  await knex.schema.createTable("complaint_categories", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.text("department");
    t.enu("default_priority", ["low", "medium", "high", "critical"]).notNullable().defaultTo("medium");
    t.integer("sla_minutes").notNullable().defaultTo(1440); // business minutes to resolve
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
  });

  // Society SLA/business-calendar policy. One active policy per society is typical.
  await knex.schema.createTable("sla_policies", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable().defaultTo("Default");
    t.integer("tz_offset_minutes").notNullable().defaultTo(330); // IST
    t.specificType("workdays", "int[]").notNullable().defaultTo(knex.raw("'{1,2,3,4,5,6}'")); // Mon–Sat
    t.integer("day_start_minutes").notNullable().defaultTo(540); // 09:00
    t.integer("day_end_minutes").notNullable().defaultTo(1080); // 18:00
    t.specificType("holidays", "text[]").notNullable().defaultTo(knex.raw("'{}'"));
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "is_active"]);
  });

  // Complaints. SLA policy is snapshotted (denormalized) at creation so later
  // policy edits never retroactively change an open complaint's due time.
  await knex.schema.createTable("complaints", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("ref").notNullable(); // human-facing reference, unique per society
    t.text("title").notNullable();
    t.text("description").notNullable();
    t.uuid("category_id").references("id").inTable("complaint_categories");
    t.text("unit_id");
    t.text("location");
    t.enu("priority", ["low", "medium", "high", "critical"]).notNullable().defaultTo("medium");
    t.enu("status", ["open", "in_progress", "resolved", "closed"]).notNullable().defaultTo("open");
    t.boolean("is_private").notNullable().defaultTo(false);
    t.text("created_by");
    t.text("assigned_to"); // current assignee user/staff/vendor id
    t.integer("sla_minutes").notNullable().defaultTo(1440);
    t.jsonb("sla_config").notNullable(); // snapshot of SlaConfig used for due math
    t.timestamp("due_at"); // computed business-hours due instant (UTC)
    t.timestamp("first_response_at");
    t.timestamp("resolved_at");
    t.timestamp("closed_at");
    t.boolean("sla_breached").notNullable().defaultTo(false);
    t.integer("reopen_count").notNullable().defaultTo(0);
    t.text("resolution_note");
    t.uuid("duplicate_of").references("id").inTable("complaints"); // duplicate linking/merge
    t.integer("version").notNullable().defaultTo(0); // optimistic locking
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "ref"]);
    t.index(["society_id", "status"]);
    t.index(["society_id", "assigned_to"]);
    t.index(["society_id", "due_at"]);
  });

  // Assignment history (current assignee also denormalized on complaints.assigned_to).
  await knex.schema.createTable("complaint_assignments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.text("assignee_id").notNullable();
    t.enu("assignee_type", ["staff", "committee", "vendor"]).notNullable().defaultTo("staff");
    t.text("assigned_by");
    t.text("reason"); // rule-based / AI / manual rationale
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "complaint_id"]);
  });

  // Comments — internal notes vs resident-visible are separated by `visibility`.
  await knex.schema.createTable("complaint_comments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.enu("visibility", ["internal", "resident"]).notNullable().defaultTo("resident");
    t.text("author_id").notNullable();
    t.text("author_name");
    t.text("body").notNullable();
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "complaint_id"]);
  });

  // Status transition audit trail (explicit state machine).
  await knex.schema.createTable("complaint_status_history", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.text("from_status");
    t.text("to_status").notNullable();
    t.text("actor_id");
    t.text("note");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "complaint_id"]);
  });

  // SLA clock events — pause/resume/breach. Pauses stop the SLA timer.
  await knex.schema.createTable("complaint_sla_events", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.enu("event", ["pause", "resume", "breach", "escalate"]).notNullable();
    t.text("reason");
    t.timestamp("occurred_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "complaint_id"]);
  });

  // Closure CSAT — one row per complaint (one rating only).
  await knex.schema.createTable("complaint_feedback", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.integer("rating").notNullable(); // 1..5
    t.text("comment");
    t.text("submitted_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["complaint_id"]); // CSAT once only
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("complaint_feedback");
  await knex.schema.dropTableIfExists("complaint_sla_events");
  await knex.schema.dropTableIfExists("complaint_status_history");
  await knex.schema.dropTableIfExists("complaint_comments");
  await knex.schema.dropTableIfExists("complaint_assignments");
  await knex.schema.dropTableIfExists("complaints");
  await knex.schema.dropTableIfExists("sla_policies");
  await knex.schema.dropTableIfExists("complaint_categories");
};
