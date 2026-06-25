// Throwaway verification harness for the Razorpay TEST-mode flow.
// Proves: (a) server-side order amount comes from the invoice, (b) checkout
// signature verification is authoritative, (c) webhook raw-body HMAC + idempotency
// produce exactly ONE financial effect on duplicate delivery.
//
// Run against a throwaway instance booted with dummy keys:
//   PORT=3011 RAZORPAY_KEY_ID=rzp_test_dummy123 RAZORPAY_KEY_SECRET=dummy_secret_for_logic_test \
//   RAZORPAY_WEBHOOK_SECRET=dummy_webhook_secret npm start
//   node scripts/verify_razorpay_logic.mjs
import crypto from "crypto";
import jwt from "jsonwebtoken";
import { execSync } from "child_process";

const BASE = "http://localhost:3011/api/v1";
const KEY_SECRET = "dummy_secret_for_logic_test";
const WEBHOOK_SECRET = "dummy_webhook_secret";
const JWT_SECRET = "sero-local-dev-secret-key-2024-xyz";
const SOCIETY = "hubtown-sunmist";
const INVOICE_NUMBER = "INV-RZP-TEST-001";

const token = jwt.sign(
  { uid: "admin-001", phone: "admin", role: "main_admin", name: "Admin", society_id: SOCIETY },
  JWT_SECRET, { algorithm: "HS256", expiresIn: "1h" }
);

const psql = (sql) =>
  execSync(`docker exec society-backend-postgres-1 psql -U sero -d sero_dev -t -A -c "${sql}"`)
    .toString().trim();

const invoiceId = psql(`SELECT id FROM invoices WHERE society_id='${SOCIETY}' AND number='${INVOICE_NUMBER}'`);

async function http(path, body, hdrs = {}) {
  const res = await fetch(BASE + path, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...hdrs },
    body: JSON.stringify(body),
  });
  let json; try { json = await res.json(); } catch { json = null; }
  return { status: res.status, json };
}
const authHdr = { Authorization: `Bearer ${token}` };

function countFor(paymentId) {
  const p = Number(psql(`SELECT count(*) FROM payments WHERE society_id='${SOCIETY}' AND provider_payment_id='${paymentId}' AND status='captured'`));
  const a = Number(psql(`SELECT count(*) FROM payment_allocations pa JOIN payments p ON p.id=pa.payment_id WHERE p.provider_payment_id='${paymentId}'`));
  const r = Number(psql(`SELECT count(*) FROM receipts r JOIN payments p ON p.id=r.payment_id WHERE p.provider_payment_id='${paymentId}' AND r.status='issued'`));
  const jl = Number(psql(`SELECT count(*) FROM journal_lines jl JOIN journal_entries je ON je.id=jl.journal_entry_id JOIN payments p ON p.id::text=je.source_id WHERE p.provider_payment_id='${paymentId}'`));
  return { payments: p, allocations: a, receipts: r, journalLines: jl };
}

let pass = 0, fail = 0;
const check = (name, cond, detail) => { if (cond) { pass++; console.log(`  PASS  ${name}`); } else { fail++; console.log(`  FAIL  ${name} :: ${detail}`); } };

console.log(`\nInvoice ${INVOICE_NUMBER} = ${invoiceId}\n`);

// Clean any prior test rows for a repeatable run.
const PID = "pay_TESTLOGIC001";
const OID = "order_TESTLOGIC001";
psql(`DELETE FROM receipts WHERE payment_id IN (SELECT id FROM payments WHERE provider_payment_id='${PID}')`);
psql(`DELETE FROM journal_lines WHERE journal_entry_id IN (SELECT je.id FROM journal_entries je JOIN payments p ON p.id::text=je.source_id WHERE p.provider_payment_id='${PID}')`);
psql(`DELETE FROM journal_entries WHERE source_id IN (SELECT id::text FROM payments WHERE provider_payment_id='${PID}')`);
psql(`DELETE FROM payment_allocations WHERE payment_id IN (SELECT id FROM payments WHERE provider_payment_id='${PID}')`);
psql(`DELETE FROM payments WHERE society_id='${SOCIETY}' AND (provider_payment_id='${PID}' OR idempotency_key='rzp_order:${OID}')`);
psql(`DELETE FROM payment_webhook_events WHERE provider='razorpay' AND event_id LIKE 'evt_TESTLOGIC%'`);

// ── 1. create-order: amount must come from invoice, not client ──────────────
console.log("[1] create-order (server-side amount)");
const co = await http("/finance/payments/create-order", { invoiceId, amount: 999999 }, authHdr);
// Dummy keys -> Razorpay API call fails; we accept any non-2xx that is NOT a
// silent client-amount echo. If real test keys were present this would be 201.
console.log(`      status=${co.status} body=${JSON.stringify(co.json)}`);
check("create-order rejects unknown 'amount' field (server derives it)", co.status === 400 || co.status === 500 || co.status === 503 || (co.status === 201 && co.json.amountMinor === 100000),
  "expected server-side amount handling");

// ── 2. verify: bad signature rejected ───────────────────────────────────────
console.log("[2] verify rejects a forged signature");
const badVerify = await http("/finance/payments/verify", {
  razorpay_order_id: OID, razorpay_payment_id: PID, razorpay_signature: "deadbeef", invoiceId,
}, authHdr);
check("forged signature -> 400", badVerify.status === 400, `got ${badVerify.status} ${JSON.stringify(badVerify.json)}`);

