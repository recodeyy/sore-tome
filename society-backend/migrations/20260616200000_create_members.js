/**
 * Phase 2 — Members (capabilities 17–20): member directory & lifecycle, committee
 * roles, family members, and KYC documents. Tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("members", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("user_id");
    t.text("name").notNullable();
    t.text("phone");
    t.text("email");
    t.uuid("unit_id");
    t.enu("status", ["pending", "approved", "rejected", "suspended", "deactivated", "moved_out"])
      .notNullable()
      .defaultTo("pending");
    t.text("role");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.integer("version").notNullable().defaultTo(0);
    t.index(["society_id", "status"]);
  });

  await knex.schema.createTable("committee_members", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("member_id").notNullable().references("id").inTable("members").onDelete("CASCADE");
    t.text("designation").notNullable();
    t.date("term_start");
    t.date("term_end");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "member_id"]);
  });

  await knex.schema.createTable("family_members", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("member_id").notNullable().references("id").inTable("members").onDelete("CASCADE");
    t.text("name").notNullable();
    t.text("relation");
    t.text("phone");
    t.boolean("is_emergency_contact").notNullable().defaultTo(false);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "member_id"]);
  });

  await knex.schema.createTable("kyc_documents", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("member_id").notNullable().references("id").inTable("members").onDelete("CASCADE");
    t.text("doc_type").notNullable();
    t.text("file_url");
    t.enu("status", ["pending", "approved", "rejected"]).notNullable().defaultTo("pending");
    t.text("reject_reason");
    t.date("expires_at");
    t.text("reviewed_by");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "status"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("kyc_documents");
  await knex.schema.dropTableIfExists("family_members");
  await knex.schema.dropTableIfExists("committee_members");
  await knex.schema.dropTableIfExists("members");
};
