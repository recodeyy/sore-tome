/**
 * Mobile revamp §7.3 (Domestic help) + §8 (Parcels) — real backend modules so
 * these stop being mock-only. Tenant-scoped by society_id throughout; unit_id
 * kept as text to match the mixed uuid/text unit references used elsewhere.
 *
 *  - parcels: guard logs a delivery for a flat -> resident notified -> resident
 *    collects with a one-time OTP -> collected notification.
 *  - domestic_helpers: a resident's maid/cook/driver profile with an access
 *    status (active/paused/revoked) the gate honours.
 *  - domestic_help_logs: append-only check-in/check-out history per helper.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("parcels", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("unit_id"); // target flat (text to match units references)
    t.text("recipient_name"); // free-text resident name for the label
    t.text("courier").notNullable(); // Amazon / Swiggy / Flipkart / Courier / ...
    t.text("tracking_code");
    t.text("description");
    t.text("photo_url");
    t.text("status").notNullable().defaultTo("pending"); // pending | collected | returned
    t.text("otp"); // one-time collection code shown to the resident
    t.text("logged_by"); // guard uid
    t.text("collected_by"); // uid who handed it over / collected
    t.timestamp("collected_at", { useTz: true });
    t.timestamp("created_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "unit_id"]);
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("domestic_helpers", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("unit_id");
    t.text("member_id"); // owning resident (members.id)
    t.text("created_by"); // resident uid
    t.text("name").notNullable();
    t.text("phone");
    t.text("helper_type").notNullable().defaultTo("maid"); // maid | cook | driver | nanny | other
    t.text("photo_url");
    t.jsonb("schedule").notNullable().defaultTo("{}"); // { days:[...], from:"08:00", to:"18:00" }
    t.text("access_status").notNullable().defaultTo("active"); // active | paused | revoked
    t.timestamp("created_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "unit_id"]);
    t.index(["society_id", "member_id"]);
  });

  await knex.schema.createTable("domestic_help_logs", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("helper_id").notNullable().references("id").inTable("domestic_helpers").onDelete("CASCADE");
    t.text("unit_id");
    t.text("action").notNullable(); // check_in | check_out
    t.text("guard_id");
    t.timestamp("at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "helper_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("domestic_help_logs");
  await knex.schema.dropTableIfExists("domestic_helpers");
  await knex.schema.dropTableIfExists("parcels");
};
