/**
 * Super Admin depth (pack §9 KYC, §10 subscriptions). Adds a platform-scoped
 * KYC review ledger. Subscription plan CRUD, plan-change history and lifecycle
 * status history reuse the existing control-plane tables.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  const hasKyc = await knex.schema.hasTable("society_kyc_reviews");
  if (!hasKyc) {
    await knex.schema.createTable("society_kyc_reviews", (t) => {
      t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
      t.text("society_id").notNullable();
      t.uuid("application_id");
      t.enu("decision", ["pending", "approved", "rejected", "replacement_requested"])
        .notNullable()
        .defaultTo("pending");
      t.text("reason");
      t.text("actor_id");
      t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
      t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
      t.index(["society_id"]);
    });
  }
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("society_kyc_reviews");
};
