/**
 * Phase 4 — Channels / messaging + moderation (capabilities 50–51).
 * Tenant-scoped by society_id; all timestamps UTC. Messages support cursor
 * pagination (created_at,id), read receipts, read-only channels, abuse reports,
 * and soft-deletion + admin moderation actions (retention-friendly: rows are
 * never hard-deleted, only flagged deleted_at).
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("channels", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.text("description");
    t.enu("type", ["community", "announcement", "committee", "support"]).notNullable().defaultTo("community");
    t.boolean("is_read_only").notNullable().defaultTo(false); // only admins may post
    t.boolean("is_archived").notNullable().defaultTo(false);
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
    t.index(["society_id", "is_archived"]);
  });

  await knex.schema.createTable("channel_members", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("channel_id").notNullable().references("id").inTable("channels").onDelete("CASCADE");
    t.text("user_id").notNullable();
    t.enu("role", ["member", "moderator"]).notNullable().defaultTo("member");
    t.boolean("is_muted").notNullable().defaultTo(false);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["channel_id", "user_id"]);
    t.index(["society_id", "channel_id"]);
  });

  await knex.schema.createTable("messages", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("channel_id").notNullable().references("id").inTable("channels").onDelete("CASCADE");
    t.text("author_id").notNullable();
    t.text("author_name");
    t.text("body").notNullable();
    t.boolean("is_official").notNullable().defaultTo(false);
    t.timestamp("deleted_at"); // soft delete (moderation/retention)
    t.text("deleted_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    // Cursor pagination + per-channel ordering.
    t.index(["channel_id", "created_at", "id"]);
  });

  await knex.schema.createTable("message_reads", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("channel_id").notNullable().references("id").inTable("channels").onDelete("CASCADE");
    t.text("user_id").notNullable();
    t.uuid("last_read_message_id");
    t.timestamp("last_read_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["channel_id", "user_id"]);
  });

  await knex.schema.createTable("moderation_reports", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("message_id").references("id").inTable("messages").onDelete("CASCADE");
    t.text("target_type").notNullable().defaultTo("message"); // message | listing
    t.text("target_id"); // for non-message targets (e.g. classified listing)
    t.text("reporter_id").notNullable();
    t.text("reason").notNullable();
    t.enu("status", ["open", "actioned", "dismissed"]).notNullable().defaultTo("open");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("moderation_actions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("report_id").references("id").inTable("moderation_reports").onDelete("SET NULL");
    t.uuid("message_id").references("id").inTable("messages").onDelete("CASCADE");
    t.enu("action", ["soft_delete", "dismiss", "mute_user", "warn"]).notNullable();
    t.text("actor_id").notNullable();
    t.text("note");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "message_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("moderation_actions");
  await knex.schema.dropTableIfExists("moderation_reports");
  await knex.schema.dropTableIfExists("message_reads");
  await knex.schema.dropTableIfExists("messages");
  await knex.schema.dropTableIfExists("channel_members");
  await knex.schema.dropTableIfExists("channels");
};
