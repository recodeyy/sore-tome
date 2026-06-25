# Deployment

## Row-Level Security (RLS) enforcement

Migration `migrations/20260616204000_enable_rls.js` puts a `tenant_isolation`
policy on every tenant table (complaints, notices, polls, votes, events,
meetings, rules, channels, messages, staff, parking_slots, parking_allocations,
assets, units, members, invoices, payments, expenses, outbox_events). Each
policy scopes rows to `current_setting('app.society_id', true)` via both `USING`
and `WITH CHECK`.

RLS is **ENABLED, not FORCED**. Postgres does not enforce RLS for:

- superusers,
- roles with `BYPASSRLS`, or
- the **table owner** (only `FORCE` constrains the owner).

So whether tenant isolation is actually enforced depends entirely on **which
role the app connects as**.

### Required production setup

1. **Run migrations as the owner/superuser.** Migrations create tables/policies
   and must own them. Use an admin `DATABASE_URL` for `npx knex migrate:latest`.

2. **Create the application role.** After migrations, run as the owner/superuser:

   ```bash
   psql "$ADMIN_DATABASE_URL" \
     -v app_password='<strong-secret>' \
     -v DBNAME='<your_db_name>' \
     -f scripts/create_app_role.sql
   ```

   This creates `sero_app` as `NOSUPERUSER NOBYPASSRLS`, not the table owner,
   with only `CONNECT` / schema `USAGE` / `SELECT,INSERT,UPDATE,DELETE` (plus
   sequence `USAGE,SELECT`). Under this role the policies are enforced.
   (Adjust the `sero_owner` name in the script's `ALTER DEFAULT PRIVILEGES`
   lines to the actual migration-owner role.)

3. **Point the app at `sero_app`.** In production the app's `DATABASE_URL` must
   use the `sero_app` credentials, **not** the admin/owner role:

   ```
   DATABASE_URL=postgres://sero_app:<strong-secret>@<host>:5432/<db>
   ```

   The app sets `app.society_id` per request, so `sero_app` only sees its
   tenant's rows; a missing/forged society id matches nothing.

### Verify enforcement

```sql
SELECT rolname, rolsuper, rolbypassrls
FROM pg_roles
WHERE rolname = 'sero_app';
-- Expected: rolsuper = f, rolbypassrls = f
```

If `rolbypassrls` (or `rolsuper`) is `t`, RLS is silently bypassed — fix the
role before going live. You can confirm the policies exist with:

```sql
SELECT tablename, policyname FROM pg_policies
WHERE policyname = 'tenant_isolation';
```
