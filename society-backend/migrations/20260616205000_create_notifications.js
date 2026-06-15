/**
 * Notifications + delivery tracking (Phase 1 data model).
 * Records notifications, fans out to a user's registered devices, and tracks
 * delivery attempts. FCM send is pluggable/stubbed. Tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("device_tokens", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id");
    t.text("user_id").notNullable();
    t.text("token").notNullable();
    t.enu("platform", ["android", "ios", "web"]).notNullable().defaultTo("android");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["token"]);
    t.index(["society_id", "user_id"]);
  });

  await knex.schema.createTable("notifications", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("user_id");
    t.text("title").notNullable();
    t.text("body");
    t.text("type");
    t.jsonb("data").notNullable().defaultTo(knex.raw("'{}'::jsonb"));
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "user_id"]);
  });

  await knex.schema.createTable("notification_deliveries", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id");
    t.uuid("notification_id").notNullable().references("id").inTable("notifications").onDelete("CASCADE");
    t.uuid("device_token_id").references("id").inTable("device_tokens");
    t.enu("status", ["queued", "sent", "failed"]).notNullable().defaultTo("queued");
    t.integer("attempts").notNullable().defaultTo(0);
    t.text("error");
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["notification_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("notification_deliveries");
  await knex.schema.dropTableIfExists("notifications");
  await knex.schema.dropTableIfExists("device_tokens");
};
