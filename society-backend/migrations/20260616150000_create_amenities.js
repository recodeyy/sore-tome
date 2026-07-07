/**
 * Amenities + bookings. Double-booking is prevented by a GiST EXCLUDE
 * constraint on overlapping time ranges for confirmed bookings — race-proof
 * at the database level, independent of application logic.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.raw(`CREATE EXTENSION IF NOT EXISTS btree_gist`);

  await knex.schema.createTable("amenities", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.integer("capacity").notNullable().defaultTo(1);
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id"]);
  });

  await knex.raw(`
    CREATE TABLE amenity_bookings (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      society_id text NOT NULL,
      amenity_id uuid NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
      member_id text,
      start_at timestamptz NOT NULL,
      end_at timestamptz NOT NULL,
      period tstzrange GENERATED ALWAYS AS (tstzrange(start_at, end_at)) STORED,
      status text NOT NULL DEFAULT 'confirmed',
      created_at timestamptz NOT NULL DEFAULT now(),
      CHECK (end_at > start_at)
    )
  `);

  // No two confirmed bookings for the same amenity may overlap in time.
  await knex.raw(`
    ALTER TABLE amenity_bookings
    ADD CONSTRAINT amenity_bookings_no_overlap
    EXCLUDE USING gist (amenity_id WITH =, period WITH &&)
    WHERE (status = 'confirmed')
  `);

  await knex.raw(`CREATE INDEX idx_amenity_bookings_lookup ON amenity_bookings (society_id, amenity_id)`);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("amenity_bookings");
  await knex.schema.dropTableIfExists("amenities");
};
