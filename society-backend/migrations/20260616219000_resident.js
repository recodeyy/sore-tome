/**
 * Resident module — visitor pre-approvals raised by residents from the member app.
 * Tenant-scoped (society_id) and unit-scoped (unit_id). A resident may only see
 * the visitor requests for their own unit; this is enforced in ResidentService.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("resident_visitors", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("unit_id");
    t.uuid("member_id").references("id").inTable("members").onDelete("SET NULL");
    t.text("created_by");
    t.text("visitor_name").notNullable();
    t.text("visitor_phone");
    t.text("purpose");
    t.enu("status", ["pending", "approved", "completed", "denied", "expired"])
      .notNullable()
      .defaultTo("approved");
    t.timestamp("expected_at");
    t.timestamp("expires_at");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "unit_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("resident_visitors");
};
