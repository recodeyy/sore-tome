/**
 * Finance core: double-entry ledger + billing + payments.
 * Money is stored as integer minor units (paise) — never float.
 * Every row is tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  // Chart of accounts — one tree per society.
  await knex.schema.createTable("chart_of_accounts", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("code").notNullable();
    t.text("name").notNullable();
    t.enu("type", ["asset", "liability", "equity", "income", "expense"]).notNullable();
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "code"]);
  });

  // Invoices (bills). Published invoices are immutable; corrections use credit notes.
  await knex.schema.createTable("invoices", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("number").notNullable(); // human-facing, immutable once published
    t.text("unit_id");
    t.text("member_id");
    t.text("period"); // e.g. 2026-06
    t.enu("status", ["draft", "published", "cancelled"]).notNullable().defaultTo("draft");
    t.bigInteger("subtotal_minor").notNullable().defaultTo(0);
    t.bigInteger("tax_minor").notNullable().defaultTo(0);
    t.bigInteger("total_minor").notNullable().defaultTo(0);
    t.text("currency").notNullable().defaultTo("INR");
    t.date("due_date");
    t.timestamp("published_at");
    t.text("created_by");
    t.integer("version").notNullable().defaultTo(0); // optimistic locking
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "number"]);
    t.index(["society_id", "status"]);
    t.index(["society_id", "member_id"]);
  });

  await knex.schema.createTable("invoice_lines", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("invoice_id").notNullable().references("id").inTable("invoices").onDelete("CASCADE");
    t.text("description").notNullable();
    t.text("component"); // maintenance, sinking_fund, parking, water, penalty, ...
    t.integer("quantity").notNullable().defaultTo(1);
    t.bigInteger("unit_price_minor").notNullable().defaultTo(0);
    t.bigInteger("tax_minor").notNullable().defaultTo(0);
    t.bigInteger("amount_minor").notNullable().defaultTo(0);
    t.index(["society_id", "invoice_id"]);
  });

  // Payments. idempotency_key makes webhook/retry processing exactly-once.
  await knex.schema.createTable("payments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("provider"); // razorpay, manual, ...
    t.text("provider_payment_id"); // safe identifier only, never card data
    t.bigInteger("amount_minor").notNullable();
    t.text("currency").notNullable().defaultTo("INR");
    t.enu("status", ["pending", "captured", "failed", "refunded"]).notNullable().defaultTo("pending");
    t.text("idempotency_key");
    t.jsonb("metadata");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "idempotency_key"]);
    t.unique(["society_id", "provider", "provider_payment_id"]);
    t.index(["society_id", "status"]);
  });

  // Allocation of a payment against one or more invoices.
  await knex.schema.createTable("payment_allocations", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("payment_id").notNullable().references("id").inTable("payments").onDelete("CASCADE");
    t.uuid("invoice_id").notNullable().references("id").inTable("invoices");
    t.bigInteger("amount_minor").notNullable();
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "invoice_id"]);
  });

  // Immutable journal entries (the ledger).
  await knex.schema.createTable("journal_entries", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.date("entry_date").notNullable();
    t.text("memo");
    t.text("source_type"); // invoice, payment, expense, adjustment
    t.text("source_id");
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "entry_date"]);
    t.index(["society_id", "source_type", "source_id"]);
  });

  await knex.schema.createTable("journal_lines", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("journal_entry_id").notNullable().references("id").inTable("journal_entries").onDelete("CASCADE");
    t.uuid("account_id").notNullable().references("id").inTable("chart_of_accounts");
    t.bigInteger("debit_minor").notNullable().defaultTo(0);
    t.bigInteger("credit_minor").notNullable().defaultTo(0);
    t.index(["society_id", "account_id"]);
  });

  // A journal line is exactly one-sided and non-negative.
  await knex.raw(`
    ALTER TABLE journal_lines
    ADD CONSTRAINT journal_lines_one_sided
    CHECK (
      debit_minor >= 0 AND credit_minor >= 0
      AND (debit_minor = 0) <> (credit_minor = 0)
    )
  `);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("journal_lines");
  await knex.schema.dropTableIfExists("journal_entries");
  await knex.schema.dropTableIfExists("payment_allocations");
  await knex.schema.dropTableIfExists("payments");
  await knex.schema.dropTableIfExists("invoice_lines");
  await knex.schema.dropTableIfExists("invoices");
  await knex.schema.dropTableIfExists("chart_of_accounts");
};
