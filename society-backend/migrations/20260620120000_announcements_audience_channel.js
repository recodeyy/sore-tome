/**
 * Platform announcements: ensure the table exists and carries audience + channel.
 * The table is also created lazily by SuperAdminService; this migration makes the
 * schema (including the new audience/channel columns) explicit and idempotent.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.raw(`
    CREATE TABLE IF NOT EXISTS platform_announcements (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `);
  await knex.raw(`ALTER TABLE platform_announcements ADD COLUMN IF NOT EXISTS audience TEXT`);
  await knex.raw(`ALTER TABLE platform_announcements ADD COLUMN IF NOT EXISTS channel TEXT`);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.raw(`ALTER TABLE platform_announcements DROP COLUMN IF EXISTS channel`);
  await knex.raw(`ALTER TABLE platform_announcements DROP COLUMN IF EXISTS audience`);
};
