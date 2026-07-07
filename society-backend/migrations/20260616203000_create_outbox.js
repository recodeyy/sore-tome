/**
 * Transactional OUTBOX event layer.
 * Business state mutations enqueue domain events into outbox_events inside the
 * SAME transaction, so events are committed atomically with the state change.
 * A separate publisher polls unpublished rows (FOR UPDATE SKIP LOCKED) and marks
 * them published. Every row is tenant-scoped by society_id.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("outbox_events", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("society_id").notNullable();
    t.text("topic").notNullable();
    t.text("type").notNullable();
    t.jsonb("payload").notNullable().defaultTo("{}");
    t.boolean("published").notNullable().defaultTo(false);
    t.timestamp("created_at").defaultTo(knex.fn.now());
    t.timestamp("published_at");
    t.index(["published", "created_at"]);
    t.index(["society_id", "topic"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("outbox_events");
};
