/**
 * Bank statement import & reconciliation (capability 40). Tenant-scoped by
 * society_id. A statement import holds many statement lines; each line is matched
 * (auto by amount, or manually) against a captured payment. Money in minor units.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("bank_accounts", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.text("account_no_masked");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id"]);
  });

  await knex.schema.createTable("bank_statement_imports", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("bank_account_id").references("id").inTable("bank_accounts");
    t.text("filename");
    t.integer("line_count").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id"]);
  });

  await knex.schema.createTable("bank_statement_lines", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("import_id").notNullable().references("id").inTable("bank_statement_imports").onDelete("CASCADE");
    t.date("txn_date");
    t.bigInteger("amount_minor").notNullable();
    t.text("description");
    t.text("reference");
    t.enu("match_status", ["unmatched", "matched", "partial"]).notNullable().defaultTo("unmatched");
    t.uuid("matched_payment_id");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "import_id", "match_status"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("bank_statement_lines");
  await knex.schema.dropTableIfExists("bank_statement_imports");
  await knex.schema.dropTableIfExists("bank_accounts");
};
