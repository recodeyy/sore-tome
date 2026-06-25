/**
 * Demo seed — "Hubtown Sunmist" society (+ an isolated "Hubtown Society B"),
 * fully linked so the admin + resident test accounts reach live data across every
 * screen and so list/filter/pagination, cross-role and tenant-isolation flows are
 * testable end to end.
 *
 * Idempotent + transactional: re-running deletes this seed's demo rows for both
 * societies and re-inserts them inside a single transaction. Only inserts into
 * tables that actually exist in the connected DB (skips missing tables gracefully).
 * Safe for dev only.
 *
 *   node scripts/seed_hubtown_sunmist.js
 */
const { Client } = require("pg");

// ── Society A (primary demo) ────────────────────────────────────────────────
const SOC = "hubtown-sunmist";
const ADMIN_UID = "admin-001";
const ADMIN_PHONE = "admin";
const RES_UID = "8Lm9vDSenHMyIqcJlHAv";
const RES_PHONE = "9876543200";

// ── Society B (tenant-isolation tests) ──────────────────────────────────────
const SOC_B = "hubtown-society-b";
const ADMIN_B_UID = "admin-b-001";
const ADMIN_B_PHONE = "9100000001";
const RES_B_UID = "resident-b-001";
const RES_B_PHONE = "9100000002";

const c = new Client({
  connectionString:
    process.env.DATABASE_URL || "postgres://sero:sero@localhost:5544/sero_dev",
});

// Tables present in this DB — populated at runtime so we can skip gracefully.
let PRESENT = new Set();
const has = (t) => PRESENT.has(t);

async function loadTables() {
  const r = await c.query(
    `SELECT tablename FROM pg_tables WHERE schemaname='public'`
  );
  PRESENT = new Set(r.rows.map((x) => x.tablename));
}

async function wipe(societyId) {
  // Order matters for FKs: children before parents.
  const tables = [
    "kyc_documents", "family_members", "committee_members",
    "vehicles", "parking_slots", "visitor_entries",
    "poll_options", "polls",
    "notices", "events", "invoices", "complaints",
    "amenities", "assets",
    "members", "staff",
    "units", "floors", "blocks", "wings",
    "society_settings", "society_applications", "society_profiles",
  ];
  for (const t of tables) {
    if (has(t)) {
      await c.query(`DELETE FROM ${t} WHERE society_id = $1`, [societyId]);
    }
  }
}

