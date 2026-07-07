/**
 * Finance billing depth: proration, late fees/waivers, GST credit notes,
 * recurring billing runs, and receipts. Money in integer minor units;
 * every table tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  // Per-line taxable base so tax breakdown (taxable + tax + total) is auditable.
  await knex.schema.alterTable("invoice_lines", (t) => {
    t.bigInteger("taxable_minor").notNullable().defaultTo(0);
    t.decimal("tax_rate", 6, 3).notNullable().defaultTo(0); // e.g. 18.000 (%)
  });

  // Late-fee marker on invoices makes fee application idempotent.
  await knex.schema.alterTable("invoices", (t) => {
    t.bigInteger("late_fee_minor").notNullable().defaultTo(0);
    t.timestamp("late_fee_applied_at");
    t.uuid("recurring_run_id"); // provenance for recurring billing
  });

  // Recurring billing runs: idempotent per (society, policy_key, period).
  await knex.schema.createTable("recurring_billing_runs", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("policy_key").notNullable(); // identifies the recurring template
    t.text("period").notNullable(); // e.g. 2026-07
    t.enu("status", ["running", "completed", "failed"]).notNullable().defaultTo("running");
    t.integer("invoices_created").notNullable().defaultTo(0);
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("completed_at");
    t.unique(["society_id", "policy_key", "period"]);
  });

  // Immutable credit notes with their own numbering sequence.
  await knex.schema.createTable("credit_notes", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("number").notNullable(); // CN-... immutable
    t.uuid("invoice_id").notNullable().references("id").inTable("invoices");
    t.text("reason").notNullable();
    t.bigInteger("taxable_minor").notNullable().defaultTo(0);
    t.bigInteger("tax_minor").notNullable().defaultTo(0);
    t.bigInteger("total_minor").notNullable();
    t.text("currency").notNullable().defaultTo("INR");
    t.uuid("journal_entry_id").references("id").inTable("journal_entries");
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "number"]);
    t.index(["society_id", "invoice_id"]);
  });

  // Receipts issued on payment capture; supports void + reissue.
  await knex.schema.createTable("receipts", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("number").notNullable(); // RCPT-... immutable
    t.uuid("payment_id").notNullable().references("id").inTable("payments");
    t.bigInteger("amount_minor").notNullable();
    t.text("currency").notNullable().defaultTo("INR");
    t.enu("status", ["issued", "void"]).notNullable().defaultTo("issued");
    t.text("void_reason");
    t.uuid("reissued_from"); // points to the voided receipt this replaces
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("voided_at");
    t.unique(["society_id", "number"]);
    // At most one live (issued) receipt per payment.
    t.index(["society_id", "payment_id"]);
  });
  await knex.raw(`
    CREATE UNIQUE INDEX receipts_one_live_per_payment
    ON receipts (society_id, payment_id) WHERE status = 'issued'
  `);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("receipts");
  await knex.schema.dropTableIfExists("credit_notes");
  await knex.schema.dropTableIfExists("recurring_billing_runs");
  await knex.schema.alterTable("invoices", (t) => {
    t.dropColumn("late_fee_minor");
    t.dropColumn("late_fee_applied_at");
    t.dropColumn("recurring_run_id");
  });
  await knex.schema.alterTable("invoice_lines", (t) => {
    t.dropColumn("taxable_minor");
    t.dropColumn("tax_rate");
  });
};

