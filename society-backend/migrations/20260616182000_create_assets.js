/**
 * Phase 5 — Assets & maintenance (capabilities 89–92): asset registry, preventive
 * maintenance schedules, work orders, breakdowns/downtime, AMC contracts, vendors,
 * spare parts. Tenant-scoped by society_id. Money in integer minor units.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("asset_categories", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.unique(["society_id", "name"]);
  });

  await knex.schema.createTable("maintenance_vendors", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.text("contact");
    t.text("speciality");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "is_active"]);
  });

  await knex.schema.createTable("assets", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("tag").notNullable(); // asset tag/code
    t.text("name").notNullable();
    t.uuid("category_id").references("id").inTable("asset_categories");
    t.enu("type", ["lift", "generator", "pump", "cctv", "fire", "other"]).notNullable().defaultTo("other");
    t.text("location");
    t.enu("status", ["operational", "down", "retired"]).notNullable().defaultTo("operational");
    t.date("commissioned_on");
    t.bigInteger("purchase_cost_minor").notNullable().defaultTo(0);
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "tag"]);
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("maintenance_schedules", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("asset_id").notNullable().references("id").inTable("assets").onDelete("CASCADE");
    t.text("title").notNullable();
    t.integer("interval_days").notNullable(); // recurrence
    t.date("next_due_on").notNullable();
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "next_due_on"]);
  });

  await knex.schema.createTable("maintenance_work_orders", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("asset_id").notNullable().references("id").inTable("assets").onDelete("CASCADE");
    t.uuid("schedule_id").references("id").inTable("maintenance_schedules"); // set for preventive WOs
    t.uuid("vendor_id").references("id").inTable("maintenance_vendors");
    t.enu("kind", ["preventive", "breakdown", "inspection"]).notNullable().defaultTo("breakdown");
    t.text("title").notNullable();
    t.text("description");
    t.enu("status", ["open", "in_progress", "completed", "cancelled"]).notNullable().defaultTo("open");
    t.text("completion_proof_url");
    t.bigInteger("cost_minor").notNullable().defaultTo(0);
    t.text("created_by");
    t.timestamp("completed_at");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });
  // One OPEN/in-progress work order per schedule occurrence — prevents duplicate
  // preventive work orders for the same scheduled due date.
  await knex.raw(
    `CREATE UNIQUE INDEX wo_one_open_per_schedule ON maintenance_work_orders (schedule_id)
     WHERE schedule_id IS NOT NULL AND status IN ('open','in_progress')`
  );

  await knex.schema.createTable("asset_downtime", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("asset_id").notNullable().references("id").inTable("assets").onDelete("CASCADE");
    t.uuid("work_order_id").references("id").inTable("maintenance_work_orders");
    t.timestamp("started_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("ended_at");
    t.integer("minutes");
    t.text("reason");
    t.index(["society_id", "asset_id"]);
  });

  await knex.schema.createTable("amc_contracts", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("asset_id").references("id").inTable("assets").onDelete("CASCADE");
    t.uuid("vendor_id").references("id").inTable("maintenance_vendors");
    t.text("contract_no");
    t.date("start_date").notNullable();
    t.date("end_date").notNullable();
    t.bigInteger("value_minor").notNullable().defaultTo(0);
    t.enu("status", ["active", "expired", "cancelled"]).notNullable().defaultTo("active");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "end_date"]);
  });

  await knex.schema.createTable("spare_parts", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.integer("quantity").notNullable().defaultTo(0);
    t.bigInteger("unit_cost_minor").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("spare_parts");
  await knex.schema.dropTableIfExists("amc_contracts");
  await knex.schema.dropTableIfExists("asset_downtime");
  await knex.raw(`DROP INDEX IF EXISTS wo_one_open_per_schedule`);
  await knex.schema.dropTableIfExists("maintenance_work_orders");
  await knex.schema.dropTableIfExists("maintenance_schedules");
  await knex.schema.dropTableIfExists("assets");
  await knex.schema.dropTableIfExists("maintenance_vendors");
  await knex.schema.dropTableIfExists("asset_categories");
};
