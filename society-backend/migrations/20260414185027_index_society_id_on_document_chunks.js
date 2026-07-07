/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
  return knex.schema.alterTable("document_chunks", (table) => {
    table.index("society_id", "idx_dc_society_id");
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.alterTable("document_chunks", (table) => {
    table.dropIndex("society_id", "idx_dc_society_id");
  });
};

