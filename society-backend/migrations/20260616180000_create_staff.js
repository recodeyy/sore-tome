/**
 * Phase 5 — Staff, attendance, roster, leave, payroll (capabilities 70–79).
 * Tenant-scoped by society_id. Money in integer minor units. Times UTC.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("staff", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.text("role"); // guard, housekeeping, electrician, manager, ...
    t.text("department");
    t.boolean("is_contractor").notNullable().defaultTo(false);
    t.text("phone");
    t.text("user_id"); // linked app login, if any (restricted access)
    t.enu("status", ["active", "suspended", "terminated"]).notNullable().defaultTo("active");
    t.date("joining_date");
    t.date("leaving_date");
    t.specificType("assigned_areas", "text[]").notNullable().defaultTo(knex.raw("'{}'"));
    t.bigInteger("monthly_wage_minor").notNullable().defaultTo(0);
    t.date("kyc_expires_at");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("shift_templates", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.integer("start_minutes").notNullable(); // from local midnight
    t.integer("end_minutes").notNullable(); // may exceed 1440 for overnight shifts
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
  });

  await knex.schema.createTable("duty_rosters", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("staff_id").notNullable().references("id").inTable("staff").onDelete("CASCADE");
    t.uuid("shift_template_id").references("id").inTable("shift_templates");
    t.date("duty_date").notNullable();
    t.text("area");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    // One roster slot per staff per day per shift — prevents conflicting double-booking.
    t.unique(["staff_id", "duty_date", "shift_template_id"]);
    t.index(["society_id", "duty_date"]);
  });

  await knex.schema.createTable("attendance_entries", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("staff_id").notNullable().references("id").inTable("staff").onDelete("CASCADE");
    t.date("work_date").notNullable();
    t.timestamp("check_in_at");
    t.timestamp("check_out_at");
    t.integer("worked_minutes").notNullable().defaultTo(0);
    t.enu("status", ["present", "absent", "half_day", "on_leave"]).notNullable().defaultTo("present");
    t.text("source"); // manual, qr, geofence
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    // One attendance row per staff per day — prevents duplicate check-ins.
    t.unique(["staff_id", "work_date"]);
    t.index(["society_id", "work_date"]);
  });

  await knex.schema.createTable("attendance_adjustments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("attendance_id").notNullable().references("id").inTable("attendance_entries").onDelete("CASCADE");
    t.text("reason").notNullable();
    t.jsonb("before").notNullable();
    t.jsonb("after").notNullable();
    t.text("adjusted_by").notNullable();
    t.text("approved_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
  });

  await knex.schema.createTable("leave_types", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.integer("annual_quota_days").notNullable().defaultTo(0);
    t.boolean("is_paid").notNullable().defaultTo(true);
    t.unique(["society_id", "name"]);
  });

  await knex.schema.createTable("leave_balances", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("staff_id").notNullable().references("id").inTable("staff").onDelete("CASCADE");
    t.uuid("leave_type_id").notNullable().references("id").inTable("leave_types").onDelete("CASCADE");
    t.integer("year").notNullable();
    t.decimal("balance_days", 6, 2).notNullable().defaultTo(0);
    t.unique(["staff_id", "leave_type_id", "year"]);
  });

  await knex.schema.createTable("leave_requests", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("staff_id").notNullable().references("id").inTable("staff").onDelete("CASCADE");
    t.uuid("leave_type_id").notNullable().references("id").inTable("leave_types");
    t.date("from_date").notNullable();
    t.date("to_date").notNullable();
    t.decimal("days", 6, 2).notNullable();
    t.enu("status", ["pending", "approved", "rejected", "cancelled"]).notNullable().defaultTo("pending");
    t.text("reason");
    t.text("decided_by");
    t.text("decision_comment");
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("payroll_runs", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("period").notNullable(); // YYYY-MM
    t.enu("status", ["draft", "approved", "paid"]).notNullable().defaultTo("draft");
    t.bigInteger("gross_minor").notNullable().defaultTo(0);
    t.bigInteger("deductions_minor").notNullable().defaultTo(0);
    t.bigInteger("net_minor").notNullable().defaultTo(0);
    t.text("created_by");
    t.text("approved_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    // One payroll run per society per period — re-run protection.
    t.unique(["society_id", "period"]);
  });

  await knex.schema.createTable("payroll_items", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("payroll_run_id").notNullable().references("id").inTable("payroll_runs").onDelete("CASCADE");
    t.uuid("staff_id").notNullable().references("id").inTable("staff");
    t.bigInteger("earnings_minor").notNullable().defaultTo(0);
    t.bigInteger("deductions_minor").notNullable().defaultTo(0);
    t.bigInteger("advance_minor").notNullable().defaultTo(0);
    t.bigInteger("net_minor").notNullable().defaultTo(0);
    t.integer("present_days").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["payroll_run_id", "staff_id"]);
  });

  await knex.schema.createTable("staff_incidents", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("staff_id").notNullable().references("id").inTable("staff").onDelete("CASCADE");
    t.enu("type", ["incident", "performance", "disciplinary"]).notNullable().defaultTo("incident");
    t.text("title").notNullable();
    t.text("details");
    t.boolean("is_private").notNullable().defaultTo(true);
    t.text("recorded_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "staff_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("staff_incidents");
  await knex.schema.dropTableIfExists("payroll_items");
  await knex.schema.dropTableIfExists("payroll_runs");
  await knex.schema.dropTableIfExists("leave_requests");
  await knex.schema.dropTableIfExists("leave_balances");
  await knex.schema.dropTableIfExists("leave_types");
  await knex.schema.dropTableIfExists("attendance_adjustments");
  await knex.schema.dropTableIfExists("attendance_entries");
  await knex.schema.dropTableIfExists("duty_rosters");
  await knex.schema.dropTableIfExists("shift_templates");
  await knex.schema.dropTableIfExists("staff");
};
