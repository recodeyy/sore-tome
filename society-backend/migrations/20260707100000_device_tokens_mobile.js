/**
 * MR-001 / MR-006 (mobile revamp):
 *  - device_tokens: add app_version + last_seen_at so multi-device FCM
 *    registration (POST /notifications/devices, legacy PATCH /users/me
 *    {fcmToken}) can track token freshness per device.
 *  - members: add requested_unit so resident join-requests (self-service
 *    onboarding) can capture the flat the resident claims (wing/floor/unit)
 *    even before an admin links a real units row.
 *
 * The device_tokens table itself already exists (20260616205000).
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.alterTable("device_tokens", (t) => {
    t.text("app_version");
    t.timestamp("last_seen_at", { useTz: true }).notNullable().defaultTo(knex.fn.now());
  });
  await knex.schema.alterTable("members", (t) => {
    t.text("requested_unit");
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.alterTable("device_tokens", (t) => {
    t.dropColumn("app_version");
    t.dropColumn("last_seen_at");
  });
  await knex.schema.alterTable("members", (t) => {
    t.dropColumn("requested_unit");
  });
};
