/**
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.schema.createTable("ai_conversations", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.text("title").notNullable().defaultTo("New Conversation");
    t.text("user_id").notNullable();
    t.text("society_id").notNullable();
    t.boolean("is_archived").notNullable().defaultTo(false);
    t.text("language_preference").notNullable().defaultTo("english");
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());
    t.timestamp("updated_at").notNullable().defaultTo(knex.fn.now());
    
    t.index(["user_id", "society_id"]);
  });

  await knex.schema.createTable("ai_messages", (t) => {
    t.uuid("id").primary().defaultTo(knex.raw("gen_random_uuid()"));
    t.uuid("conversation_id")
      .notNullable()
      .references("id")
      .inTable("ai_conversations")
      .onDelete("CASCADE");
    t.text("role").notNullable(); // 'user' | 'assistant' | 'system'
    t.text("text_content").notNullable();
    t.jsonb("meta_json").notNullable().defaultTo(knex.raw("'{}'::jsonb"));
    t.timestamp("created_at").notNullable().defaultTo(knex.fn.now());

    t.index(["conversation_id"]);
  });
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.schema.dropTableIfExists("ai_messages");
  await knex.schema.dropTableIfExists("ai_conversations");
};
