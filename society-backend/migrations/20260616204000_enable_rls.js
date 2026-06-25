/**
 * Postgres Row-Level Security (RLS) — defense-in-depth tenant isolation.
 *
 * For each tenant table we ENABLE (not FORCE) RLS and add a `tenant_isolation`
 * policy scoping rows to current_setting('app.society_id'). ENABLE keeps the
 * table-owner app role unrestricted (so the application keeps working without
 * setting the GUC), while non-owner roles are confined to their tenant — a
 * second line of defense behind the application's own society_id scoping.
 *
 * Every table is guarded with to_regclass so a not-yet-created table is skipped
 * rather than failing the whole migration. Policy creation is idempotent
 * (DROP POLICY IF EXISTS before CREATE).
 *
 * @param { import("knex").Knex } knex
 */
const TENANT_TABLES = [
  "complaints",
  "notices",
  "polls",
  "votes",
  "events",
  "meetings",
  "rules",
  "channels",
  "messages",
  "staff",
  "parking_slots",
  "parking_allocations",
  "assets",
  "units",
  "members",
  "invoices",
  "payments",
  "expenses",
  "outbox_events",
];

exports.up = async function (knex) {
  for (const table of TENANT_TABLES) {
    await knex.raw(
      `DO $$
       BEGIN
         IF to_regclass('public.${table}') IS NOT NULL THEN
           EXECUTE 'ALTER TABLE public.${table} ENABLE ROW LEVEL SECURITY';
           EXECUTE 'DROP POLICY IF EXISTS tenant_isolation ON public.${table}';
           EXECUTE 'CREATE POLICY tenant_isolation ON public.${table} '
                || 'USING (society_id = current_setting(''app.society_id'', true)) '
                || 'WITH CHECK (society_id = current_setting(''app.society_id'', true))';
         END IF;
       END $$;`
    );
  }
};

exports.down = async function (knex) {
  for (const table of TENANT_TABLES) {
    await knex.raw(
      `DO $$
       BEGIN
         IF to_regclass('public.${table}') IS NOT NULL THEN
           EXECUTE 'DROP POLICY IF EXISTS tenant_isolation ON public.${table}';
           EXECUTE 'ALTER TABLE public.${table} DISABLE ROW LEVEL SECURITY';
         END IF;
       END $$;`
    );
  }
};
