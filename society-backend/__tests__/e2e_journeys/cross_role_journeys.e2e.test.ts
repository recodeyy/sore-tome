import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll, jest } from "@jest/globals";
import express from "express";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import { db, dbManager } from "../../src/shared/Database";

// No @types/supertest in this repo — require() keeps ts-jest's strict compile happy.
// eslint-disable-next-line @typescript-eslint/no-var-requires
const request = require("supertest");

/**
 * §17 cross-role E2E journeys, exercised over the REAL HTTP API surface
 * (supertest drives the same Express routers server.js mounts, minus the
 * Redis rate limiters so a full journey run is deterministic).
 *
 * Data strategy:
 *  - Seeded "hubtown-sunkist" society (scripts/seed_hubtown_sunkist.js) is used
 *    wherever possible; every row this suite creates carries a unique RUN id
 *    and is deleted in afterAll, so re-runs are idempotent.
 *  - Finance journeys (2, 11) run in a per-run fixture society so ledger /
 *    receipt rows can be wiped wholesale without touching seeded finance data.
 *  - Tokens are minted directly with JWT_SECRET (same claims POST /auth/login
 *    issues) instead of hammering the rate-limited login route. Login itself
 *    is smoke-tested per portal in login_smoke.e2e.test.ts.
 */

jest.setTimeout(60000);

const SECRET = process.env.JWT_SECRET || "sero-local-dev-secret-key-2024-xyz";
const SOC = "hubtown-sunkist";
const SOC_B = "hubtown-society-b";
const RUN = `${Date.now()}`;
const FIN_SOC = `e2e-fin-${RUN}`;

// ── App under test: the real routers, mounted exactly like server.js ────────
const app = express();
app.use(express.json({ limit: "5mb" }));
const v1 = express.Router();
/* eslint-disable @typescript-eslint/no-var-requires */
v1.use("/complaints", require("../../src/routes/complaints").default);
v1.use("/resident", require("../../src/routes/resident_pg").default);
v1.use("/finance", require("../../src/routes/finance").default);
v1.use("/amenities", require("../../src/routes/amenities").default);
v1.use("/notices-v2", require("../../src/routes/notices_pg").default);
v1.use("/polls-v2", require("../../src/routes/polls_pg").default);
v1.use("/parking", require("../../src/routes/parking_pg").default);
v1.use("/guard", require("../../src/routes/guard_pg").default);
v1.use("/members-v2", require("../../src/routes/members_pg").default);
v1.use("/notifications", require("../../src/routes/notifications_pg").default);
/* eslint-enable @typescript-eslint/no-var-requires */
app.use("/api/v1", v1);

// ── Role tokens (same claim shape middleware/auth.js verifies) ──────────────
const mint = (uid: string, role: string, society_id: string, extra: Record<string, unknown> = {}) =>
  jwt.sign({ uid, phone: "9999999999", name: uid, role, society_id, ...extra }, SECRET, { expiresIn: "2h" });

const ADMIN = mint("sunkist-admin-001", "main_admin", SOC);
const RESIDENT = mint("sunkist-res-001", "resident", SOC); // A-1402
const RESIDENT2 = mint("sunkist-res-002", "resident", SOC); // A-1401
const GUARD = mint("sunkist-guard-001", "guard", SOC);
const B_ADMIN = mint("admin-b-001", "main_admin", SOC_B);
const FIN_ADMIN = mint(`e2e-fin-admin-${RUN}`, "main_admin", FIN_SOC);
const FIN_RESIDENT = mint(`e2e-fin-res-${RUN}`, "resident", FIN_SOC);

const api = (tok: string) => ({
  get: (p: string) => request(app).get(`/api/v1${p}`).set("Authorization", `Bearer ${tok}`),
  post: (p: string) => request(app).post(`/api/v1${p}`).set("Authorization", `Bearer ${tok}`),
  patch: (p: string) => request(app).patch(`/api/v1${p}`).set("Authorization", `Bearer ${tok}`),
  put: (p: string) => request(app).put(`/api/v1${p}`).set("Authorization", `Bearer ${tok}`),
  del: (p: string) => request(app).delete(`/api/v1${p}`).set("Authorization", `Bearer ${tok}`),
});

const notifWhere = async (where: string, params: any[]) =>
  (await db.query(`SELECT * FROM notifications WHERE ${where} ORDER BY created_at`, params)).rows;

// ── Seeded fixture handles resolved up-front ─────────────────────────────────
let unitA1402: string;
let memberRes1: string; // members.id of sunkist-res-001
let staffGuardId: string; // staff.id (uuid) of sunkist-guard-001
let vehicleId: string; // a seeded A-1402 vehicle
let seededNoticeId: string; // any hubtown-sunkist notice, for isolation checks
let finResidentMemberId: string;

// Rows created by this run, deleted in afterAll.
const created = {
  joinUsers: [] as string[],
  memberIds: [] as string[],
  noticeIds: [] as string[],
  visitorIds: [] as string[],
  preApprovalIds: [] as string[],
  complaintIds: [] as string[],
  pollIds: [] as string[],
  amenityIds: [] as string[],
  bookingIds: [] as string[],
  slotIds: [] as string[],
  allocationIds: [] as string[],
  incidentIds: [] as string[],
};

