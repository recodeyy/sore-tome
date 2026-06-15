/**
 * Phase 2 — Society structure (capabilities 11–16): wings, blocks/towers, floors,
 * units/flats, and unit occupancy history. Tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("wings", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("name").notNullable();
    t.integer("position").notNullable().defaultTo(0);
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
  });

  await knex.schema.createTable("blocks", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("wing_id").references("id").inTable("wings").onDelete("SET NULL");
    t.text("name").notNullable();
    t.integer("position").notNullable().defaultTo(0);
    t.boolean("is_active").notNullable().defaultTo(true);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "name"]);
    t.index(["society_id", "wing_id"]);
  });

  await knex.schema.createTable("floors", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("block_id").references("id").inTable("blocks").onDelete("CASCADE");
    t.text("label").notNullable(); // e.g. "G", "1", "12"
    t.integer("position").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "block_id"]);
  });

  await knex.schema.createTable("units", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("wing_id").references("id").inTable("wings").onDelete("SET NULL");
    t.uuid("block_id").references("id").inTable("blocks").onDelete("SET NULL");
    t.uuid("floor_id").references("id").inTable("floors").onDelete("SET NULL");
    t.text("number").notNullable(); // flat number, unique within society
    t.text("unit_type"); // 1BHK, 2BHK, shop, ...
    t.decimal("area_sqft", 10, 2);
    t.decimal("maintenance_weight", 10, 4).notNullable().defaultTo(1);
    t.enu("ownership_status", ["owned", "rented", "vacant", "jointly_owned"]).notNullable().defaultTo("vacant");
    t.enu("occupancy_status", ["occupied", "vacant"]).notNullable().defaultTo("vacant");
    t.boolean("is_active").notNullable().defaultTo(true);
    t.integer("version").notNullable().defaultTo(0);
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    t.unique(["society_id", "number"]);
    t.index(["society_id", "occupancy_status"]);
  });

  await knex.schema.createTable("unit_occupancies", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.uuid("unit_id").notNullable().references("id").inTable("units").onDelete("CASCADE");
    t.text("resident_id"); // user id
    t.enu("relation", ["owner", "tenant", "co_owner", "family"]).notNullable().defaultTo("owner");
    t.date("from_date").notNullable().defaultTo(knex.fn.now());
    t.date("to_date"); // null = current
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.index(["society_id", "unit_id"]);
  });
  // At most one CURRENT occupancy of a given relation per unit.
  await knex.raw(
    `CREATE UNIQUE INDEX unit_current_occupancy ON unit_occupancies (unit_id, relation) WHERE to_date IS NULL`
  );
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.raw(`DROP INDEX IF EXISTS unit_current_occupancy`);
  await knex.schema.dropTableIfExists("unit_occupancies");
  await knex.schema.dropTableIfExists("units");
  await knex.schema.dropTableIfExists("floors");
  await knex.schema.dropTableIfExists("blocks");
  await knex.schema.dropTableIfExists("wings");
};
