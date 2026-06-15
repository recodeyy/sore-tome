/**
 * Staff pack — capabilities 71, 76, 77, 79.
 *  - 71 Staff permissions / restricted app access (staff.permissions jsonb).
 *  - 76 Overtime/holiday/late-arrival inputs (society_holidays, staff overtime/late columns).
 *  - 77 KYC, contracts, training, certifications with expiry (staff_documents).
 *  - 79 Reports are aggregation queries (no new tables).
 * Tenant-scoped by society_id. Money in integer minor units. Times UTC.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  // 71 — restricted app permissions per staff (array of permission keys).
  await knex.schema.alterTable("staff", (t) => {
    t.specificType("permissions", "text[]").notNullable().defaultTo(knex.raw("'{}'"));
    // 76 — wage/overtime parameters.
    t.bigInteger("overtime_rate_minor").notNullable().defaultTo(0); // per OT hour
    t.integer("standard_shift_minutes").notNullable().defaultTo(480); // 8h baseline
    t.integer("late_grace_minutes").notNullable().defaultTo(0);
  });

  // 76 — overtime & late-arrival derived columns on attendance.
  await knex.schema.alterTable("attendance_entries", (t) => {
    t.integer("overtime_minutes").notNullable().defaultTo(0);
    t.integer("late_minutes").notNullable().defaultTo(0);
    t.boolean("is_holiday").notNullable().defaultTo(false);
  });

  // 76 — society holiday calendar feeds holiday-pay calculations.
  await knex.schema.createTable("society_holidays", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.date("holiday_date").notNullable();
    t.text("name").notNullable();
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "holiday_date"]);
  });

  // 77 — KYC, contracts, training, certifications with expiry reminders.
  await knex.schema.createTable("staff_documents", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("staff_id").notNullable().references("id").inTable("staff").onDelete("CASCADE");
    t.enu("doc_type", ["kyc", "contract", "training", "certification"]).notNullable();
    t.text("title").notNullable();
    t.text("reference"); // doc number / id
    t.text("file_url");
    t.date("issued_on");
    t.date("expires_on");
    t.enu("status", ["valid", "expired", "revoked"]).notNullable().defaultTo("valid");
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "doc_type"]);
    t.index(["society_id", "expires_on"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("staff_documents");
  await knex.schema.dropTableIfExists("society_holidays");
  await knex.schema.alterTable("attendance_entries", (t) => {
    t.dropColumn("overtime_minutes");
    t.dropColumn("late_minutes");
    t.dropColumn("is_holiday");
  });
  await knex.schema.alterTable("staff", (t) => {
    t.dropColumn("permissions");
    t.dropColumn("overtime_rate_minor");
    t.dropColumn("standard_shift_minutes");
    t.dropColumn("late_grace_minutes");
  });
};