beforeAll(async () => {
  const one = async (sql: string, params: any[] = []) => (await db.query(sql, params)).rows[0];

  unitA1402 = (await one(`SELECT id FROM units WHERE society_id = $1 AND number = 'A-1402'`, [SOC]))?.id;
  memberRes1 = (await one(`SELECT id FROM members WHERE society_id = $1 AND user_id = 'sunkist-res-001'`, [SOC]))?.id;
  staffGuardId = (await one(`SELECT id FROM staff WHERE society_id = $1 AND user_id = 'sunkist-guard-001'`, [SOC]))?.id;
  vehicleId = (await one(
    `SELECT id FROM vehicles WHERE society_id = $1 AND unit_id = $2 ORDER BY plate LIMIT 1`, [SOC, unitA1402]
  ))?.id;
  seededNoticeId = (await one(`SELECT id FROM notices WHERE society_id = $1 ORDER BY created_at LIMIT 1`, [SOC]))?.id;

  if (!unitA1402 || !memberRes1 || !staffGuardId) {
    throw new Error(
      "hubtown-sunkist seed missing — run `node scripts/seed_hubtown_sunkist.js` before the e2e journeys suite"
    );
  }

  // Per-run finance fixture society (journeys 2 & 11).
  await db.query(
    `INSERT INTO society_profiles (society_id, name) VALUES ($1, 'E2E Finance Fixture') ON CONFLICT DO NOTHING`,
    [FIN_SOC]
  );
  await db.query(
    `INSERT INTO members (society_id, user_id, name, phone, status, role)
     VALUES ($1, $2, 'E2E Fin Admin', '9111100001', 'approved', 'main_admin')`,
    [FIN_SOC, `e2e-fin-admin-${RUN}`]
  );
  finResidentMemberId = (
    await db.query(
      `INSERT INTO members (society_id, user_id, name, phone, status, role)
       VALUES ($1, $2, 'E2E Fin Resident', '9111100002', 'approved', 'resident') RETURNING id`,
      [FIN_SOC, `e2e-fin-res-${RUN}`]
    )
  ).rows[0].id;
});

