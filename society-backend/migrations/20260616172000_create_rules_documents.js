/**
 * Rules & Society Documents (Phase 4, capability 58).
 * Tenant-scoped bylaws/rules/NOCs/policies with edit history (rule_versions),
 * and society documents with file version history (document_versions).
 * Full-text search over rules via a GIN tsvector index.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("rules", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("title").notNullable();
    t.enu("category", ["bylaw", "rule", "noc", "policy", "other"]).notNullable().defaultTo("rule");
    t.text("body").notNullable();
    t.enu("status", ["draft", "active", "archived"]).notNullable().defaultTo("draft");
    t.integer("current_version").notNullable().defaultTo(1);
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("rule_versions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("rule_id").notNullable().references("id").inTable("rules").onDelete("CASCADE");
    t.integer("version").notNullable();
    t.text("title").notNullable();
    t.text("body").notNullable();
    t.text("edited_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "rule_id"]);
  });

  await knex.schema.createTable("society_documents", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("title").notNullable();
    t.enu("doc_type", ["bylaw", "noc", "record", "minutes", "other"]).notNullable().defaultTo("other");
    t.integer("current_version").notNullable().defaultTo(1);
    t.text("created_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "doc_type"]);
  });

  await knex.schema.createTable("document_versions", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("document_id").notNullable().references("id").inTable("society_documents").onDelete("CASCADE");
    t.integer("version").notNullable();
    t.text("file_url").notNullable();
    t.text("file_name");
    t.text("mime_type");
    t.text("checksum");
    t.text("uploaded_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "document_id"]);
  });

  // Full-text search index over rules (title + body).
  await knex.raw(
    `CREATE INDEX rules_fts_idx ON rules USING gin (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,'')))`
  );
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("document_versions");
  await knex.schema.dropTableIfExists("society_documents");
  await knex.schema.dropTableIfExists("rule_versions");
  await knex.schema.dropTableIfExists("rules");
};