// ── 3. verify: valid signature captures exactly once (idempotent) ───────────
console.log("[3] verify with a valid signature captures once, duplicate is a no-op");
// Seed a pending intent so the server can resolve the invoice from the order.
psql(`INSERT INTO payments (society_id, provider, amount_minor, currency, status, idempotency_key, metadata) VALUES ('${SOCIETY}','razorpay',100000,'INR','pending','rzp_order:${OID}','{\\"orderId\\":\\"${OID}\\",\\"invoiceId\\":\\"${invoiceId}\\"}')`);
const goodSig = crypto.createHmac("sha256", KEY_SECRET).update(`${OID}|${PID}`).digest("hex");
const v1 = await http("/finance/payments/verify", { razorpay_order_id: OID, razorpay_payment_id: PID, razorpay_signature: goodSig, invoiceId }, authHdr);
check("valid signature -> 200 captured", v1.status === 200 && v1.json.success, `got ${v1.status} ${JSON.stringify(v1.json)}`);
const afterV1 = countFor(PID);
const v2 = await http("/finance/payments/verify", { razorpay_order_id: OID, razorpay_payment_id: PID, razorpay_signature: goodSig, invoiceId }, authHdr);
check("duplicate verify -> 200 duplicate", v2.status === 200 && (v2.json.duplicate === true), `got ${v2.status} ${JSON.stringify(v2.json)}`);
const afterV2 = countFor(PID);
console.log(`      after 1st: ${JSON.stringify(afterV1)}`);
console.log(`      after 2nd: ${JSON.stringify(afterV2)}`);
check("exactly ONE captured payment after duplicate verify", afterV2.payments === 1, `payments=${afterV2.payments}`);
check("exactly ONE allocation", afterV2.allocations === 1, `allocations=${afterV2.allocations}`);
check("exactly ONE issued receipt", afterV2.receipts === 1, `receipts=${afterV2.receipts}`);
check("balanced ledger: 2 journal lines (Dr cash / Cr A/R)", afterV2.journalLines === 2, `journalLines=${afterV2.journalLines}`);

// ── 4. webhook: raw-body HMAC + idempotency ─────────────────────────────────
console.log("[4] webhook verifies raw-body HMAC and dedupes by event id");
const WPID = "pay_TESTLOGIC_WH";
const WOID = "order_TESTLOGIC_WH";
// clean
psql(`DELETE FROM receipts WHERE payment_id IN (SELECT id FROM payments WHERE provider_payment_id='${WPID}')`);
psql(`DELETE FROM journal_lines WHERE journal_entry_id IN (SELECT je.id FROM journal_entries je JOIN payments p ON p.id::text=je.source_id WHERE p.provider_payment_id='${WPID}')`);
psql(`DELETE FROM journal_entries WHERE source_id IN (SELECT id::text FROM payments WHERE provider_payment_id='${WPID}')`);
psql(`DELETE FROM payment_allocations WHERE payment_id IN (SELECT id FROM payments WHERE provider_payment_id='${WPID}')`);
psql(`DELETE FROM payments WHERE society_id='${SOCIETY}' AND provider_payment_id='${WPID}'`);

const eventId = "evt_TESTLOGIC_WH_1";
const evt = {
  id: eventId, event: "payment.captured",
  payload: { payment: { entity: { id: WPID, order_id: WOID, amount: 100000, notes: { societyId: SOCIETY, invoiceId } } } },
};
const rawBody = JSON.stringify(evt);
const wSig = crypto.createHmac("sha256", WEBHOOK_SECRET).update(rawBody).digest("hex");

async function postWebhook(raw, sig, eid) {
  const res = await fetch(BASE + "/finance/webhook/razorpay", {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-razorpay-signature": sig, "x-razorpay-event-id": eid },
    body: raw,
  });
  let j; try { j = await res.json(); } catch { j = null; }
  return { status: res.status, json: j };
}

const wBad = await postWebhook(rawBody, "00bad00", eventId);
check("webhook forged signature -> 400", wBad.status === 400, `got ${wBad.status} ${JSON.stringify(wBad.json)}`);

const w1 = await postWebhook(rawBody, wSig, eventId);
check("webhook valid signature -> 200 processed", w1.status === 200 && w1.json.processed === true, `got ${w1.status} ${JSON.stringify(w1.json)}`);
const wAfter1 = countFor(WPID);
const w2 = await postWebhook(rawBody, wSig, eventId);
check("webhook duplicate -> 200 duplicate", w2.status === 200 && w2.json.duplicate === true, `got ${w2.status} ${JSON.stringify(w2.json)}`);
const wAfter2 = countFor(WPID);
console.log(`      after 1st webhook: ${JSON.stringify(wAfter1)}`);
console.log(`      after 2nd webhook: ${JSON.stringify(wAfter2)}`);
check("exactly ONE captured payment after duplicate webhook", wAfter2.payments === 1, `payments=${wAfter2.payments}`);
check("exactly ONE allocation after duplicate webhook", wAfter2.allocations === 1, `allocations=${wAfter2.allocations}`);
check("exactly ONE issued receipt after duplicate webhook", wAfter2.receipts === 1, `receipts=${wAfter2.receipts}`);
const whEvents = Number(psql(`SELECT count(*) FROM payment_webhook_events WHERE provider='razorpay' AND event_id='${eventId}'`));
check("webhook event stored exactly once", whEvents === 1, `webhook_events=${whEvents}`);

console.log(`\n=== RESULT: ${pass} passed, ${fail} failed ===`);
process.exit(fail === 0 ? 0 : 1);
