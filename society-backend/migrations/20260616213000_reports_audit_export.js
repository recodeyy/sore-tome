/**
 * Phase 6/7 — Report generation artifacts + retention (capability 91) and an
 * immutable, tenant-scoped administrative audit log with export (capability 92).
 *
 * - report_jobs gains output_content (generated artifact body), content_type,
 *   file_name and expires_at (retention).
 * - audit_logs is append-only: a BEFORE UPDATE/DELETE trigger raises an
 *   exception so rows can never be mutated or removed once written.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.alterTable("report_jobs", (t) => {
    t.text("output_content");
    t.text("content_type");
    t.text("file_name");
    t.timestamp("expires_at").nullable();
  });

  await knex.schema.createTable("audit_logs", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("actor_id");
    t.text("actor_name");
    t.text("action").notNullable();
    t.text("resource");
    t.text("result").notNullable().defaultTo("success");
    t.text("ip");
    t.text("request_id");
    t.text("reason");
    t.jsonb("before").notNullable().defaultTo("{}");
    t.jsonb("after").notNullable().defaultTo("{}");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "created_at"]);
    t.index(["society_id", "actor_id"]);
  });

  // Append-only guard: block UPDATE and DELETE at the database level.
  await knex.raw(`
    CREATE OR REPLACE FUNCTION audit_logs_append_only() RETURNS trigger AS $$
    BEGIN
      RAISE EXCEPTION 'audit_logs is append-only';
    END;
    $$ LANGUAGE plpgsql;
  `);
  await knex.raw(`
    CREATE TRIGGER audit_logs_no_update BEFORE UPDATE ON audit_logs
      FOR EACH ROW EXECUTE FUNCTION audit_logs_append_only();
  `);
  await knex.raw(`
    CREATE TRIGGER audit_logs_no_delete BEFORE DELETE ON audit_logs
      FOR EACH ROW EXECUTE FUNCTION audit_logs_append_only();
  `);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.raw(`DROP TRIGGER IF EXISTS audit_logs_no_update ON audit_logs;`);
  await knex.raw(`DROP TRIGGER IF EXISTS audit_logs_no_delete ON audit_logs;`);
  await knex.raw(`DROP FUNCTION IF EXISTS audit_logs_append_only();`);
  await knex.schema.dropTableIfExists("audit_logs");
  await knex.schema.alterTable("report_jobs", (t) => {
    t.dropColumn("output_content");
    t.dropColumn("content_type");
    t.dropColumn("file_name");
    t.dropColumn("expires_at");
  });
};
