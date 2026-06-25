/**
 * Super Admin control plane (Super Admin pack §5). Platform-scoped tables that
 * are NOT tenant-owned — they are administered by platform roles only. Covers
 * society lifecycle (B), subscriptions/plans (C), feature controls (D), support
 * (E), and impersonation/audit (F). Money is in integer minor units.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  // C. Subscription plans + per-society subscription
  await knex.schema.createTable("subscription_plans", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("code").notNullable().unique();
    t.text("name").notNullable();
    t.bigInteger("price_minor").notNullable().defaultTo(0);
    t.text("currency").notNullable().defaultTo("INR");
    t.enu("interval", ["monthly", "yearly"]).notNullable().defaultTo("monthly");
    t.jsonb("features").notNullable().defaultTo(knex.raw("'[]'::jsonb"));
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable("society_subscriptions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("plan_id").notNullable().references("id").inTable("subscription_plans");
    t.enu("status", ["trial", "active", "grace", "suspended", "cancelled"]).notNullable().defaultTo("trial");
    t.date("effective_date");
    t.date("renews_at");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id"]); // one active subscription record per society
  });

  await knex.schema.createTable("subscription_changes", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("from_plan_id");
    t.uuid("to_plan_id").notNullable();
    t.text("actor_id");
    t.text("reason");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id"]);
  });

  // B. Society lifecycle
  await knex.schema.createTable("society_applications", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_name").notNullable();
    t.text("contact_email");
    t.enu("status", ["pending", "approved", "rejected"]).notNullable().defaultTo("pending");
    t.text("society_id"); // set once approved
    t.text("reviewer_id");
    t.text("reject_reason");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable("society_status_history", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("from_status");
    t.text("to_status").notNullable();
    t.text("actor_id");
    t.text("reason");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id"]);
  });

  // D. Feature controls (per-society overrides over a platform feature registry)
  await knex.schema.createTable("platform_features", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("key").notNullable().unique();
    t.text("name").notNullable();
    t.boolean("default_enabled").notNullable().defaultTo(false);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable("society_feature_overrides", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("feature_key").notNullable();
    t.boolean("enabled").notNullable();
    t.text("actor_id");
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "feature_key"]);
  });

  // E. Support tickets
  await knex.schema.createTable("support_tickets", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id");
    t.text("subject").notNullable();
    t.text("body");
    t.enu("priority", ["low", "medium", "high", "urgent"]).notNullable().defaultTo("medium");
    t.enu("status", ["open", "in_progress", "resolved", "closed"]).notNullable().defaultTo("open");
    t.text("assignee_id");
    t.text("requester_id");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["status", "priority"]);
  });

  await knex.schema.createTable("support_ticket_comments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.uuid("ticket_id").notNullable().references("id").inTable("support_tickets").onDelete("CASCADE");
    t.text("author_id");
    t.text("body").notNullable();
    t.boolean("internal").notNullable().defaultTo(false);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["ticket_id"]);
  });

  await knex.schema.createTable("support_ticket_status_history", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.uuid("ticket_id").notNullable().references("id").inTable("support_tickets").onDelete("CASCADE");
    t.text("from_status");
    t.text("to_status").notNullable();
    t.text("actor_id");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["ticket_id"]);
  });

  // F. Impersonation (controlled, reason + expiry + stop)
  await knex.schema.createTable("impersonation_sessions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("actor_id").notNullable(); // platform user impersonating
    t.text("target_user_id").notNullable();
    t.text("society_id");
    t.text("reason").notNullable();
    t.enu("status", ["active", "ended", "expired"]).notNullable().defaultTo("active");
    t.timestamp("expires_at").notNullable();
    t.timestamp("ended_at");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["actor_id", "status"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("impersonation_sessions");
  await knex.schema.dropTableIfExists("support_ticket_status_history");
  await knex.schema.dropTableIfExists("support_ticket_comments");
  await knex.schema.dropTableIfExists("support_tickets");
  await knex.schema.dropTableIfExists("society_feature_overrides");
  await knex.schema.dropTableIfExists("platform_features");
  await knex.schema.dropTableIfExists("society_status_history");
  await knex.schema.dropTableIfExists("society_applications");
  await knex.schema.dropTableIfExists("subscription_changes");
  await knex.schema.dropTableIfExists("society_subscriptions");
  await knex.schema.dropTableIfExists("subscription_plans");
};
