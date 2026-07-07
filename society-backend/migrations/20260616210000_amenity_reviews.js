/**
 * Amenities cap 85: reviews (calendar/revenue/utilization analytics are query-only).
 * Additive: a per-booking review table (rating 1-5 + comment), tenant-scoped.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("amenity_reviews", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("amenity_id").notNullable().references("id").inTable("amenities").onDelete("CASCADE");
    t.uuid("booking_id").references("id").inTable("amenity_bookings").onDelete("SET NULL");
    t.text("member_id");
    t.integer("rating").notNullable();
    t.text("comment");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "amenity_id"]);
  });
  await knex.raw(`ALTER TABLE amenity_reviews ADD CONSTRAINT amenity_reviews_rating_chk CHECK (rating BETWEEN 1 AND 5)`);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("amenity_reviews");
};
