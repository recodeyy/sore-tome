/**
 * Creates the pgvector-backed tables that were previously created implicitly
 * at runtime by LangChain (document_chunks) or by ad-hoc SQL (semantic_cache),
 * so a migration from an empty database succeeds.
 *
 * document_chunks intentionally omits society_id here; the existing later
 * migration (add_society_id_to_document_chunks) adds it.
 *
 * @param { import("knex").Knex } knex
 */
exports.up = async function (knex) {
  await knex.raw(`CREATE EXTENSION IF NOT EXISTS vector`);

  await knex.raw(`
    CREATE TABLE IF NOT EXISTS document_chunks (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      content text,
      metadata jsonb,
      vector vector,
      fts_content tsvector GENERATED ALWAYS AS (to_tsvector('english', coalesce(content, ''))) STORED,
      created_at timestamptz DEFAULT now()
    )
  `);

  await knex.raw(`
    CREATE TABLE IF NOT EXISTS semantic_cache (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      society_id text NOT NULL,
      query text NOT NULL,
      response text,
      embedding vector,
      created_at timestamptz DEFAULT now(),
      UNIQUE (society_id, query)
    )
  `);
};

/**
 * @param { import("knex").Knex } knex
 */
exports.down = async function (knex) {
  await knex.raw(`DROP TABLE IF EXISTS semantic_cache`);
  await knex.raw(`DROP TABLE IF EXISTS document_chunks`);
};
