/**
 * Society events with RSVP, capacity & waitlist. Tenant-scoped by society_id.
 * All timestamps are stored in UTC. Capacity null = unlimited.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("events", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("title").notNullable();
    t.text("description");
    t.text("location");
    t.timestamp("starts_at").notNullable();
    t.timestamp("ends_at");
    t.integer("capacity"); // null = unlimited
    t.enu("status", ["draft", "published", "cancelled", "completed"]).notNullable().defaultTo("draft");
    t.text("created_by");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("event_rsvps", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("event_id").notNullable().references("id").inTable("events").onDelete("CASCADE");
    t.text("user_id").notNullable();
    t.enu("status", ["going", "waitlist", "cancelled"]).notNullable().defaultTo("going");
    t.integer("guests").notNullable().defaultTo(0);
    t.boolean("attended").notNullable().defaultTo(false);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["event_id", "user_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("event_rsvps");
  await knex.schema.dropTableIfExists("events");
};
