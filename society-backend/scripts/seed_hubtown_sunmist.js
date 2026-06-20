/**
 * Demo seed — "Hubtown Sunmist" society, fully linked so the admin + resident
 * test accounts reach live data across every screen. Idempotent: re-running
 * replaces this society's demo rows. Safe for dev only.
 *
 *   node scripts/seed_hubtown_sunmist.js
 */
const { Client } = require("pg");

const SOC = "hubtown-sunmist";
const ADMIN_UID = "admin-001";
const ADMIN_PHONE = "admin";
const RES_UID = "8Lm9vDSenHMyIqcJlHAv";
const RES_PHONE = "9876543200";

const c = new Client({
  connectionString:
    process.env.DATABASE_URL || "postgres://sero:sero@localhost:5544/sero_dev",
});

async function main() {
  await c.connect();
  await c.query("BEGIN");
  try {
    // Clean prior demo rows for this society (idempotent re-seed).
    for (const t of [
      "notices",
      "events",
      "invoices",
      "complaints",
      "members",
      "staff",
      "society_settings",
      "society_profiles",
    ]) {
      await c.query(`DELETE FROM ${t} WHERE society_id = $1`, [SOC]);
    }

    // 1. Society profile + settings
    await c.query(
      `INSERT INTO society_profiles (society_id, name, registration_no, address)
       VALUES ($1,$2,$3,$4)`,
      [SOC, "Hubtown Sunmist", "MH/CHS/2016/HSM", "Hubtown Sunmist, Andheri East, Mumbai 400069"]
    );
    await c.query(
      `INSERT INTO society_settings (society_id, feature_flags)
       VALUES ($1, '{"ai":true,"payments":true,"visitors":true}'::jsonb)`,
      [SOC]
    );

    // 2. Members — admin + resident (active, linked to the login accounts)
    await c.query(
      `INSERT INTO members (society_id, user_id, name, phone, email, status, role)
       VALUES
        ($1,$2,'Society Main Admin',$3,'admin@hubtown.test','approved','main_admin'),
        ($1,$4,'Avinash (A-1204)',$5,'resident@hubtown.test','approved','resident')`,
      [SOC, ADMIN_UID, ADMIN_PHONE, RES_UID, RES_PHONE]
    );

    // Staff/Security member (for staff-portal load + loadtest-login by phone).
    await c.query(
      `INSERT INTO staff (society_id, user_id, name, phone, role, status)
       VALUES ($1,'staff-guard-001','Ramesh (Gate Guard)','9000000001','guard','active')`,
      [SOC]
    );

    // 3. Notices (published)
    await c.query(
      `INSERT INTO notices (society_id, title, body, type, priority, status, author_name, published_at)
       VALUES
        ($1,'Water supply maintenance','Water supply will be interrupted Sat 10am–2pm for tank cleaning.','general','high','published','Admin', now()),
        ($1,'Diwali celebration','Join the Diwali event at the clubhouse on Nov 1, 7pm.','event','medium','published','Admin', now()),
        ($1,'Parking rule update','Visitor parking now limited to 4 hours. Register at the gate.','general','medium','published','Admin', now())`,
      [SOC]
    );

    // 4. Events
    await c.query(
      `INSERT INTO events (society_id, title, description, location, starts_at, ends_at, capacity, status, created_by)
       VALUES
        ($1,'Diwali Celebration','Festive evening with dinner','Clubhouse', now() + interval '7 day', now() + interval '7 day' + interval '3 hour', 200,'published',$2),
        ($1,'Society AGM','Annual general meeting','Community Hall', now() + interval '20 day', now() + interval '20 day' + interval '2 hour', 150,'published',$2)`,
      [SOC, ADMIN_UID]
    );

    // 5. Invoices
    await c.query(
      `INSERT INTO invoices (society_id, number, period, status, subtotal_minor, tax_minor, total_minor, due_date, published_at, created_by)
       VALUES
        ($1,'INV-2026-001','2026-06','published',500000,90000,590000, current_date + 10, now(), $2),
        ($1,'INV-2026-002','2026-06','published',500000,90000,590000, current_date + 10, now(), $2)`,
      [SOC, ADMIN_UID]
    );

    // 6. Complaints
    await c.query(
      `INSERT INTO complaints (society_id, ref, title, description, priority, status, created_by, sla_config)
       VALUES
        ($1,'CMP-001','Lift not working','B-wing lift stuck on 4th floor','high','open',$2,'{"minutes":1440}'::jsonb),
        ($1,'CMP-002','Garden lights out','Lights near block C are off at night','medium','in_progress',$2,'{"minutes":1440}'::jsonb)`,
      [SOC, ADMIN_UID]
    );

    await c.query("COMMIT");
    const counts = {};
    for (const t of ["society_profiles", "members", "notices", "events", "invoices", "complaints"]) {
      const r = await c.query(`SELECT count(*)::int n FROM ${t} WHERE society_id=$1`, [SOC]);
      counts[t] = r.rows[0].n;
    }
    console.log("SEEDED hubtown-sunmist:", JSON.stringify(counts));
  } catch (e) {
    await c.query("ROLLBACK");
    throw e;
  } finally {
    await c.end();
  }
}

main().catch((e) => {
  console.error("SEED ERROR:", e.message);
  process.exit(1);
});
