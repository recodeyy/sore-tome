/**
 * Waits out the per-IP login rate limit, then logs in as staff / super-admin /
 * resident and probes each portal's endpoints. Writes a result table to
 * scripts/portal_test_results.txt. Node 24 global fetch.
 */
const fs = require("fs");
const BASE = "http://localhost:3001/api/v1";
const OUT = require("path").join(__dirname, "portal_test_results.txt");
const lines = [];
const log = (s) => { lines.push(s); console.log(s); fs.writeFileSync(OUT, lines.join("\n")); };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function login(phone, password, portal) {
  const res = await fetch(`${BASE}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ phone, password, portal }),
  });
  const j = await res.json().catch(() => ({}));
  const token = (j.data && j.data.token) || j.token || null;
  return { status: res.status, token, body: j };
}

async function probe(token, paths) {
  const out = [];
  for (const p of paths) {
    try {
      const r = await fetch(`${BASE}${p}`, { headers: { Authorization: `Bearer ${token}` } });
      out.push(`    ${p} [${r.status}]`);
    } catch (e) {
      out.push(`    ${p} [ERR ${e.message}]`);
    }
  }
  return out;
}

async function waitForRateLimit() {
  // Poll a harmless login until it is NOT rate-limited (429-style message clears).
  for (let i = 0; i < 25; i++) {
    const r = await login("ratecheck-nonexistent", "x", "resident");
    const msg = (r.body && r.body.error) || "";
    if (!/too many/i.test(typeof msg === "string" ? msg : JSON.stringify(msg))) {
      log(`Rate limit clear after ~${i} min (probe status ${r.status}).`);
      return true;
    }
    log(`[${i}] still rate-limited, waiting 60s...`);
    await sleep(60000);
  }
  return false;
}

async function main() {
  log(`SERO portal test — ${new Date().toISOString()}`);
  const ok = await waitForRateLimit();
  if (!ok) { log("Rate limit did not clear in time. Aborting."); process.exit(1); }

  const cases = [
    { label: "STAFF / Security", phone: "9000000001", pwd: "123456", portal: "staff",
      paths: ["/staff/me", "/staff/shift", "/visitors", "/staff/dashboard", "/notices-v2"] },
    { label: "SUPER ADMIN", phone: "superadmin", pwd: "123456", portal: "super-admin",
      paths: ["/super-admin/overview", "/super-admin/societies", "/super-admin/analytics", "/super-admin/system-health"] },
    { label: "RESIDENT", phone: "9876543200", pwd: "123456", portal: "resident",
      paths: ["/notices-v2", "/events-v2", "/finance/invoices", "/complaints", "/amenities"] },
  ];

  for (const c of cases) {
    await sleep(1500); // gentle spacing to avoid re-tripping the limiter
    const r = await login(c.phone, c.pwd, c.portal);
    log(`\n### ${c.label}  (${c.phone}/${c.pwd}, portal=${c.portal})`);
    if (!r.token) {
      log(`  LOGIN FAILED [${r.status}]: ${JSON.stringify(r.body).slice(0, 200)}`);
      continue;
    }
    let soc = "?";
    try { soc = JSON.parse(Buffer.from(r.token.split(".")[1], "base64").toString()).society_id; } catch {}
    log(`  login OK [${r.status}] society_id=${soc}`);
    const rows = await probe(r.token, c.paths);
    rows.forEach((x) => log(x));
  }
  log("\nDONE.");
  process.exit(0);
}

main().catch((e) => { log("FATAL: " + e.message); process.exit(1); });
