/**
 * Phase 4 — Complaints capabilities 65 (escalation ladder) and 67 (attachments).
 * Tenant-scoped by society_id. Escalations are idempotent per (complaint_id, level)
 * for a given breach window via unique(complaint_id, level, due_at_at_escalation).
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  // Escalation ladder events recorded by the breach worker.
  await knex.schema.createTable("complaint_escalations", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.integer("level").notNullable().defaultTo(1);
    t.timestamp("due_at_at_escalation").notNullable(); // the breached due_at snapshot
    t.text("reason");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    // Idempotency: one escalation row per complaint+level for the same breached due_at.
    t.unique(["complaint_id", "level", "due_at_at_escalation"]);
    t.index(["society_id", "complaint_id"]);
  });

  // File / image / video evidence attached to a complaint.
  await knex.schema.createTable("complaint_attachments", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("complaint_id").notNullable().references("id").inTable("complaints").onDelete("CASCADE");
    t.text("file_url").notNullable();
    t.text("mime");
    t.text("kind"); // e.g. before/after/proof
    t.text("uploaded_by");
    t.text("scan_status").notNullable().defaultTo("pending"); // malware scan state
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "complaint_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("complaint_attachments");
  await knex.schema.dropTableIfExists("complaint_escalations");
};
