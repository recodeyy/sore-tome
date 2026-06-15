/**
 * Amenities enhancement (Phase 5, capabilities 80–85).
 * Additive: adds eligibility/pricing/operating-hours columns to amenities and
 * blackout + payment tables. Money is in integer minor units.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.alterTable("amenities", (t) => {
    t.integer("open_minutes").defaultTo(360);
    t.integer("close_minutes").defaultTo(1320);
    t.bigInteger("price_minor").defaultTo(0);
    t.bigInteger("deposit_minor").defaultTo(0);
    t.boolean("requires_approval").defaultTo(false);
    t.integer("max_per_member");
  });

  await knex.schema.createTable("amenity_blackouts", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("amenity_id").notNullable().references("id").inTable("amenities").onDelete("CASCADE");
    t.timestamp("from_at").notNullable();
    t.timestamp("to_at").notNullable();
    t.text("reason");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "amenity_id"]);
  });

  await knex.schema.createTable("booking_payments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("booking_id").notNullable().references("id").inTable("amenity_bookings").onDelete("CASCADE");
    t.bigInteger("amount_minor").defaultTo(0);
    t.bigInteger("deposit_minor").defaultTo(0);
    t.enu("status", ["pending", "paid", "refunded"]).notNullable().defaultTo("pending");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "booking_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("booking_payments");
  await knex.schema.dropTableIfExists("amenity_blackouts");
  await knex.schema.alterTable("amenities", (t) => {
    t.dropColumn("open_minutes");
    t.dropColumn("close_minutes");
    t.dropColumn("price_minor");
    t.dropColumn("deposit_minor");
    t.dropColumn("requires_approval");
    t.dropColumn("max_per_member");
  });
};
