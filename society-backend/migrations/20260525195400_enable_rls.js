/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function(knex) {
  // Enable Row Level Security (RLS) on the tables
  await knex.raw('ALTER TABLE document_chunks ENABLE ROW LEVEL SECURITY;');
  await knex.raw('ALTER TABLE ai_audit_logs ENABLE ROW LEVEL SECURITY;');
  await knex.raw('ALTER TABLE ai_costs ENABLE ROW LEVEL SECURITY;');
  await knex.raw('ALTER TABLE ai_audit_logs_partitioned ENABLE ROW LEVEL SECURITY;');

  // Create Policies using current_setting('app.current_tenant')
  await knex.raw(`
    CREATE POLICY tenant_isolation_policy_chunks ON document_chunks 
    USING (society_id = current_setting('app.current_tenant', true));
  `);
  await knex.raw(`
    CREATE POLICY tenant_isolation_policy_audit ON ai_audit_logs 
    USING (society_id = current_setting('app.current_tenant', true));
  `);
  await knex.raw(`
    CREATE POLICY tenant_isolation_policy_costs ON ai_costs 
    USING (society_id = current_setting('app.current_tenant', true));
  `);
  await knex.raw(`
    CREATE POLICY tenant_isolation_policy_audit_part ON ai_audit_logs_partitioned 
    USING (society_id = current_setting('app.current_tenant', true));
  `);
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function(knex) {
  // Drop policies
  await knex.raw('DROP POLICY IF EXISTS tenant_isolation_policy_chunks ON document_chunks;');
  await knex.raw('DROP POLICY IF EXISTS tenant_isolation_policy_audit ON ai_audit_logs;');
  await knex.raw('DROP POLICY IF EXISTS tenant_isolation_policy_costs ON ai_costs;');
  await knex.raw('DROP POLICY IF EXISTS tenant_isolation_policy_audit_part ON ai_audit_logs_partitioned;');

  // Disable RLS
  await knex.raw('ALTER TABLE document_chunks DISABLE ROW LEVEL SECURITY;');
  await knex.raw('ALTER TABLE ai_audit_logs DISABLE ROW LEVEL SECURITY;');
  await knex.raw('ALTER TABLE ai_costs DISABLE ROW LEVEL SECURITY;');
  await knex.raw('ALTER TABLE ai_audit_logs_partitioned DISABLE ROW LEVEL SECURITY;');
};
