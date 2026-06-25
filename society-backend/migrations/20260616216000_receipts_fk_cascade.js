/**
 * Fix: receipts.payment_id referenced payments without ON DELETE CASCADE, so
 * deleting a payment (e.g. test teardown or a payment reversal) failed with a
 * FK violation. Recreate the constraint with ON DELETE CASCADE — a receipt has
 * no meaning without its payment.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.raw(`ALTER TABLE receipts DROP CONSTRAINT IF EXISTS receipts_payment_id_foreign`);
  await knex.raw(`
    ALTER TABLE receipts
    ADD CONSTRAINT receipts_payment_id_foreign
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
  `);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.raw(`ALTER TABLE receipts DROP CONSTRAINT IF EXISTS receipts_payment_id_foreign`);
  await knex.raw(`
    ALTER TABLE receipts
    ADD CONSTRAINT receipts_payment_id_foreign
    FOREIGN KEY (payment_id) REFERENCES payments(id)
  `);
};
