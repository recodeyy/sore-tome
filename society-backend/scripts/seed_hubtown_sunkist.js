/**
 * MR-013 demo seed — "Hubtown Sunkist" society (society_id: hubtown-sunkist).
 *
 * Richer demo fixture than seed_hubtown_sunmist.js (which is left untouched):
 *   - A Wing / Floor 14 / flat A-1402 for the primary demo resident
 *   - 3 residents + 1 admin (members), 1 guard (staff)
 *   - 4 notices, 2 polls (with options), 2 events
 *   - 3 invoices (one overdue with a late fee applied)
 *   - 3 complaints in different statuses (open / in_progress / resolved)
 *   - 2 amenities, 2 visitors (one pre-approved pending, one checked-in)
 *   - 2 vehicles and 1 active parking allocation for A-1402
 *   - parcels: skipped (no parcels table exists in this schema)
 *
 * Idempotent + transactional: re-running wipes this society's rows and
 * re-inserts them in one transaction. Only touches tables that exist.
 * Dev only.
 *
 *   node scripts/seed_hubtown_sunkist.js
 */
const { Client } = require("pg");

const SOC = "hubtown-sunkist";
const ADMIN_UID = "sunkist-admin-001";
const ADMIN_PHONE = "9876500001";
const RES_UID = "sunkist-res-001"; // primary demo resident — A-1402
const RES_PHONE = "9876500002";
const RES2_UID = "sunkist-res-002"; // A-1401
const RES3_UID = "sunkist-res-003"; // A-101
const GUARD_UID = "sunkist-guard-001";

const c = new Client({
  connectionString:
    process.env.DATABASE_URL || "postgres://sero:sero@localhost:5544/sero_dev",
});

let PRESENT = new Set();
const has = (t) => PRESENT.has(t);

async function loadTables() {
  const r = await c.query(`SELECT tablename FROM pg_tables WHERE schemaname='public'`);
  PRESENT = new Set(r.rows.map((x) => x.tablename));
}

async function wipe(societyId) {
  // Children before parents (FK order).
  const tables = [
    "notification_deliveries", "notifications", "device_tokens",
    "kyc_documents", "family_members", "committee_members",
    "parking_allocations", "vehicles", "parking_slots",
    "resident_visitors", "visitor_entries",
    "poll_options", "polls",
    "notices", "events",
    // parcels + domestic help (mobile revamp §8 / §7.3). Logs before helpers (FK).
    "domestic_help_logs", "domestic_helpers", "parcels",
    // payment-demo stack first: demo_payment_audits FKs payments+invoices,
    // booking_payments/webhook events are downstream of the finance rows.
    "demo_payment_audits", "payment_webhook_events", "booking_payments",
    "payment_allocations", "receipts", "payments", "invoice_lines", "invoices",
    "complaints",
    "amenities", "assets",
    "members", "staff",
    "unit_occupancies", "units", "floors", "blocks", "wings",
    "society_settings", "society_applications", "society_profiles",
  ];
  for (const t of tables) {
    if (has(t)) await c.query(`DELETE FROM ${t} WHERE society_id = $1`, [societyId]);
  }
}

