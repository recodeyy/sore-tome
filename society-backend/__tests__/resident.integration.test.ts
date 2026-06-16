import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { db, dbManager } from "../src/shared/Database";
import { ResidentService } from "../src/services/resident/ResidentService";
import { FinanceService } from "../src/services/finance/FinanceService";
import { PollService } from "../src/services/polls/PollService";

const SOC = `test-res-${Date.now()}`;
const SOC2 = `test-res2-${Date.now()}`;
const UNIT_A = "11111111-1111-1111-1111-111111111111";
const UNIT_B = "22222222-2222-2222-2222-222222222222";
const USER_A = "user-a";
const USER_B = "user-b";

async function mkMember(soc: string, userId: string, unitId: string) {
  const { rows } = await db.query(
    `INSERT INTO members (society_id, user_id, name, unit_id, status)
     VALUES ($1,$2,$3,$4,'approved') RETURNING *`,
    [soc, userId, `M-${userId}`, unitId]
  );
  return rows[0];
}

async function mkPublishedInvoice(soc: string, unitId: string, amountMinor: number) {
  const inv = await FinanceService.createInvoice(soc, {
    number: `INV-${unitId.slice(0, 8)}-${Date.now()}`,
    unitId,
    dueDate: "2026-05-01",
    lines: [{ description: "Maintenance", unitPriceMinor: amountMinor }],
  });
  await FinanceService.publishInvoice(soc, inv.id);
  return inv;
}

beforeAll(async () => {
  await mkMember(SOC, USER_A, UNIT_A);
  await mkMember(SOC, USER_B, UNIT_B);
  await mkMember(SOC2, USER_A, UNIT_A); // same user id, different tenant + unmatched
});

afterAll(async () => {
  for (const soc of [SOC, SOC2]) {
    await db.query(`DELETE FROM payment_allocations WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM payments WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM receipts WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM invoice_lines WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM invoices WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM journal_lines WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM journal_entries WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM chart_of_accounts WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM resident_visitors WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM complaints WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM votes WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM poll_options WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM poll_eligibility WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM polls WHERE society_id = $1`, [soc]);
    await db.query(`DELETE FROM members WHERE society_id = $1`, [soc]);
  }
  await dbManager.close();
});

describe("ResidentService (integration)", () => {
  it("derives the caller's own unit from the member record", async () => {
    const ctx = await ResidentService.resolveContext(SOC, USER_A);
    expect(ctx.unitId).toBe(UNIT_A);
    expect(ctx.memberId).toBeTruthy();
  });

  it("denies users with no active membership", async () => {
    await expect(ResidentService.resolveContext(SOC, "ghost")).rejects.toMatchObject({ code: "NOT_A_MEMBER" });
  });

  it("scopes dues to the resident's own unit and never another unit", async () => {
    await mkPublishedInvoice(SOC, UNIT_A, 50000);
    await mkPublishedInvoice(SOC, UNIT_B, 99999);

    const ctxA = await ResidentService.resolveContext(SOC, USER_A);
    const dues = await ResidentService.dues(ctxA);
    expect(dues.totalOutstandingMinor).toBe(50000);
    expect(dues.items.every((i) => i.totalMinor === 50000)).toBe(true);
  });

  it("scopes complaints + payments per unit (no cross-unit leakage)", async () => {
    const ctxA = await ResidentService.resolveContext(SOC, USER_A);
    const ctxB = await ResidentService.resolveContext(SOC, USER_B);

    await ResidentService.raiseComplaint(ctxA, { title: "Leak", description: "Tap leaking" });
    const aComplaints = await ResidentService.complaints(ctxA);
    const bComplaints = await ResidentService.complaints(ctxB);
    expect(aComplaints.length).toBe(1);
    expect(bComplaints.length).toBe(0);

    // Pay unit B's invoice — must appear only for B.
    const invB = (await ResidentService.dues(ctxB)).items[0];
    await FinanceService.recordPayment(SOC, {
      idempotencyKey: `pay-${Date.now()}`,
      invoiceId: invB.invoiceId,
      amountMinor: 99999,
    });
    expect((await ResidentService.payments(ctxA)).length).toBe(0);
    expect((await ResidentService.payments(ctxB)).length).toBe(1);
  });

  it("cross-tenant isolation: same user id in another tenant sees different scope", async () => {
    // SOC2 member has UNIT_A but no SOC2 invoices/complaints.
    const ctx2 = await ResidentService.resolveContext(SOC2, USER_A);
    expect((await ResidentService.dues(ctx2)).totalOutstandingMinor).toBe(0);
    expect((await ResidentService.complaints(ctx2)).length).toBe(0);
  });

  it("pre-approves a visitor scoped to the unit", async () => {
    const ctxA = await ResidentService.resolveContext(SOC, USER_A);
    const ctxB = await ResidentService.resolveContext(SOC, USER_B);
    await ResidentService.preApproveVisitor(ctxA, { visitorName: "Courier", purpose: "Parcel" });
    expect((await ResidentService.visitors(ctxA)).length).toBe(1);
    expect((await ResidentService.visitors(ctxB)).length).toBe(0);
  });

  it("votes on a poll atomically with unit eligibility and rejects double vote", async () => {
    const ctxA = await ResidentService.resolveContext(SOC, USER_A);
    const poll = await PollService.createPoll(SOC, {
      title: "Paint colour",
      voteScope: "unit",
      options: [{ label: "Blue" }, { label: "Green" }],
    });
    await PollService.open(SOC, poll.id);
    const { rows: opts } = await db.query(
      `SELECT id FROM poll_options WHERE poll_id = $1 AND society_id = $2 ORDER BY position ASC LIMIT 1`,
      [poll.id, SOC]
    );
    const optId = opts[0].id;

    const v = await ResidentService.vote(ctxA, poll.id, optId);
    expect(v.id).toBeTruthy();
    await expect(ResidentService.vote(ctxA, poll.id, optId)).rejects.toMatchObject({ code: "ALREADY_VOTED" });
  });

  it("aggregates the dashboard from the resident's own data", async () => {
    const ctxA = await ResidentService.resolveContext(SOC, USER_A);
    const dash = await ResidentService.dashboard(ctxA);
    expect(dash.duesTotalMinor).toBe(50000);
    expect(dash.openComplaints).toBe(1);
    expect(typeof dash.upcomingBookings).toBe("number");
    expect(typeof dash.unreadNotices).toBe("number");
  });
});