/** Seed the shared, society-level scaffolding for either society. */
async function seedSociety(opts) {
  const {
    societyId, name, regNo, address, applicationName, adminUid, adminPhone, adminName,
    resUid, resPhone, resName, resUnitNumber,
  } = opts;

  // 1. Society profile + settings + application (application drives societyName
  //    resolution in auth.getUserDestinations via a LEFT JOIN).
  if (has("society_profiles")) {
    await c.query(
      `INSERT INTO society_profiles (society_id, name, registration_no, address)
       VALUES ($1,$2,$3,$4)`,
      [societyId, name, regNo, address]
    );
  }
  if (has("society_settings")) {
    await c.query(
      `INSERT INTO society_settings (society_id, feature_flags)
       VALUES ($1, '{"ai":true,"payments":true,"visitors":true}'::jsonb)`,
      [societyId]
    );
  }
  if (has("society_applications")) {
    await c.query(
      `INSERT INTO society_applications (society_name, contact_email, status, society_id)
       VALUES ($1,$2,'approved',$3)`,
      [applicationName, `contact@${societyId}.test`, societyId]
    );
  }

  // 2. Structure: wings A & B -> blocks -> floors -> units. The schema models a
  //    wings -> blocks -> floors -> units hierarchy (floors.block_id and
  //    units.block_id FK to blocks). We create one block per wing (mirrors the
  //    wing) so the chain is consistent. Returns the resident's unit id.
  let resUnitId = null;
  if (has("wings") && has("units")) {
    const wingIds = {};
    const blockIds = {};
    for (const [wn, pos] of [["A", 0], ["B", 1]]) {
      const w = await c.query(
        `INSERT INTO wings (society_id, name, position) VALUES ($1,$2,$3) RETURNING id`,
        [societyId, wn, pos]
      );
      wingIds[wn] = w.rows[0].id;
      if (has("blocks")) {
        const b = await c.query(
          `INSERT INTO blocks (society_id, wing_id, name, position) VALUES ($1,$2,$3,$4) RETURNING id`,
          [societyId, wingIds[wn], `Block ${wn}`, pos]
        );
        blockIds[wn] = b.rows[0].id;
      }
    }

    // A few floors per wing so list/filter/pagination has depth.
    const floorIds = {}; // `${wing}-${floorNo}` -> id
    for (const wn of ["A", "B"]) {
      for (const fl of [1, 2, 14]) {
        if (has("floors") && blockIds[wn]) {
          const f = await c.query(
            `INSERT INTO floors (society_id, block_id, label, position)
             VALUES ($1,$2,$3,$4) RETURNING id`,
            [societyId, blockIds[wn], `Floor ${fl}`, fl]
          );
          floorIds[`${wn}-${fl}`] = f.rows[0].id;
        }
      }
    }

    // Units: enough rows across wings/floors to exercise filtering + pagination.
    // The resident's unit is renamed to A-1402 (wing A, floor 14, unit 1402).
    const unitSpecs = [
      ["A", 14, resUnitNumber, "2bhk", "owned", "occupied", true],   // resident (A-1402)
      ["A", 14, "A-1401", "2bhk", "rented", "occupied", false],
      ["A", 1,  "A-101",  "1bhk", "owned", "occupied", false],
      ["A", 2,  "A-201",  "3bhk", "jointly_owned", "occupied", false],
      ["B", 1,  "B-101",  "1bhk", "rented", "occupied", false],
      ["B", 2,  "B-201",  "2bhk", "vacant", "vacant", false],
      ["B", 14, "B-1402", "3bhk", "owned", "occupied", false],
    ];
    for (const [wn, fl, num, utype, own, occ, isRes] of unitSpecs) {
      const u = await c.query(
        `INSERT INTO units (society_id, wing_id, block_id, floor_id, number, unit_type, ownership_status, occupancy_status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
        [societyId, wingIds[wn], blockIds[wn] || null, floorIds[`${wn}-${fl}`] || null, num, utype, own, occ]
      );
      if (isRes) resUnitId = u.rows[0].id;
    }
  }

  // 3. Full role roster — members + staff.
  //    Admin committee (admin/treasurer/secretary) + residents as members;
  //    security manager / guard / maintenance as staff.
  if (has("members")) {
    await c.query(
      `INSERT INTO members (society_id, user_id, name, phone, email, unit_id, status, role)
       VALUES
        ($1,$2,$3,$4,$5,NULL,'approved','main_admin'),
        ($1,$6,$7,$8,$9,$10,'approved','resident')`,
      [societyId, adminUid, adminName, adminPhone, `admin@${societyId}.test`,
       resUid, resName, resPhone, `resident@${societyId}.test`, resUnitId]
    );
    // Extra committee + another resident (only for the primary society to keep B minimal).
    if (societyId === SOC) {
      await c.query(
        `INSERT INTO members (society_id, user_id, name, phone, email, status, role)
         VALUES
          ($1,'treasurer-001','Treasurer Tina','9000000010','treasurer@hubtown.test','approved','treasurer'),
          ($1,'secretary-001','Secretary Sam','9000000011','secretary@hubtown.test','approved','secretary'),
          ($1,'resident-002','Resident Rohit (A-101)','9000000020','rohit@hubtown.test','approved','resident')`,
        [societyId]
      );
    }
  }

  if (has("staff")) {
    await c.query(
      `INSERT INTO staff (society_id, user_id, name, phone, role, department, status, assigned_areas)
       VALUES ($1,$2,$3,$4,'guard','security','active',ARRAY['Main Gate'])`,
      [societyId, `${societyId}-guard-001`,
       societyId === SOC ? "Ramesh (Gate Guard)" : "Guard B", societyId === SOC ? "9000000001" : "9100000003"]
    );
    if (societyId === SOC) {
      await c.query(
        `INSERT INTO staff (society_id, user_id, name, phone, role, department, status, assigned_areas)
         VALUES
          ($1,'security-mgr-001','Security Manager Suresh','9000000002','security_manager','security','active',ARRAY['Main Gate','Service Gate']),
          ($1,'maintenance-001','Maintenance Mohan','9000000003','maintenance','facilities','active',ARRAY['Lift','Pump'])`,
        [societyId]
      );
    }
  }

  // 4. Family member / tenant for the resident (capability + KYC targets).
  let resMemberId = null;
  if (has("members")) {
    const rm = await c.query(
      `SELECT id FROM members WHERE society_id=$1 AND user_id=$2`, [societyId, resUid]
    );
    resMemberId = rm.rows[0] && rm.rows[0].id;
  }
  if (resMemberId && has("family_members")) {
    await c.query(
      `INSERT INTO family_members (society_id, member_id, name, relation, phone, is_emergency_contact)
       VALUES ($1,$2,$3,'spouse',$4,true)`,
      [societyId, resMemberId, "Family Member (Tenant)", societyId === SOC ? "9000000021" : "9100000004"]
    );
  }
  if (resMemberId && has("kyc_documents")) {
    await c.query(
      `INSERT INTO kyc_documents (society_id, member_id, doc_type, status)
       VALUES
        ($1,$2,'aadhaar','approved'),
        ($1,$2,'pan','pending')`,
      [societyId, resMemberId]
    );
  }

  // 5. Amenities (Gym, Clubhouse, Swimming Pool, Community Hall).
  if (has("amenities")) {
    await c.query(
      `INSERT INTO amenities (society_id, name, capacity, requires_approval)
       VALUES
        ($1,'Gym',30,false),
        ($1,'Clubhouse',100,true),
        ($1,'Swimming Pool',40,false),
        ($1,'Community Hall',150,true)`,
      [societyId]
    );
  }

  // 6. Assets (Lift, Generator, Pump, CCTV). No `gates`/`parcels` tables exist in
  //    this schema — those are intentionally skipped.
  if (has("assets")) {
    await c.query(
      `INSERT INTO assets (society_id, tag, name, type, location, status)
       VALUES
        ($1,'AST-LIFT-A','Wing A Lift','lift','Wing A','operational'),
        ($1,'AST-GEN-1','Diesel Generator','generator','Basement','operational'),
        ($1,'AST-PUMP-1','Water Pump','pump','Pump Room','operational'),
        ($1,'AST-CCTV-1','CCTV System','cctv','Main Gate','operational')`,
      [societyId]
    );
  }

  // 7. Parking slots (and a vehicle for the resident).
  if (has("parking_slots")) {
    await c.query(
      `INSERT INTO parking_slots (society_id, code, type, location, is_ev, status)
       VALUES
        ($1,'P-A-01','car','Wing A Basement',false,'available'),
        ($1,'P-A-02','car','Wing A Basement',true,'available'),
        ($1,'P-B-01','car','Wing B Basement',false,'available'),
        ($1,'P-2W-01','bike','Two-wheeler Zone',false,'available')`,
      [societyId]
    );
  }
  if (has("vehicles")) {
    await c.query(
      `INSERT INTO vehicles (society_id, plate, type, unit_id, owner_id, make_model)
       VALUES
        ($1,$2,'car',$3,$4,'Honda City'),
        ($1,$5,'bike',$3,$4,'Royal Enfield')`,
      [societyId,
       societyId === SOC ? "MH01AB1402" : "MH02CD0001", resUnitId, resUid,
       societyId === SOC ? "MH01XY9999" : "MH02EF0002"]
    );
  }

  // 8. Visitors (gate log).
  if (has("visitor_entries")) {
    await c.query(
      `INSERT INTO visitor_entries (society_id, name, phone, purpose, status)
       VALUES
        ($1,'Amazon Delivery','9011111111','delivery','expected'),
        ($1,'Guest of A-1402','9022222222','guest','checked_in')`,
      [societyId]
    );
  }

  // 9. Poll with options.
  if (has("polls") && has("poll_options")) {
    const p = await c.query(
      `INSERT INTO polls (society_id, title, description, status, created_by, starts_at, ends_at)
       VALUES ($1,$2,$3,'open',$4, now() - interval '1 day', now() + interval '7 day') RETURNING id`,
      [societyId, "Repaint society exterior?", "Vote on the proposed exterior repainting.", adminUid]
    );
    const pid = p.rows[0].id;
    await c.query(
      `INSERT INTO poll_options (society_id, poll_id, label, position)
       VALUES ($1,$2,'Yes',0),($1,$2,'No',1),($1,$2,'Abstain',2)`,
      [societyId, pid]
    );
  }

  return { resUnitId };
}

/** Per-society operational content: notices, events, invoices, complaints. */
async function seedContent(societyId, adminUid) {
  if (has("notices")) {
    await c.query(
      `INSERT INTO notices (society_id, title, body, type, priority, status, author_name, published_at)
       VALUES
        ($1,'Water supply maintenance','Water supply will be interrupted Sat 10am–2pm for tank cleaning.','general','high','published','Admin', now()),
        ($1,'Diwali celebration','Join the Diwali event at the clubhouse on Nov 1, 7pm.','event','medium','published','Admin', now()),
        ($1,'Parking rule update','Visitor parking now limited to 4 hours. Register at the gate.','general','medium','published','Admin', now())`,
      [societyId]
    );
  }
  if (has("events")) {
    await c.query(
      `INSERT INTO events (society_id, title, description, location, starts_at, ends_at, capacity, status, created_by)
       VALUES
        ($1,'Diwali Celebration','Festive evening with dinner','Clubhouse', now() + interval '7 day', now() + interval '7 day' + interval '3 hour', 200,'published',$2),
        ($1,'Society AGM','Annual general meeting','Community Hall', now() + interval '20 day', now() + interval '20 day' + interval '2 hour', 150,'published',$2)`,
      [societyId, adminUid]
    );
  }
  if (has("invoices")) {
    await c.query(
      `INSERT INTO invoices (society_id, number, period, status, subtotal_minor, tax_minor, total_minor, due_date, published_at, created_by)
       VALUES
        ($1,'INV-2026-001','2026-06','published',500000,90000,590000, current_date + 10, now(), $2),
        ($1,'INV-2026-002','2026-06','published',500000,90000,590000, current_date + 10, now(), $2)`,
      [societyId, adminUid]
    );
  }
  if (has("complaints")) {
    await c.query(
      `INSERT INTO complaints (society_id, ref, title, description, priority, status, created_by, sla_config)
       VALUES
        ($1,'CMP-001','Lift not working','B-wing lift stuck on 4th floor','high','open',$2,'{"minutes":1440}'::jsonb),
        ($1,'CMP-002','Garden lights out','Lights near block C are off at night','medium','in_progress',$2,'{"minutes":1440}'::jsonb)`,
      [societyId, adminUid]
    );
  }
}

async function main() {
  await c.connect();
  await loadTables();
  await c.query("BEGIN");
  try {
    // Idempotent re-seed for both societies.
    await wipe(SOC);
    await wipe(SOC_B);

    // Society A — full fixture.
    await seedSociety({
      societyId: SOC, name: "Hubtown Sunmist", regNo: "MH/CHS/2016/HSM",
      address: "Hubtown Sunmist, Andheri East, Mumbai 400069",
      applicationName: "Hubtown Sunmist",
      adminUid: ADMIN_UID, adminPhone: ADMIN_PHONE, adminName: "Society Main Admin",
      resUid: RES_UID, resPhone: RES_PHONE, resName: "Avinash (A-1402)", resUnitNumber: "A-1402",
    });
    await seedContent(SOC, ADMIN_UID);

    // Society B — minimal, isolated tenant for cross-society isolation tests.
    await seedSociety({
      societyId: SOC_B, name: "Hubtown Society B", regNo: "MH/CHS/2018/HSB",
      address: "Hubtown Society B, Powai, Mumbai 400076",
      applicationName: "Hubtown Society B",
      adminUid: ADMIN_B_UID, adminPhone: ADMIN_B_PHONE, adminName: "Society B Admin",
      resUid: RES_B_UID, resPhone: RES_B_PHONE, resName: "Resident B (B-1401)", resUnitNumber: "B-1401",
    });
    await seedContent(SOC_B, ADMIN_B_UID);

    await c.query("COMMIT");

    // Final per-table row counts for both societies.
    const countTables = [
      "society_profiles", "society_applications", "wings", "floors", "units",
      "members", "staff", "family_members", "kyc_documents",
      "amenities", "assets", "parking_slots", "vehicles", "visitor_entries",
      "polls", "poll_options", "notices", "events", "invoices", "complaints",
    ];
    for (const soc of [SOC, SOC_B]) {
      const counts = {};
      for (const t of countTables) {
        if (!has(t)) { counts[t] = "n/a"; continue; }
        const r = await c.query(`SELECT count(*)::int n FROM ${t} WHERE society_id=$1`, [soc]);
        counts[t] = r.rows[0].n;
      }
      console.log(`SEEDED ${soc}:`, JSON.stringify(counts));
    }
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
