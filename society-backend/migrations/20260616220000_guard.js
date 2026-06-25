/**
 * Guard / Security module — lean, tenant-scoped (society_id) tables.
 *  - visitor_entries: gate visitor lifecycle (expected -> checked_in -> checked_out / denied).
 *  - gate_passes: short-lived passes (visitor/delivery/cab/service), code unique per society.
 *  - patrol_logs: checkpoint patrol records.
 *  - security_incidents: incident reports raised by guards.
 * Times UTC. No cross-tenant FKs; every query filters by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("visitor_entries", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.text("phone");
    t.text("purpose");
    t.text("unit_id");
    t.enu("status", ["expected", "checked_in", "checked_out", "denied"]).notNullable().defaultTo("expected");
    t.uuid("pre_approval_id");
    t.timestamp("checked_in_at");
    t.timestamp("checked_out_at");
    t.text("guard_id");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("gate_passes", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.enu("type", ["visitor", "delivery", "cab", "service"]).notNullable();
    t.text("code").notNullable();
    t.timestamp("valid_until").notNullable();
    t.enu("status", ["active", "used", "expired", "revoked"]).notNullable().defaultTo("active");
    t.text("guard_id");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "code"]);
  });

  await knex.schema.createTable("patrol_logs", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("guard_id");
    t.text("checkpoint").notNullable();
    t.text("note");
    t.timestamp("logged_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "logged_at"]);
  });

  await knex.schema.createTable("security_incidents", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("guard_id");
    t.text("category").notNullable();
    t.text("description");
    t.enu("severity", ["low", "medium", "high", "critical"]).notNullable().defaultTo("low");
    t.enu("status", ["open", "investigating", "resolved", "closed"]).notNullable().defaultTo("open");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("security_incidents");
  await knex.schema.dropTableIfExists("patrol_logs");
  await knex.schema.dropTableIfExists("gate_passes");
  await knex.schema.dropTableIfExists("visitor_entries");
};
