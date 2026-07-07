/**
 * Phase 5 — Parking (capabilities 86–88): slot inventory, vehicle registry,
 * allocations (one active per slot), requests, visitor parking, violations/fines.
 * Tenant-scoped by society_id. Money in integer minor units.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("parking_slots", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("code").notNullable(); // e.g. B1-12
    t.enu("type", ["car", "bike", "ev", "visitor", "accessible"]).notNullable().defaultTo("car");
    t.text("location");
    t.boolean("is_ev").notNullable().defaultTo(false);
    t.boolean("is_accessible").notNullable().defaultTo(false);
    t.boolean("is_reserved").notNullable().defaultTo(false);
    t.enu("status", ["available", "allocated", "maintenance"]).notNullable().defaultTo("available");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "code"]);
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("vehicles", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("plate").notNullable();
    t.enu("type", ["car", "bike", "ev", "other"]).notNullable().defaultTo("car");
    t.text("unit_id");
    t.text("owner_id");
    t.text("make_model");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    // A plate is unique within a society (cannot register the same vehicle twice).
    t.unique(["society_id", "plate"]);
    t.index(["society_id", "unit_id"]);
  });

  await knex.schema.createTable("parking_allocations", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("slot_id").notNullable().references("id").inTable("parking_slots").onDelete("CASCADE");
    t.uuid("vehicle_id").references("id").inTable("vehicles");
    t.text("unit_id");
    t.text("allocated_to"); // resident/user id
    t.enu("status", ["active", "released"]).notNullable().defaultTo("active");
    t.timestamp("allocated_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("released_at");
    t.text("allocated_by");
    t.index(["society_id", "slot_id"]);
  });
  // At most ONE active allocation per slot — partial unique index prevents double allocation.
  await knex.raw(
    `CREATE UNIQUE INDEX parking_alloc_one_active ON parking_allocations (slot_id) WHERE status = 'active'`
  );

  await knex.schema.createTable("parking_requests", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("requested_by").notNullable();
    t.text("unit_id");
    t.enu("vehicle_type", ["car", "bike", "ev"]).notNullable().defaultTo("car");
    t.enu("status", ["waiting", "allocated", "rejected", "cancelled"]).notNullable().defaultTo("waiting");
    t.uuid("allocation_id").references("id").inTable("parking_allocations");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("visitor_parking", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("slot_id").references("id").inTable("parking_slots");
    t.text("plate").notNullable();
    t.text("visiting_unit_id");
    t.timestamp("valid_from").notNullable().defaultTo(knex.fn.now());
    t.timestamp("valid_until").notNullable();
    t.enu("status", ["active", "expired", "checked_out"]).notNullable().defaultTo("active");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("parking_violations", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("slot_id").references("id").inTable("parking_slots");
    t.text("plate");
    t.text("description").notNullable();
    t.text("evidence_url");
    t.bigInteger("fine_minor").notNullable().defaultTo(0);
    t.enu("status", ["open", "waived", "paid", "disputed"]).notNullable().defaultTo("open");
    t.text("reported_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("parking_violations");
  await knex.schema.dropTableIfExists("visitor_parking");
  await knex.schema.dropTableIfExists("parking_requests");
  await knex.raw(`DROP INDEX IF EXISTS parking_alloc_one_active`);
  await knex.schema.dropTableIfExists("parking_allocations");
  await knex.schema.dropTableIfExists("vehicles");
  await knex.schema.dropTableIfExists("parking_slots");
};
