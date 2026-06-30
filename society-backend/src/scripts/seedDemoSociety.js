/**
 * Reusable demo-society seed that runs against a provided pg client (so it can
 * execute INSIDE a transaction from an API handler against ANY environment,
 * including production Cloud SQL — used by the guarded super-admin
 * `POST /super-admin/seed-demo` endpoint).
 *
 * Idempotent: deletes this seed's rows for the target society, then re-inserts.
 * Only touches tables that exist. Re-creates the admin + resident MEMBER rows
 * for the given uids so the existing login→workspace resolution keeps working.
 */

async function loadTables(client) {
  const r = await client.query(
    `SELECT tablename FROM pg_tables WHERE schemaname='public'`
  );
  return new Set(r.rows.map((x) => x.tablename));
}

async function wipe(client, has, societyId) {
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
    if (has(t)) await client.query(`DELETE FROM ${t} WHERE society_id = $1`, [societyId]);
  }
}

/**
 * @param client  pg client/pool (must support .query)
 * @param opts    { societyId, name, regNo, address, adminUid, adminName, adminPhone,
 *                  resUid, resName, resPhone, resUnitNumber }
 */
async function seedDemoSociety(client, opts) {
  const {
    societyId, name, regNo, address,
    adminUid, adminName, adminPhone,
    resUid, resName, resPhone, resUnitNumber,
  } = opts;

  const PRESENT = await loadTables(client);
  const has = (t) => PRESENT.has(t);

  await wipe(client, has, societyId);

  // 1. Society profile + settings + application
  if (has("society_profiles")) {
    await client.query(
      `INSERT INTO society_profiles (society_id, name, registration_no, address) VALUES ($1,$2,$3,$4)`,
      [societyId, name, regNo, address]
    );
  }
  if (has("society_settings")) {
    await client.query(
      `INSERT INTO society_settings (society_id, feature_flags)
       VALUES ($1, '{"ai":true,"payments":true,"visitors":true}'::jsonb)`,
      [societyId]
    );
  }
  if (has("society_applications")) {
    await client.query(
      `INSERT INTO society_applications (society_name, contact_email, status, society_id)
       VALUES ($1,$2,'approved',$3)`,
      [name, `contact@${societyId}.test`, societyId]
    );
  }

  // 2. Structure: wings -> blocks -> floors -> units
  let resUnitId = null;
  if (has("wings") && has("units")) {
    const wingIds = {}, blockIds = {};
    for (const [wn, pos] of [["A", 0], ["B", 1]]) {
      const w = await client.query(
        `INSERT INTO wings (society_id, name, position) VALUES ($1,$2,$3) RETURNING id`,
        [societyId, wn, pos]
      );
      wingIds[wn] = w.rows[0].id;
      if (has("blocks")) {
        const b = await client.query(
          `INSERT INTO blocks (society_id, wing_id, name, position) VALUES ($1,$2,$3,$4) RETURNING id`,
          [societyId, wingIds[wn], `Block ${wn}`, pos]
        );
        blockIds[wn] = b.rows[0].id;
      }
    }
    const floorIds = {};
    for (const wn of ["A", "B"]) {
      for (const fl of [1, 2, 14]) {
        if (has("floors") && blockIds[wn]) {
          const f = await client.query(
            `INSERT INTO floors (society_id, block_id, label, position) VALUES ($1,$2,$3,$4) RETURNING id`,
            [societyId, blockIds[wn], `Floor ${fl}`, fl]
          );
          floorIds[`${wn}-${fl}`] = f.rows[0].id;
        }
      }
    }
    const unitSpecs = [
      ["A", 14, resUnitNumber, "2bhk", "owned", "occupied", true],
      ["A", 14, "A-1401", "2bhk", "rented", "occupied", false],
      ["A", 1, "A-101", "1bhk", "owned", "occupied", false],
      ["A", 2, "A-201", "3bhk", "jointly_owned", "occupied", false],
      ["B", 1, "B-101", "1bhk", "rented", "occupied", false],
      ["B", 2, "B-201", "2bhk", "vacant", "vacant", false],
      ["B", 14, "B-1402", "3bhk", "owned", "occupied", false],
    ];
    for (const [wn, fl, num, utype, own, occ, isRes] of unitSpecs) {
      const u = await client.query(
        `INSERT INTO units (society_id, wing_id, block_id, floor_id, number, unit_type, ownership_status, occupancy_status)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
        [societyId, wingIds[wn], blockIds[wn] || null, floorIds[`${wn}-${fl}`] || null, num, utype, own, occ]
      );
      if (isRes) resUnitId = u.rows[0].id;
    }
  }

  // 3. Members + staff (admin/treasurer/secretary committee + residents; guard/security/maintenance)
  if (has("members")) {
    await client.query(
      `INSERT INTO members (society_id, user_id, name, phone, email, unit_id, status, role)
       VALUES
        ($1,$2,$3,$4,$5,NULL,'approved','main_admin'),
        ($1,$6,$7,$8,$9,$10,'approved','resident'),
        ($1,'treasurer-001','Treasurer Tina','9000000010','treasurer@demo.test',NULL,'approved','treasurer'),
        ($1,'secretary-001','Secretary Sam','9000000011','secretary@demo.test',NULL,'approved','secretary'),
        ($1,'resident-002','Resident Rohit (A-101)','9000000020','rohit@demo.test',NULL,'approved','resident')`,
      [societyId, adminUid, adminName, adminPhone, `admin@${societyId}.test`,
       resUid, resName, resPhone, `resident@${societyId}.test`, resUnitId]
    );
  }
  if (has("staff")) {
    await client.query(
      `INSERT INTO staff (society_id, user_id, name, phone, role, department, status, assigned_areas)
       VALUES
        ($1,$2,'Ramesh (Gate Guard)','9000000001','guard','security','active',ARRAY['Main Gate']),
        ($1,'security-mgr-001','Security Manager Suresh','9000000002','security_manager','security','active',ARRAY['Main Gate','Service Gate']),
        ($1,'maintenance-001','Maintenance Mohan','9000000003','maintenance','facilities','active',ARRAY['Lift','Pump'])`,
      [societyId, `${societyId}-guard-001`]
    );
  }

  // 4. Family + KYC for the resident
  let resMemberId = null;
  if (has("members")) {
    const rm = await client.query(`SELECT id FROM members WHERE society_id=$1 AND user_id=$2`, [societyId, resUid]);
    resMemberId = rm.rows[0] && rm.rows[0].id;
  }
  if (resMemberId && has("family_members")) {
    await client.query(
      `INSERT INTO family_members (society_id, member_id, name, relation, phone, is_emergency_contact)
       VALUES ($1,$2,'Family Member (Tenant)','spouse','9000000021',true)`,
      [societyId, resMemberId]
    );
  }
  if (resMemberId && has("kyc_documents")) {
    await client.query(
      `INSERT INTO kyc_documents (society_id, member_id, doc_type, status)
       VALUES ($1,$2,'aadhaar','approved'),($1,$2,'pan','pending')`,
      [societyId, resMemberId]
    );
  }

  // 5. Amenities
  if (has("amenities")) {
    await client.query(
      `INSERT INTO amenities (society_id, name, capacity, requires_approval)
       VALUES ($1,'Gym',30,false),($1,'Clubhouse',100,true),($1,'Swimming Pool',40,false),($1,'Community Hall',150,true)`,
      [societyId]
    );
  }
  // 6. Assets
  if (has("assets")) {
    await client.query(
      `INSERT INTO assets (society_id, tag, name, type, location, status)
       VALUES
        ($1,'AST-LIFT-A','Wing A Lift','lift','Wing A','operational'),
        ($1,'AST-GEN-1','Diesel Generator','generator','Basement','operational'),
        ($1,'AST-PUMP-1','Water Pump','pump','Pump Room','operational'),
        ($1,'AST-CCTV-1','CCTV System','cctv','Main Gate','operational')`,
      [societyId]
    );
  }
  // 7. Parking + vehicles
  if (has("parking_slots")) {
    await client.query(
      `INSERT INTO parking_slots (society_id, code, type, location, is_ev, status)
       VALUES
        ($1,'P-A-01','car','Wing A Basement',false,'available'),
        ($1,'P-A-02','car','Wing A Basement',true,'available'),
        ($1,'P-B-01','car','Wing B Basement',false,'available'),
        ($1,'P-2W-01','bike','Two-wheeler Zone',false,'available')`,
      [societyId]
    );
  }
  if (has("vehicles") && resUnitId) {
    await client.query(
      `INSERT INTO vehicles (society_id, plate, type, unit_id, owner_id, make_model)
       VALUES ($1,'MH01AB1402','car',$2,$3,'Honda City'),($1,'MH01XY9999','bike',$2,$3,'Royal Enfield')`,
      [societyId, resUnitId, resUid]
    );
  }
  // 8. Visitors
  if (has("visitor_entries")) {
    await client.query(
      `INSERT INTO visitor_entries (society_id, name, phone, purpose, status)
       VALUES ($1,'Amazon Delivery','9011111111','delivery','expected'),($1,'Guest of A-1402','9022222222','guest','checked_in')`,
      [societyId]
    );
  }
  // 9. Poll + options
  if (has("polls") && has("poll_options")) {
    const p = await client.query(
      `INSERT INTO polls (society_id, title, description, status, created_by, starts_at, ends_at)
       VALUES ($1,'Repaint society exterior?','Vote on the proposed exterior repainting.','open',$2, now() - interval '1 day', now() + interval '7 day') RETURNING id`,
      [societyId, adminUid]
    );
    const pid = p.rows[0].id;
    await client.query(
      `INSERT INTO poll_options (society_id, poll_id, label, position)
       VALUES ($1,$2,'Yes',0),($1,$2,'No',1),($1,$2,'Abstain',2)`,
      [societyId, pid]
    );
  }

  // 10. Operational content: notices, events, invoices, complaints
  if (has("notices")) {
    await client.query(
      `INSERT INTO notices (society_id, title, body, type, priority, status, author_name, published_at)
       VALUES
        ($1,'Water supply maintenance','Water supply will be interrupted Sat 10am–2pm for tank cleaning.','general','high','published','Admin', now()),
        ($1,'Diwali celebration','Join the Diwali event at the clubhouse on Nov 1, 7pm.','event','medium','published','Admin', now()),
        ($1,'Parking rule update','Visitor parking now limited to 4 hours. Register at the gate.','general','medium','published','Admin', now())`,
      [societyId]
    );
  }
  if (has("events")) {
    await client.query(
      `INSERT INTO events (society_id, title, description, location, starts_at, ends_at, capacity, status, created_by)
       VALUES
        ($1,'Diwali Celebration','Festive evening with dinner','Clubhouse', now() + interval '7 day', now() + interval '7 day' + interval '3 hour', 200,'published',$2),
        ($1,'Society AGM','Annual general meeting','Community Hall', now() + interval '20 day', now() + interval '20 day' + interval '2 hour', 150,'published',$2)`,
      [societyId, adminUid]
    );
  }
  if (has("invoices")) {
    await client.query(
      `INSERT INTO invoices (society_id, number, period, status, subtotal_minor, tax_minor, total_minor, due_date, published_at, created_by)
       VALUES
        ($1,'INV-2026-001','2026-06','published',500000,90000,590000, current_date + 10, now(), $2),
        ($1,'INV-2026-002','2026-06','published',500000,90000,590000, current_date + 10, now(), $2)`,
      [societyId, adminUid]
    );
  }
  if (has("complaints")) {
    await client.query(
      `INSERT INTO complaints (society_id, ref, title, description, priority, status, created_by, sla_config)
       VALUES
        ($1,'CMP-001','Lift not working','B-wing lift stuck on 4th floor','high','open',$2,'{"minutes":1440}'::jsonb),
        ($1,'CMP-002','Garden lights out','Lights near block C are off at night','medium','in_progress',$2,'{"minutes":1440}'::jsonb)`,
      [societyId, adminUid]
    );
  }

  // Final counts for the response
  const countTables = [
    "society_profiles", "wings", "floors", "units", "members", "staff",
    "amenities", "assets", "parking_slots", "vehicles", "visitor_entries",
    "polls", "notices", "events", "invoices", "complaints",
  ];
  const counts = {};
  for (const t of countTables) {
    if (!has(t)) { counts[t] = "n/a"; continue; }
    const r = await client.query(`SELECT count(*)::int n FROM ${t} WHERE society_id=$1`, [societyId]);
    counts[t] = r.rows[0].n;
  }
  return { societyId, resUnitId, counts };
}

module.exports = { seedDemoSociety };
