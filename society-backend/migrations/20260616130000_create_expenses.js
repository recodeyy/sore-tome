/**
 * Expenses with maker-checker approval. Money is in integer minor units.
 * An approved expense posts an immutable journal entry (Dr Expense, Cr Cash).
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("expenses", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("vendor");
    t.text("category");
    t.text("description").notNullable();
    t.bigInteger("amount_minor").notNullable();
    t.bigInteger("tax_minor").notNullable().defaultTo(0);
    t.enu("status", ["pending_approval", "approved", "rejected"]).notNullable().defaultTo("pending_approval");
    t.text("created_by");
    t.text("approved_by");
    t.uuid("journal_entry_id").references("id").inTable("journal_entries");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("expense_approvals", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("expense_id").notNullable().references("id").inTable("expenses").onDelete("CASCADE");
    t.text("approver_id").notNullable();
    t.enu("decision", ["approved", "rejected"]).notNullable();
    t.text("comment");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "expense_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("expense_approvals");
  await knex.schema.dropTableIfExists("expenses");
};
