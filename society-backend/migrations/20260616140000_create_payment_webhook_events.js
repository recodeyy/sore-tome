/**
 * Stores incoming payment-gateway webhook events for replay protection and audit.
 * Processing is idempotent: a repeated event_id is ignored.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("payment_webhook_events", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("provider").notNullable();
    t.text("event_id").notNullable();
    t.text("event_type");
    t.text("society_id");
    t.boolean("signature_valid").notNullable().defaultTo(false);
    t.boolean("processed").notNullable().defaultTo(false);
    t.jsonb("payload");
    t.text("error");
    t.timestamp("received_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["provider", "event_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("payment_webhook_events");
};
