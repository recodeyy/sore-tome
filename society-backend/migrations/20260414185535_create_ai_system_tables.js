/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function(knex) {
  const hasAuditLogs = await knex.schema.hasTable('ai_audit_logs');
  if (!hasAuditLogs) {
    await knex.schema.createTable('ai_audit_logs', function(table) {
      table.increments('id').primary();
      table.uuid('action_id').defaultTo(knex.raw('gen_random_uuid()'));
      table.string('tool_id', 100);
      table.string('user_id', 255);
      table.string('society_id', 255);
      table.string('action', 100);
      table.jsonb('params');
      table.string('status', 50); 
      table.text('error_message');
      table.timestamp('created_at').defaultTo(knex.fn.now());
      table.timestamp('expires_at').defaultTo(knex.raw("CURRENT_TIMESTAMP + INTERVAL '10 minutes'"));
      
      table.index('society_id', 'idx_ai_audit_society');
      table.index('user_id', 'idx_ai_audit_user');
    });
  }

  const hasCosts = await knex.schema.hasTable('ai_costs');
  if (!hasCosts) {
    await knex.schema.createTable('ai_costs', function(table) {
      table.increments('id').primary();
      table.string('user_id', 255).notNullable();
      table.string('society_id', 255).notNullable();
      table.string('request_id', 255).notNullable();
      table.integer('tokens');
      table.decimal('cost_usd', 15, 6);
      table.timestamp('created_at').defaultTo(knex.fn.now());

      table.index('society_id', 'idx_ai_costs_society');
      table.index(['society_id', 'created_at'], 'idx_ai_costs_lookup');
    });
  }
};


/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema
    .dropTableIfExists('ai_costs')
    .dropTableIfExists('ai_audit_logs');
};