afterAll(async () => {
  const run = async (sql: string, params: any[]) => {
    try { await db.query(sql, params); } catch { /* best-effort cleanup */ }
  };

  // Finance fixture society: wipe wholesale (same table list as payment_demo).
  for (const t of [
    "demo_payment_audits", "outbox_events", "notifications", "receipts", "payment_allocations", "payments",
    "journal_lines", "journal_entries", "invoice_lines", "invoices", "chart_of_accounts", "members",
  ]) {
    await run(`DELETE FROM ${t} WHERE society_id = $1`, [FIN_SOC]);
  }
  await run(`DELETE FROM payment_webhook_events WHERE society_id = $1`, [FIN_SOC]);
  await run(`DELETE FROM society_profiles WHERE society_id = $1`, [FIN_SOC]);

  // hubtown-sunkist: delete only what this run created (children first).
  if (created.bookingIds.length)
    await run(`DELETE FROM amenity_bookings WHERE id = ANY($1)`, [created.bookingIds]);
  if (created.amenityIds.length) {
    await run(`DELETE FROM amenity_bookings WHERE amenity_id = ANY($1)`, [created.amenityIds]);
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'amenityId' = ANY($2)`, [SOC, created.amenityIds]);
    await run(`DELETE FROM amenities WHERE id = ANY($1)`, [created.amenityIds]);
  }
  if (created.allocationIds.length) {
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'allocationId' = ANY($2)`, [SOC, created.allocationIds]);
    await run(`DELETE FROM parking_allocations WHERE id = ANY($1)`, [created.allocationIds]);
  }
  if (created.slotIds.length)
    await run(`DELETE FROM parking_slots WHERE id = ANY($1)`, [created.slotIds]);
  if (created.pollIds.length) {
    await run(`DELETE FROM votes WHERE poll_id = ANY($1)`, [created.pollIds]);
    await run(`DELETE FROM poll_eligibility WHERE poll_id = ANY($1)`, [created.pollIds]);
    await run(`DELETE FROM poll_options WHERE poll_id = ANY($1)`, [created.pollIds]);
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'pollId' = ANY($2)`, [SOC, created.pollIds]);
    await run(`DELETE FROM polls WHERE id = ANY($1)`, [created.pollIds]);
  }
  if (created.complaintIds.length) {
    for (const t of ["complaint_assignments", "complaint_status_history", "complaint_comments", "complaint_sla_events", "complaint_feedback"]) {
      await run(`DELETE FROM ${t} WHERE complaint_id = ANY($1)`, [created.complaintIds]);
    }
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'complaintId' = ANY($2)`, [SOC, created.complaintIds]);
    await run(`DELETE FROM complaints WHERE id = ANY($1)`, [created.complaintIds]);
  }
  if (created.noticeIds.length) {
    for (const t of ["notice_versions", "notice_reads", "notice_audiences"]) {
      await run(`DELETE FROM ${t} WHERE notice_id = ANY($1)`, [created.noticeIds]);
    }
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'noticeId' = ANY($2)`, [SOC, created.noticeIds]);
    await run(`DELETE FROM outbox_events WHERE society_id = $1 AND payload->>'id' = ANY($2)`, [SOC, created.noticeIds]);
    await run(`DELETE FROM notices WHERE id = ANY($1)`, [created.noticeIds]);
  }
  if (created.visitorIds.length) {
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'visitorId' = ANY($2)`, [SOC, created.visitorIds]);
    await run(`DELETE FROM outbox_events WHERE society_id = $1 AND payload->>'id' = ANY($2)`, [SOC, created.visitorIds]);
    await run(`DELETE FROM visitor_entries WHERE id = ANY($1)`, [created.visitorIds]);
  }
  if (created.preApprovalIds.length)
    await run(`DELETE FROM resident_visitors WHERE id = ANY($1)`, [created.preApprovalIds]);
  if (created.incidentIds.length) {
    await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'incidentId' = ANY($2)`, [SOC, created.incidentIds]);
    await run(`DELETE FROM outbox_events WHERE society_id = $1 AND payload->>'id' = ANY($2)`, [SOC, created.incidentIds]);
    await run(`DELETE FROM security_incidents WHERE id = ANY($1)`, [created.incidentIds]);
  }
  if (created.joinUsers.length) {
    await run(`DELETE FROM notifications WHERE user_id = ANY($1)`, [created.joinUsers]);
    if (created.memberIds.length)
      await run(`DELETE FROM notifications WHERE society_id = $1 AND data->>'memberId' = ANY($2)`, [SOC, created.memberIds]);
    await run(`DELETE FROM outbox_events WHERE society_id = $1 AND payload->>'memberId' = ANY($2)`, [SOC, created.memberIds]);
    await run(`DELETE FROM members WHERE society_id = $1 AND user_id = ANY($2)`, [SOC, created.joinUsers]);
  }

  await dbManager.close();
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 1 — Resident join request → admin approves/rejects → notifications
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 1: resident join-request → admin approval/rejection", () => {
  const joinerA = `e2e-join-a-${RUN}`;
  const joinerB = `e2e-join-b-${RUN}`;
  const tokenA = mint(joinerA, "resident", "");
  const tokenB = mint(joinerB, "resident", "");
  let requestA: string;
  let requestB: string;

  it("resident submits a join request for a real flat", async () => {
    const res = await api(tokenA).post("/resident/join-requests").send({
      societyId: SOC, wing: "A", unitNumber: "A-101", name: "E2E Joiner A", phone: "9333300001",
    });
    expect(res.status).toBe(201);
    expect(res.body.request.status).toBe("pending");
    requestA = res.body.request.id;
    created.joinUsers.push(joinerA);
    created.memberIds.push(requestA);

    const mine = await api(tokenA).get("/resident/join-requests/my");
    expect(mine.status).toBe(200);
    expect(mine.body.requests.some((r: any) => r.id === requestA)).toBe(true);
  });

  it("admin sees the pending request in /members-v2/join-requests and approves it", async () => {
    const list = await api(ADMIN).get("/members-v2/join-requests");
    expect(list.status).toBe(200);
    expect(list.body.requests.some((r: any) => r.id === requestA)).toBe(true);

    const ok = await api(ADMIN).post(`/members-v2/join-requests/${requestA}/approve`);
    expect(ok.status).toBe(200);
    expect(ok.body.request.status).toBe("approved");

    const member = (await db.query(`SELECT status FROM members WHERE id = $1`, [requestA])).rows[0];
    expect(member.status).toBe("approved");

    const notifs = await notifWhere(`society_id = $1 AND user_id = $2 AND type = 'member'`, [SOC, joinerA]);
    expect(notifs.some((n: any) => n.title === "Join request approved")).toBe(true);
  });

  it("reject path: a fresh request is rejected and the resident is notified", async () => {
    const res = await api(tokenB).post("/resident/join-requests").send({
      societyId: SOC, wing: "A", unitNumber: "A-1401", name: "E2E Joiner B", phone: "9333300002",
    });
    expect(res.status).toBe(201);
    requestB = res.body.request.id;
    created.joinUsers.push(joinerB);
    created.memberIds.push(requestB);

    const no = await api(ADMIN).post(`/members-v2/join-requests/${requestB}/reject`);
    expect(no.status).toBe(200);
    expect(no.body.request.status).toBe("rejected");

    const notifs = await notifWhere(`society_id = $1 AND user_id = $2 AND type = 'member'`, [SOC, joinerB]);
    expect(notifs.some((n: any) => n.title === "Join request declined")).toBe(true);

    // A rejected request never becomes an active member.
    const member = (await db.query(`SELECT status FROM members WHERE id = $1`, [requestB])).rows[0];
    expect(member.status).toBe("rejected");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 2 — Invoice publish → resident pays (verify) → receipt + PDF
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 2: invoice → Razorpay-style verify (idempotent) → receipt PDF", () => {
  const INV_NO = `E2E-INV-${RUN}`;
  const orderId = `order_e2e_${RUN}`;
  const paymentId = `pay_e2e_${RUN}`;
  let invoiceId: string;
  let receiptId: string;

  const sig = (o: string, p: string) =>
    crypto.createHmac("sha256", process.env.RAZORPAY_KEY_SECRET as string).update(`${o}|${p}`).digest("hex");

  it("admin creates and publishes an invoice", async () => {
    const createRes = await api(FIN_ADMIN).post("/finance/invoices").send({
      number: INV_NO,
      memberId: finResidentMemberId,
      period: "2026-07",
      lines: [{ description: "Maintenance Jul 2026", unitPriceMinor: 45000 }],
    });
    expect(createRes.status).toBe(201);
    invoiceId = createRes.body.invoice.id;

    const pub = await api(FIN_ADMIN).post(`/finance/invoices/${invoiceId}/publish`);
    expect(pub.status).toBe(200);
  });

  it("resident lists the published invoice in /finance/invoices", async () => {
    const res = await api(FIN_RESIDENT).get("/finance/invoices?status=published");
    expect(res.status).toBe(200);
    const inv = res.body.invoices.find((i: any) => i.id === invoiceId);
    expect(inv).toBeTruthy();
    expect(inv.number).toBe(INV_NO);
  });

  it("verify is idempotent: duplicate verify applies exactly one payment", async () => {
    // Seed the order intent exactly like POST /payments/create-order records it
    // (avoids a live Razorpay order call in CI; the verify path is the target).
    await db.query(
      `INSERT INTO payments (society_id, provider, amount_minor, currency, status, idempotency_key, metadata)
       VALUES ($1,'razorpay',45000,'INR','pending',$2,$3)`,
      [FIN_SOC, `rzp_order:${orderId}`, JSON.stringify({ orderId, invoiceId })]
    );

    const body = { razorpay_order_id: orderId, razorpay_payment_id: paymentId, razorpay_signature: sig(orderId, paymentId) };
    const first = await api(FIN_RESIDENT).post("/finance/payments/verify").send(body);
    expect(first.status).toBe(200);
    expect(first.body.status).toBe("captured");
    expect(first.body.duplicate).toBe(false);

    const second = await api(FIN_RESIDENT).post("/finance/payments/verify").send(body);
    expect(second.status).toBe(200);
    expect(second.body.duplicate).toBe(true);

    const captured = await db.query(
      `SELECT count(*)::int n FROM payments WHERE society_id = $1 AND provider_payment_id = $2 AND status = 'captured'`,
      [FIN_SOC, paymentId]
    );
    expect(captured.rows[0].n).toBe(1);

    const bad = await api(FIN_RESIDENT).post("/finance/payments/verify").send({ ...body, razorpay_signature: "f".repeat(64) });
    expect(bad.status).toBe(400);
  });

  it("resident sees the issued receipt and downloads a %PDF", async () => {
    const list = await api(FIN_RESIDENT).get("/finance/receipts");
    expect(list.status).toBe(200);
    const receipt = list.body.receipts.find((r: any) => r.invoice_id === invoiceId);
    expect(receipt).toBeTruthy();
    expect(receipt.status).toBe("issued");
    receiptId = receipt.id;

    const pdf = await api(FIN_RESIDENT)
      .get(`/finance/receipts/${receiptId}/pdf`)
      .buffer(true)
      .parse((res: any, cb: any) => {
        const chunks: Buffer[] = [];
        res.on("data", (c: Buffer) => chunks.push(c));
        res.on("end", () => cb(null, Buffer.concat(chunks)));
      });
    expect(pdf.status).toBe(200);
    expect(pdf.headers["content-type"]).toContain("application/pdf");
    const buf = pdf.body as Buffer;
    expect(buf.length).toBeGreaterThan(500);
    expect(buf.slice(0, 4).toString()).toBe("%PDF");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 3 — Notice publish → resident sees it → notification rows + deeplink
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 3: notices-v2 publish → resident visibility → notifications", () => {
  let noticeId: string;
  const title = `E2E Notice ${RUN}`;

  it("admin creates and publishes a notice", async () => {
    const createRes = await api(ADMIN).post("/notices-v2").send({
      title, body: "Water supply maintenance on Sunday 10:00-14:00.", type: "maintenance",
    });
    expect(createRes.status).toBe(201);
    noticeId = createRes.body.notice.id;
    created.noticeIds.push(noticeId);

    const pub = await api(ADMIN).post(`/notices-v2/${noticeId}/publish`);
    expect(pub.status).toBe(200);
    expect(pub.body.notice.status).toBe("published");
  });

  it("resident sees the published notice", async () => {
    const res = await api(RESIDENT).get("/notices-v2?status=published");
    expect(res.status).toBe(200);
    const notice = res.body.notices.find((n: any) => n.id === noticeId);
    expect(notice).toBeTruthy();
    expect(notice.title).toBe(title);
  });

  it("notification rows exist for approved members, with a deeplink", async () => {
    const rows = await notifWhere(`society_id = $1 AND type = 'notice' AND data->>'noticeId' = $2`, [SOC, noticeId]);
    // All approved members with a login get one (admin + 3 residents at minimum).
    expect(rows.length).toBeGreaterThanOrEqual(3);
    const residentRow = rows.find((r: any) => r.user_id === "sunkist-res-001");
    expect(residentRow).toBeTruthy();
    // In-app rows carry the app-scheme deepLink; the FCM push payload carries
    // the path-style `/notices/:id` deeplink (see NoticeService.publish).
    expect(residentRow.data.deepLink).toBe(`sero://notices/${noticeId}`);
    expect(residentRow.data.noticeId).toBe(noticeId);

    // Resident also sees it via the notifications API.
    const inbox = await api(RESIDENT).get("/notifications");
    expect(inbox.status).toBe(200);
    const body = JSON.stringify(inbox.body);
    expect(body).toContain(noticeId);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 4 — Guard logs visitor → resident approves → entry → checkout
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 4: guard visitor flow with resident approval + entry/exit notifications", () => {
  let visitorId: string;

  it("guard logs a visitor for A-1402 → resident gets an approval-request notification", async () => {
    const res = await api(GUARD).post("/guard/visitors/check-in").send({
      name: `E2E Zomato ${RUN}`, phone: "9888800001", purpose: "Food delivery", unitId: unitA1402,
    });
    expect(res.status).toBe(201);
    visitorId = res.body.visitor.id;
    created.visitorIds.push(visitorId);

    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-res-001' AND data->>'visitorId' = $2`, [SOC, visitorId]
    );
    expect(rows.length).toBe(1);
    expect(rows[0].title).toBe("Visitor at the gate");
    expect(rows[0].data.action).toBe("approval");
  });

  it("resident approves via the decision route → guard notified", async () => {
    const res = await api(RESIDENT).post(`/guard/visitors/${visitorId}/decision`).send({ decision: "approved" });
    expect(res.status).toBe(200);

    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-guard-001' AND data->>'visitorId' = $2`, [SOC, visitorId]
    );
    expect(rows.some((r: any) => r.title === "Visitor approved")).toBe(true);
  });

  it("guard records entry then checkout → entry/exit notification rows for the resident", async () => {
    const entry = await api(GUARD).post(`/guard/visitors/${visitorId}/entry`);
    expect(entry.status).toBe(200);
    expect(entry.body.visitor.status).toBe("checked_in");

    const out = await api(GUARD).post(`/guard/visitors/${visitorId}/check-out`);
    expect(out.status).toBe(200);
    expect(out.body.visitor.status).toBe("checked_out");

    // Double checkout is rejected.
    const again = await api(GUARD).post(`/guard/visitors/${visitorId}/check-out`);
    expect(again.status).toBe(409);

    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-res-001' AND data->>'visitorId' = $2`, [SOC, visitorId]
    );
    expect(rows.some((r: any) => r.title === "Visitor entered")).toBe(true);
    expect(rows.some((r: any) => r.title === "Visitor exited")).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 5 — Resident pre-approval → gate check-in referencing it
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 5: resident pre-approves a visitor → guard check-in via preApprovalId", () => {
  let preApprovalId: string;
  let visitorId: string;

  it("resident creates a pre-approval and sees it in /resident/visitors", async () => {
    const res = await api(RESIDENT).post("/resident/visitors").send({
      visitorName: `E2E Guest ${RUN}`, visitorPhone: "9888800002", purpose: "Family visit",
      expectedAt: new Date(Date.now() + 3600_000).toISOString(),
    });
    expect(res.status).toBe(201);
    preApprovalId = res.body.visitor.id;
    expect(res.body.visitor.status).toBe("approved");
    created.preApprovalIds.push(preApprovalId);

    const mine = await api(RESIDENT).get("/resident/visitors");
    expect(mine.status).toBe(200);
    expect(mine.body.visitors.some((v: any) => v.id === preApprovalId)).toBe(true);
  });

  // Backend gap (gap report journey 5): no guard-facing endpoint surfaces
  // resident_visitors pre-approvals as an "expected" list — /guard/visitors only
  // reads visitor_entries, and nothing projects resident pre-approvals into it.
  it.skip("guard's expected visitor list shows the pre-approval (BLOCKED: no guard endpoint reads resident_visitors)", () => {
    /* Unblock by adding e.g. GET /guard/expected-visitors backed by resident_visitors. */
  });

  it("guard checks the pre-approved guest in, linked via preApprovalId → checked_in", async () => {
    const res = await api(GUARD).post("/guard/visitors/check-in").send({
      name: `E2E Guest ${RUN}`, purpose: "Family visit (pre-approved)",
      unitId: unitA1402, preApprovalId,
    });
    expect(res.status).toBe(201);
    visitorId = res.body.visitor.id;
    created.visitorIds.push(visitorId);
    expect(res.body.visitor.status).toBe("checked_in");
    expect(res.body.visitor.pre_approval_id).toBe(preApprovalId);

    const list = await api(GUARD).get("/guard/visitors?status=checked_in");
    expect(list.status).toBe(200);
    expect(list.body.visitors.some((v: any) => v.id === visitorId)).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 6 — Complaint lifecycle across resident, admin, staff
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 6: complaint create → assign (uuid + text) → status flow → notifications", () => {
  let c1: string; // driven via explicit status changes + text-form assignment
  let c2: string; // uuid-form assignment (auto in_progress)

  it("resident raises two complaints", async () => {
    for (const [idx, title] of [`E2E Leak ${RUN}`, `E2E Lift ${RUN}`].entries()) {
      const res = await api(RESIDENT).post("/complaints").send({
        title, description: "Created by the cross-role E2E journey suite.", priority: "high",
      });
      expect(res.status).toBe(201);
      expect(res.body.complaint.status).toBe("open");
      if (idx === 0) c1 = res.body.complaint.id; else c2 = res.body.complaint.id;
      created.complaintIds.push(res.body.complaint.id);
    }
  });

  it("admin moves c1 to in_progress → resident notified of the update", async () => {
    const res = await api(ADMIN).patch(`/complaints/${c1}/status`).send({ status: "in_progress" });
    expect(res.status).toBe(200);
    expect(res.body.complaint.status).toBe("in_progress");

    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-res-001' AND data->>'complaintId' = $2`, [SOC, c1]
    );
    expect(rows.some((r: any) => r.title === "Complaint updated")).toBe(true);
  });

  it("admin assigns c1 with a TEXT user_id and c2 with a staff UUID (MR-005 regression)", async () => {
    const textForm = await api(ADMIN).post(`/complaints/${c1}/assign`).send({
      assigneeId: "sunkist-guard-001", assigneeType: "staff", reason: "text user_id form",
    });
    expect(textForm.status).toBe(200);
    expect(textForm.body.complaint.assigned_to).toBe("sunkist-guard-001");

    const uuidForm = await api(ADMIN).post(`/complaints/${c2}/assign`).send({
      assigneeId: staffGuardId, assigneeType: "staff", reason: "uuid form",
    });
    expect(uuidForm.status).toBe(200);
    expect(uuidForm.body.complaint.assigned_to).toBe(staffGuardId);
    expect(uuidForm.body.complaint.status).toBe("in_progress"); // auto-transition on assign

    // Assignee notification exists for both forms (uuid resolved to the login user_id).
    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-guard-001' AND type = 'complaint'
         AND data->>'complaintId' = ANY($2)`, [SOC, [c1, c2]]
    );
    expect(rows.filter((r: any) => r.title === "Complaint assigned to you").length).toBe(2);
  });

  it("staff cannot drive the status route (documented gap) — admin resolves instead", async () => {
    // PATCH /complaints/:id/status is gated by canManageContent, which excludes
    // staff roles (guard/facility_manager). The §17 journey expects the assigned
    // staff member to update the status; today that returns 403.
    const staffTry = await api(GUARD).patch(`/complaints/${c1}/status`).send({ status: "resolved" });
    expect(staffTry.status).toBe(403);

    const res = await api(ADMIN).patch(`/complaints/${c1}/status`).send({ status: "resolved", note: "Plumber fixed it" });
    expect(res.status).toBe(200);
    expect(res.body.complaint.status).toBe("resolved");
  });

  it("resident sees the resolution + a notification row for each step", async () => {
    const detail = await api(RESIDENT).get(`/complaints/${c1}`);
    expect(detail.status).toBe(200);
    expect(detail.body.complaint.status).toBe("resolved");

    const history = (await db.query(
      `SELECT to_status FROM complaint_status_history WHERE complaint_id = $1 ORDER BY created_at`, [c1]
    )).rows.map((r: any) => r.to_status);
    expect(history).toEqual(expect.arrayContaining(["in_progress", "resolved"]));

    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-res-001' AND data->>'complaintId' = $2`, [SOC, c1]
    );
    expect(rows.some((r: any) => r.title === "Complaint updated")).toBe(true); // in_progress step
    expect(rows.some((r: any) => r.title === "Complaint resolved")).toBe(true); // resolved step
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 7 — Parking allocation → resident /parking/my → admin /allocations
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 7: admin allocates parking to A-1402 → visible to resident and admin", () => {
  const slotCode = `E2E-P-${RUN}`;
  let slotId: string;
  let allocationId: string;

  it("admin creates a slot and allocates it to A-1402's vehicle", async () => {
    const slot = await api(ADMIN).post("/parking/slots").send({ code: slotCode, type: "car", location: "E2E basement" });
    expect(slot.status).toBe(201);
    slotId = slot.body.slot.id;
    created.slotIds.push(slotId);

    const alloc = await api(ADMIN).post("/parking/allocations").send({
      slotId, vehicleId, unitId: unitA1402, allocatedTo: "sunkist-res-001",
    });
    expect(alloc.status).toBe(201);
    allocationId = alloc.body.allocation.id;
    created.allocationIds.push(allocationId);
    expect(alloc.body.allocation.status).toBe("active");
  });

  it("resident sees the slot in /parking/my (with slot code) + a notification", async () => {
    const res = await api(RESIDENT).get("/parking/my");
    expect(res.status).toBe(200);
    const mine = res.body.allocations.find((a: any) => a.id === allocationId);
    expect(mine).toBeTruthy();
    expect(mine.slot_code).toBe(slotCode);

    const rows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-res-001' AND data->>'allocationId' = $2`, [SOC, allocationId]
    );
    expect(rows.some((r: any) => r.title === "Parking slot allocated")).toBe(true);
  });

  it("allocation appears in admin /parking/allocations; residents get 403 there", async () => {
    const res = await api(ADMIN).get("/parking/allocations?status=active");
    expect(res.status).toBe(200);
    const row = res.body.allocations.find((a: any) => a.id === allocationId);
    expect(row).toBeTruthy();
    expect(row.unit_number).toBe("A-1402");

    const forbidden = await api(RESIDENT).get("/parking/allocations");
    expect(forbidden.status).toBe(403);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 8 — Poll create → single vote enforced → results
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 8: polls-v2 create → resident votes once → results", () => {
  let pollId: string;
  let optionYes: string;

  it("admin creates and opens a poll", async () => {
    const res = await api(ADMIN).post("/polls-v2").send({
      title: `E2E Poll ${RUN}`, description: "Should we adopt E2E tests?",
      resultsVisibility: "always",
      options: [{ label: "Yes" }, { label: "No" }],
    });
    expect(res.status).toBe(201);
    pollId = res.body.poll.id;
    created.pollIds.push(pollId);

    const open = await api(ADMIN).post(`/polls-v2/${pollId}/open`);
    expect(open.status).toBe(200);
    expect(open.body.poll.status).toBe("open");

    const opts = (await db.query(
      `SELECT id, label FROM poll_options WHERE poll_id = $1 ORDER BY position`, [pollId]
    )).rows;
    optionYes = opts.find((o: any) => o.label === "Yes").id;
  });

  it("resident votes once; a second vote is rejected as ALREADY_VOTED", async () => {
    const first = await api(RESIDENT).post(`/polls-v2/${pollId}/vote`).send({ optionId: optionYes });
    expect(first.status).toBe(201);

    const second = await api(RESIDENT).post(`/polls-v2/${pollId}/vote`).send({ optionId: optionYes });
    expect(second.status).toBe(409);
  });

  it("results show exactly the one vote", async () => {
    const res = await api(ADMIN).get(`/polls-v2/${pollId}/results`);
    expect(res.status).toBe(200);
    expect(res.body.talliesVisible).toBe(true);
    expect(res.body.totalVotes).toBe(1);
    const yes = res.body.options.find((o: any) => o.id === optionYes);
    expect(yes.count).toBe(1);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 9 — Amenity booking → overlap rejected → admin sees the booking
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 9: amenity booking with double-book protection", () => {
  let amenityId: string;
  let bookingId: string;
  const startAt = new Date(Date.now() + 24 * 3600_000).toISOString();
  const endAt = new Date(Date.now() + 25 * 3600_000).toISOString();

  it("admin creates an amenity; resident books a slot", async () => {
    const amenity = await api(ADMIN).post("/amenities").send({ name: `E2E Court ${RUN}`, capacity: 4 });
    expect(amenity.status).toBe(201);
    amenityId = amenity.body.amenity.id;
    created.amenityIds.push(amenityId);

    const booking = await api(RESIDENT).post(`/amenities/${amenityId}/book`).send({ startAt, endAt });
    expect(booking.status).toBe(201);
    bookingId = booking.body.booking.id;
    created.bookingIds.push(bookingId);
    expect(booking.body.booking.status).toBe("confirmed");
  });

  it("an overlapping booking by another resident is rejected with 409", async () => {
    const overlap = await api(RESIDENT2).post(`/amenities/${amenityId}/book`).send({
      startAt: new Date(Date.parse(startAt) + 30 * 60_000).toISOString(),
      endAt: new Date(Date.parse(endAt) + 30 * 60_000).toISOString(),
    });
    expect(overlap.status).toBe(409);
    expect(overlap.body.error).toMatch(/already booked/i);
  });

  it("admin sees the booking in the amenity's booking list", async () => {
    const res = await api(ADMIN).get(`/amenities/${amenityId}/bookings`);
    expect(res.status).toBe(200);
    expect(res.body.bookings.some((b: any) => b.id === bookingId)).toBe(true);

    const mine = await api(RESIDENT).get("/amenities/bookings/mine");
    expect(mine.status).toBe(200);
    expect(mine.body.bookings.some((b: any) => b.id === bookingId)).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 10 — SOS / security incident → staff acknowledges → resident sees it
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 10: SOS incident → staff acknowledges → status visible to resident", () => {
  let incidentId: string;

  it("guard raises an SOS incident → admins + security get notification rows", async () => {
    // NOTE: POST /guard/incidents is gated by canManageSecurity, so a resident
    // token cannot raise SOS over HTTP today (GuardService.reportIncident itself
    // supports resident reporters) — the guard raises it in this journey.
    const residentTry = await api(RESIDENT).post("/guard/incidents").send({ category: "sos" });
    expect(residentTry.status).toBe(403); // documents the missing resident SOS trigger

    const res = await api(GUARD).post("/guard/incidents").send({
      category: "sos", description: `E2E medical emergency ${RUN}`, severity: "critical",
    });
    expect(res.status).toBe(201);
    incidentId = res.body.incident.id;
    created.incidentIds.push(incidentId);
    expect(res.body.incident.status).toBe("open");

    const adminRows = await notifWhere(
      `society_id = $1 AND user_id = 'sunkist-admin-001' AND data->>'incidentId' = $2`, [SOC, incidentId]
    );
    expect(adminRows.some((r: any) => r.title.startsWith("SOS"))).toBe(true);
  });

  it("staff acknowledges (investigating) then resolves → status visible to resident", async () => {
    const ack = await api(GUARD).patch(`/guard/incidents/${incidentId}/status`).send({ status: "investigating" });
    expect(ack.status).toBe(200);
    expect(ack.body.incident.status).toBe("investigating");

    // Residents can read incident status through the same tenant-scoped list.
    const seen = await api(RESIDENT).get("/guard/incidents?status=investigating");
    expect(seen.status).toBe(200);
    expect(seen.body.incidents.some((i: any) => i.id === incidentId)).toBe(true);

    const done = await api(GUARD).patch(`/guard/incidents/${incidentId}/status`).send({ status: "resolved" });
    expect(done.status).toBe(200);

    const rows = await notifWhere(`society_id = $1 AND data->>'incidentId' = $2`, [SOC, incidentId]);
    expect(rows.some((r: any) => r.title === "Incident investigating")).toBe(true);
    expect(rows.some((r: any) => r.title === "Incident resolved")).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 11 — Dues reminders: once per invoice per day
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 11: overdue invoice → reminders run → no same-day duplicate", () => {
  const INV_NO = `E2E-INV-OD-${RUN}`;
  let invoiceId: string;

  it("admin publishes an overdue invoice and runs reminders → resident notified once", async () => {
    const createRes = await api(FIN_ADMIN).post("/finance/invoices").send({
      number: INV_NO, memberId: finResidentMemberId, dueDate: "2026-01-31",
      lines: [{ description: "Overdue maintenance", unitPriceMinor: 40000 }],
    });
    expect(createRes.status).toBe(201);
    invoiceId = createRes.body.invoice.id;
    await api(FIN_ADMIN).post(`/finance/invoices/${invoiceId}/publish`).expect(200);

    const run1 = await api(FIN_ADMIN).post("/finance/reminders/run");
    expect(run1.status).toBe(200);
    expect(run1.body.invoices.some((i: any) => i.invoiceId === invoiceId && i.notified >= 1)).toBe(true);

    const rows = await notifWhere(
      `society_id = $1 AND user_id = $2 AND type = 'billing' AND title = 'Dues reminder'`,
      [FIN_SOC, `e2e-fin-res-${RUN}`]
    );
    expect(rows.length).toBe(1);
    expect(rows[0].data.deeplink).toBe("/resident/payments");
  });

  it("a second run the same day does not duplicate the reminder", async () => {
    const run2 = await api(FIN_ADMIN).post("/finance/reminders/run");
    expect(run2.status).toBe(200);
    expect(run2.body.invoices.some((i: any) => i.invoiceId === invoiceId)).toBe(false);

    const rows = await notifWhere(
      `society_id = $1 AND user_id = $2 AND type = 'billing' AND title = 'Dues reminder'`,
      [FIN_SOC, `e2e-fin-res-${RUN}`]
    );
    expect(rows.length).toBe(1); // still exactly one
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Journey 12 — Tenant isolation: society-B admin cannot read hubtown-sunkist
// ─────────────────────────────────────────────────────────────────────────────
describe("Journey 12: society-B admin cannot read hubtown-sunkist data", () => {
  it("cannot fetch a sunkist notice by id (404) and never sees it in lists", async () => {
    expect(seededNoticeId).toBeTruthy();
    const byId = await api(B_ADMIN).get(`/notices-v2/${seededNoticeId}`);
    expect(byId.status).toBe(404);

    const list = await api(B_ADMIN).get("/notices-v2");
    expect(list.status).toBe(200);
    expect(list.body.notices.some((n: any) => n.id === seededNoticeId)).toBe(false);
  });

  it("cannot fetch a sunkist invoice by id and invoice list leaks nothing", async () => {
    const sunkistInvoice = (await db.query(
      `SELECT id, number FROM invoices WHERE society_id = $1 ORDER BY created_at LIMIT 1`, [SOC]
    )).rows[0];
    expect(sunkistInvoice).toBeTruthy();

    const byId = await api(B_ADMIN).get(`/finance/invoices/${sunkistInvoice.id}`);
    expect(byId.status).toBe(404);

    const list = await api(B_ADMIN).get("/finance/invoices");
    expect(list.status).toBe(200);
    expect(list.body.invoices.some((i: any) => i.id === sunkistInvoice.id)).toBe(false);
    expect(list.body.invoices.some((i: any) => i.number === sunkistInvoice.number)).toBe(false);
  });

  it("member list shows no sunkist users; sunkist member detail is not readable", async () => {
    const list = await api(B_ADMIN).get("/members-v2");
    expect(list.status).toBe(200);
    expect(list.body.members.some((m: any) => String(m.user_id || "").startsWith("sunkist-"))).toBe(false);

    const byId = await api(B_ADMIN).get(`/members-v2/${memberRes1}`);
    // Convention: cross-tenant reads must not return the row (404 / null body).
    expect([200, 404]).toContain(byId.status);
    if (byId.status === 200) expect(byId.body.member).toBeFalsy();
  });

  it("cannot see sunkist visitors or act on them", async () => {
    const sunkistVisitor = created.visitorIds[0];
    expect(sunkistVisitor).toBeTruthy();

    const list = await api(B_ADMIN).get("/guard/visitors");
    expect(list.status).toBe(200);
    expect(list.body.visitors.some((v: any) => v.id === sunkistVisitor)).toBe(false);

    const act = await api(B_ADMIN).post(`/guard/visitors/${sunkistVisitor}/check-out`);
    expect(act.status).toBe(404); // scoped update matches nothing
  });
});
