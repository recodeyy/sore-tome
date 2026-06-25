/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function(knex) {
  // 1. Create the partitioned table using RAW SQL
  await knex.raw(`
    CREATE TABLE ai_audit_logs_partitioned (
      id UUID NOT NULL,
      action_id UUID NOT NULL,
      tool_id VARCHAR(100),
      user_id VARCHAR(255),
      society_id VARCHAR(255),
      action TEXT,
      params JSONB,
      status VARCHAR(50),
      error_message TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TIMESTAMP DEFAULT (CURRENT_TIMESTAMP + INTERVAL '10 minutes'),
      PRIMARY KEY (id, created_at),
      UNIQUE (id, created_at)
    ) PARTITION BY RANGE (created_at);
  `);

  // 2. Create monthly partitions for 2026
  const months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
  for (const month of months) {
    const nextMonth = month === '12' ? '01' : (parseInt(month) + 1).toString().padStart(2, '0');
    const year = '2026';
    const nextYear = month === '12' ? '2027' : '2026';
    
    await knex.raw(`
      CREATE TABLE ai_audit_logs_2026_${month} 
      PARTITION OF ai_audit_logs_partitioned 
      FOR VALUES FROM ('${year}-${month}-01') TO ('${nextYear}-${nextMonth}-01');
    `);
  }

  // 3. Create Default Partition for safety
  await knex.raw(`
    CREATE TABLE ai_audit_logs_default 
    PARTITION OF ai_audit_logs_partitioned DEFAULT;
  `);

  // 4. Add Indices to partitioned table (propagates to child tables)
  await knex.raw(`CREATE INDEX idx_audit_partitioned_society ON ai_audit_logs_partitioned (society_id);`);
  await knex.raw(`CREATE INDEX idx_audit_partitioned_user ON ai_audit_logs_partitioned (user_id);`);
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  return knex.schema.dropTableIfExists('ai_audit_logs_partitioned');
};
