-- create_app_role.sql
-- Creates the production application role `sero_app`.
--
-- WHY: RLS policies in migrations/20260616204000_enable_rls.js use ENABLE (not
-- FORCE) ROW LEVEL SECURITY. Postgres NEVER enforces RLS for:
--   * superusers,
--   * roles with the BYPASSRLS attribute, and
--   * the table OWNER (under ENABLE, not FORCE).
-- Migrations are run by the owner/superuser (so the app can bootstrap and the
-- owner is unconstrained), but the APPLICATION must connect as a role that is
-- none of the above, so the tenant_isolation policies are actually enforced.
--
-- `sero_app` is therefore created NOSUPERUSER NOBYPASSRLS, is NOT the table
-- owner, and gets only the minimal DML grants. With this role, every tenant
-- table is scoped to current_setting('app.society_id') as set by the app.
--
-- Run as the database owner/superuser, AFTER migrations have been applied:
--   psql "$ADMIN_DATABASE_URL" -v app_password='<strong-secret>' \
--        -f scripts/create_app_role.sql

\set ON_ERROR_STOP on

-- 1. Role. NOSUPERUSER NOBYPASSRLS are the load-bearing attributes for RLS.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sero_app') THEN
    CREATE ROLE sero_app LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE;
  ELSE
    ALTER ROLE sero_app NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE;
  END IF;
END $$;

-- Set/rotate the password (pass via psql -v app_password=...).
ALTER ROLE sero_app WITH PASSWORD :'app_password';

-- 2. Minimal grants.
GRANT CONNECT ON DATABASE :"DBNAME" TO sero_app;   -- run with -v DBNAME=<db>
GRANT USAGE ON SCHEMA public TO sero_app;

-- DML on all existing tables (the app does not run DDL at runtime).
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO sero_app;

-- Sequences backing serial/identity PKs need USAGE+SELECT for INSERTs.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO sero_app;

-- 3. Make future tables/sequences (new migrations) inherit the same grants.
--    ALTER DEFAULT PRIVILEGES must name the role that CREATES the objects
--    (the migration owner). Replace `sero_owner` with that role if different.
ALTER DEFAULT PRIVILEGES FOR ROLE sero_owner IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO sero_app;
ALTER DEFAULT PRIVILEGES FOR ROLE sero_owner IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO sero_app;

-- 4. Verify (expected: rolbypassrls=f, rolsuper=f).
--   SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname='sero_app';