async function main() {
  await c.connect();
  await loadTables();
  await c.query("BEGIN");
  try {
    await wipe(SOC);

    // ── Society profile / settings / application ────────────────────────────
    await c.query(
      `INSERT INTO society_profiles (society_id, name, registration_no, address)
       VALUES ($1,'Hubtown Sunkist','MH/CHS/2017/HSK','Hubtown Sunkist, LBS Marg, Kurla West, Mumbai 400070')`,
      [SOC]
    );
    if (has("society_settings")) {
      await c.query(
        `INSERT INTO society_settings (society_id, feature_flags)
         VALUES ($1,'{"ai":true,"payments":true,"visitors":true}'::jsonb)`,
        [SOC]
      );
    }
    if (has("society_applications")) {
      await c.query(
        `INSERT INTO society_applications (society_name, contact_email, status, society_id)
         VALUES ('Hubtown Sunkist','contact@hubtown-sunkist.test','approved',$1)`,
        [SOC]
      );
    }

    // ── Structure: A Wing (Floor 1, 14) + B Wing (Floor 1) ─────────────────
    const wingA = (await c.query(
      `INSERT INTO wings (society_id, name, position) VALUES ($1,'A',0) RETURNING id`, [SOC])).rows[0].id;
    const wingB = (await c.query(
      `INSERT INTO wings (society_id, name, position) VALUES ($1,'B',1) RETURNING id`, [SOC])).rows[0].id;
    const blockA = (await c.query(
      `INSERT INTO blocks (society_id, wing_id, name, position) VALUES ($1,$2,'Block A',0) RETURNING id`, [SOC, wingA])).rows[0].id;
    const blockB = (await c.query(
      `INSERT INTO blocks (society_id, wing_id, name, position) VALUES ($1,$2,'Block B',1) RETURNING id`, [SOC, wingB])).rows[0].id;

    const floors = {};
    for (const [wing, block, fl] of [[wingA, blockA, 1], [wingA, blockA, 14], [wingB, blockB, 1]]) {
      const f = await c.query(
        `INSERT INTO floors (society_id, block_id, label, position) VALUES ($1,$2,$3,$4) RETURNING id`,
        [SOC, block, `Floor ${fl}`, fl]
      );
      floors[`${wing}-${fl}`] = f.rows[0].id;
    }

    const unitIds = {};
    const unitSpecs = [
      [wingA, blockA, 14, "A-1402", "2bhk", "owned", "occupied"],       // primary resident
      [wingA, blockA, 14, "A-1401", "2bhk", "rented", "occupied"],
      [wingA, blockA, 1, "A-101", "1bhk", "owned", "occupied"],
      [wingB, blockB, 1, "B-101", "1bhk", "vacant", "vacant"],
    ];
    for (const [w, b, fl, num, utype, own, occ] of unitSpecs) {
      const u = await c.query(
        `INSERT INTO units (society_id, wing_id, block_id, floor_id, number, unit_type, ownership_status, occupancy_status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
        [SOC, w, b, floors[`${w}-${fl}`], num, utype, own, occ]
      );
      unitIds[num] = u.rows[0].id;
    }

    // ── Members (admin + 3 residents) + staff (guard) ───────────────────────
    await c.query(
      `INSERT INTO members (society_id, user_id, name, phone, email, unit_id, status, role)
       VALUES
        ($1,$2,'Sunkist Main Admin',$3,'admin@hubtown-sunkist.test',NULL,'approved','main_admin'),
        ($1,$4,'Avinash (A-1402)',$5,'avinash@hubtown-sunkist.test',$6,'approved','resident'),
        ($1,$7,'Priya Sharma (A-1401)','9876500003','priya@hubtown-sunkist.test',$8,'approved','resident'),
        ($1,$9,'Rahul Mehta (A-101)','9876500004','rahul@hubtown-sunkist.test',$10,'approved','resident')`,
      [SOC, ADMIN_UID, ADMIN_PHONE, RES_UID, RES_PHONE, unitIds["A-1402"],
       RES2_UID, unitIds["A-1401"], RES3_UID, unitIds["A-101"]]
    );
    await c.query(
      `INSERT INTO staff (society_id, user_id, name, phone, role, department, status, assigned_areas)
       VALUES ($1,$2,'Bahadur (Gate Guard)','9876500005','guard','security','active',ARRAY['Main Gate'])`,
      [SOC, GUARD_UID]
    );

    // ── 4 notices ────────────────────────────────────────────────────────────
    await c.query(
      `INSERT INTO notices (society_id, title, body, type, priority, status, author_name, published_at)
       VALUES
        ($1,'Water supply maintenance','Water supply interrupted Sat 10am-2pm for tank cleaning.','general','high','published','Admin', now() - interval '3 day'),
        ($1,'Ganesh Chaturthi celebration','Celebrations at the clubhouse; volunteers welcome.','event','medium','published','Admin', now() - interval '2 day'),
        ($1,'Lift B annual servicing','Lift B unavailable Tuesday 9am-1pm.','general','medium','published','Admin', now() - interval '1 day'),
        ($1,'New visitor parking rules','Visitor parking limited to 4 hours; register at the gate.','general','low','published','Admin', now())`,
      [SOC]
    );

    // ── 2 polls with options ─────────────────────────────────────────────────
    for (const [title, desc, opts] of [
      ["Repaint society exterior?", "Vote on the proposed exterior repainting this winter.", ["Yes", "No", "Abstain"]],
      ["Install EV chargers in basement?", "Two fast chargers, cost shared via sinking fund.", ["Approve", "Reject", "Need more info"]],
    ]) {
      const p = await c.query(
        `INSERT INTO polls (society_id, title, description, status, created_by, starts_at, ends_at)
         VALUES ($1,$2,$3,'open',$4, now() - interval '1 day', now() + interval '7 day') RETURNING id`,
        [SOC, title, desc, ADMIN_UID]
      );
      for (let i = 0; i < opts.length; i++) {
        await c.query(
          `INSERT INTO poll_options (society_id, poll_id, label, position) VALUES ($1,$2,$3,$4)`,
          [SOC, p.rows[0].id, opts[i], i]
        );
      }
    }

    // ── 2 events ─────────────────────────────────────────────────────────────
    await c.query(
      `INSERT INTO events (society_id, title, description, location, starts_at, ends_at, capacity, status, created_by)
       VALUES
        ($1,'Society Annual Day','Cultural evening with dinner','Clubhouse', now() + interval '10 day', now() + interval '10 day' + interval '4 hour', 200,'published',$2),
        ($1,'Yoga Workshop','Morning yoga for all age groups','Garden Lawn', now() + interval '3 day', now() + interval '3 day' + interval '2 hour', 40,'published',$2)`,
      [SOC, ADMIN_UID]
    );

    // ── 3 invoices for A-1402 (one overdue with late fee) ───────────────────
    const resMember = (await c.query(
      `SELECT id FROM members WHERE society_id=$1 AND user_id=$2`, [SOC, RES_UID])).rows[0].id;
    await c.query(
      `INSERT INTO invoices (society_id, number, unit_id, member_id, period, status, subtotal_minor, tax_minor, total_minor, due_date, published_at, created_by, late_fee_minor, late_fee_applied_at)
       VALUES
        ($1,'INV-SK-001',$2,$3,'2026-05','published',450000,81000,531000, current_date - 35, now() - interval '40 day', $4, 25000, now() - interval '5 day'),
        ($1,'INV-SK-002',$2,$3,'2026-06','published',450000,81000,531000, current_date - 5, now() - interval '10 day', $4, 0, NULL),
        ($1,'INV-SK-003',$2,$3,'2026-07','published',450000,81000,531000, current_date + 10, now(), $4, 0, NULL)`,
      [SOC, unitIds["A-1402"], resMember, ADMIN_UID]
    );

    // ── 3 complaints (open / in_progress / resolved) ─────────────────────────
    await c.query(
      `INSERT INTO complaints (society_id, ref, title, description, priority, status, created_by, unit_id, sla_config, due_at, first_response_at, resolved_at, resolution_note, assigned_to)
       VALUES
        ($1,'CMP-1001','Lift A making noise','Grinding noise between floors 10-14','high','open',$2,$3,'{"minutes":1440}'::jsonb, now() + interval '1 day', NULL, NULL, NULL, NULL),
        ($1,'CMP-1002','Water seepage in A-1402','Ceiling seepage in master bedroom','medium','in_progress',$2,$3,'{"minutes":2880}'::jsonb, now() + interval '2 day', now() - interval '1 day', NULL, NULL, $4),
        ($1,'CMP-1003','Corridor light flickering','14th floor corridor light flickers at night','low','resolved',$2,$3,'{"minutes":4320}'::jsonb, now() - interval '1 day', now() - interval '3 day', now() - interval '1 day','Replaced LED driver', $4)`,
      [SOC, RES_UID, unitIds["A-1402"], GUARD_UID]
    );

    // ── 2 amenities ──────────────────────────────────────────────────────────
    await c.query(
      `INSERT INTO amenities (society_id, name, capacity, requires_approval)
       VALUES ($1,'Gym',30,false), ($1,'Clubhouse',120,true)`,
      [SOC]
    );

    // ── 2 visitors: one pre-approved pending, one checked-in ────────────────
    if (has("resident_visitors")) {
      await c.query(
        `INSERT INTO resident_visitors (society_id, unit_id, member_id, created_by, visitor_name, visitor_phone, purpose, status, expected_at, expires_at)
         VALUES ($1,$2,$3,$4,'Suresh Kumar (Guest)','9822200001','guest','pending', now() + interval '4 hour', now() + interval '1 day')`,
        [SOC, unitIds["A-1402"], resMember, RES_UID]
      );
    }
    await c.query(
      `INSERT INTO visitor_entries (society_id, name, phone, purpose, unit_id, status, checked_in_at, guard_id)
       VALUES
        ($1,'Suresh Kumar (Guest)','9822200001','guest',$2,'expected',NULL,$3),
        ($1,'Amazon Delivery','9822200002','delivery',$2,'checked_in', now() - interval '30 minute',$3)`,
      [SOC, unitIds["A-1402"], GUARD_UID]
    );

    // ── 2 vehicles + parking slot + 1 active allocation for A-1402 ──────────
    await c.query(
      `INSERT INTO vehicles (society_id, plate, type, unit_id, owner_id, make_model)
       VALUES
        ($1,'MH03SK1402','car',$2,$3,'Hyundai Creta'),
        ($1,'MH03SK9999','bike',$2,$3,'TVS Jupiter')`,
      [SOC, unitIds["A-1402"], RES_UID]
    );
    const slot = (await c.query(
      `INSERT INTO parking_slots (society_id, code, type, location, status)
       VALUES ($1,'P-SK-A01','car','Wing A Basement','allocated') RETURNING id`,
      [SOC])).rows[0].id;
    await c.query(
      `INSERT INTO parking_slots (society_id, code, type, location, status)
       VALUES ($1,'P-SK-A02','car','Wing A Basement','available'), ($1,'P-SK-2W01','bike','Two-wheeler Zone','available')`,
      [SOC]
    );
    const vehicle = (await c.query(
      `SELECT id FROM vehicles WHERE society_id=$1 AND plate='MH03SK1402'`, [SOC])).rows[0].id;
    await c.query(
      `INSERT INTO parking_allocations (society_id, slot_id, vehicle_id, unit_id, allocated_to, allocated_by, status)
       VALUES ($1,$2,$3,$4,$5,$6,'active')`,
      [SOC, slot, vehicle, unitIds["A-1402"], RES_UID, ADMIN_UID]
    );

    // ── Parcels (§8): one pending (with OTP) + one collected, for A-1402 ─────
    if (has("parcels")) {
      await c.query(
        `INSERT INTO parcels (society_id, unit_id, recipient_name, courier, description, status, otp, logged_by)
         VALUES ($1,$2,'Avinash (A-1402)','Amazon','Electronics box','pending','482913',$3),
                ($1,$2,'Avinash (A-1402)','Swiggy','Food order','collected',NULL,$3)`,
        [SOC, unitIds["A-1402"], GUARD_UID]
      );
    }

    // ── Domestic help (§7.3): a maid for A-1402 with one check-in log ────────
    if (has("domestic_helpers")) {
      const helper = (await c.query(
        `INSERT INTO domestic_helpers (society_id, unit_id, member_id, created_by, name, phone, helper_type, schedule, access_status)
         VALUES ($1,$2,$3,$4,'Sunita Devi','9876512345','maid','{"days":["Mon","Tue","Wed","Thu","Fri","Sat"],"from":"08:00","to":"11:00"}'::jsonb,'active')
         RETURNING id`,
        [SOC, unitIds["A-1402"], resMember, RES_UID]
      )).rows[0].id;
      if (has("domestic_help_logs")) {
        await c.query(
          `INSERT INTO domestic_help_logs (society_id, helper_id, unit_id, action, guard_id, at)
           VALUES ($1,$2,$3,'check_in',$4, now() - interval '3 hour'),
                  ($1,$2,$3,'check_out',$4, now() - interval '1 hour')`,
          [SOC, helper, unitIds["A-1402"], GUARD_UID]
        );
      }
    }

    await c.query("COMMIT");

    // ── Verification: per-table row counts ──────────────────────────────────
    const countTables = [
      "society_profiles", "wings", "floors", "units", "members", "staff",
      "notices", "polls", "poll_options", "events", "invoices", "complaints",
      "amenities", "visitor_entries", "resident_visitors", "vehicles",
      "parking_slots", "parking_allocations", "parcels", "domestic_helpers",
    ];
    const counts = {};
    for (const t of countTables) {
      if (!has(t)) { counts[t] = "n/a"; continue; }
      const r = await c.query(`SELECT count(*)::int n FROM ${t} WHERE society_id=$1`, [SOC]);
      counts[t] = r.rows[0].n;
    }
    console.log(`SEEDED ${SOC}:`, JSON.stringify(counts));
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
