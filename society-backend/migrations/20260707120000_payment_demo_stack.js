/**
 * Demo payment stack (revamp §7.2/§13):
 *  1. payments.status gains the full lifecycle: pending → processing →
 *     verified/captured/failed, plus refunded and a demo-reversal state
 *     ('reversed'). 'captured' is kept as the canonical settled state the
 *     ledger queries already use; 'verified' is an accepted synonym.
 *  2. invoices.last_reminded_at — dues-reminder job sends at most one
 *     reminder per invoice per day.
 *  3. demo_payment_audits — audit trail for the admin-only UPI demo
 *     "mark paid" action (who/when/reference).
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.raw(`ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_status_check`);
  await knex.raw(`
    ALTER TABLE payments ADD CONSTRAINT payments_status_check
    CHECK (status = ANY (ARRAY[
      'pending'::text, 'processing'::text, 'verified'::text, 'captured'::text,
      'failed'::text, 'refunded'::text, 'reversed'::text
    ]))
  `);

  await knex.schema.alterTable("invoices", (t) => {
    t.timestamp("last_reminded_at");
  });

  await knex.schema.createTable("demo_payment_audits", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("invoice_id").notNullable().references("id").inTable("invoices");
    t.uuid("payment_id").references("id").inTable("payments");
    t.text("action").notNullable().defaultTo("upi_demo_mark_paid");
    t.text("reference").notNullable(); // UPI reference / UTR supplied by the admin
    t.text("actor_id").notNullable(); // who marked it paid
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "invoice_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("demo_payment_audits");
  await knex.schema.alterTable("invoices", (t) => {
    t.dropColumn("last_reminded_at");
  });
  await knex.raw(`ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_status_check`);
  await knex.raw(`
    ALTER TABLE payments ADD CONSTRAINT payments_status_check
    CHECK (status = ANY (ARRAY['pending'::text, 'captured'::text, 'failed'::text, 'refunded'::text]))
  `);
};
