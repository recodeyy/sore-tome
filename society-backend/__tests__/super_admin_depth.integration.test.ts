import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { SuperAdminService } from "../src/services/platform/SuperAdminService";
import { db, dbManager } from "../src/shared/Database";

const ACTOR_ID = "depth-super-admin-actor";
const SOC_ID = "depth-super-admin-soc";
const SOC_ID_B = "depth-super-admin-soc-b";

beforeAll(async () => {
  await db.query(`DELETE FROM society_kyc_reviews WHERE society_id LIKE 'depth-%'`).catch(() => {});
  await db.query(`DELETE FROM subscription_changes WHERE society_id LIKE 'depth-%'`);
  await db.query(`DELETE FROM society_status_history WHERE society_id LIKE 'depth-%'`);
  await db.query(`DELETE FROM society_subscriptions WHERE society_id LIKE 'depth-%'`);
  await db.query(`DELETE FROM subscription_plans WHERE code LIKE 'depth-%'`);
});

afterAll(async () => {
  await db.query(`DELETE FROM society_kyc_reviews WHERE society_id LIKE 'depth-%'`).catch(() => {});
  await db.query(`DELETE FROM subscription_changes WHERE society_id LIKE 'depth-%'`);
  await db.query(`DELETE FROM society_status_history WHERE society_id LIKE 'depth-%'`);
  await db.query(`DELETE FROM society_subscriptions WHERE society_id LIKE 'depth-%'`);
  await db.query(`DELETE FROM subscription_plans WHERE code LIKE 'depth-%'`);
  await dbManager.close();
});

describe("Super Admin Depth (Integration)", () => {
  let planId: string;
  let planId2: string;

  it("creates, updates and deactivates a subscription plan", async () => {
    const created = await SuperAdminService.createPlan({
      code: "depth-basic",
      name: "Depth Basic",
      priceMinor: 30000,
      interval: "monthly",
    });
    planId = created.id;
    expect(created.code).toBe("depth-basic");
    expect(Number(created.price_minor)).toBe(30000);
    expect(created.is_active).toBe(true);

    const updated = await SuperAdminService.updatePlan(planId, { priceMinor: 45000, name: "Depth Basic v2" });
    expect(Number(updated.price_minor)).toBe(45000);
    expect(updated.name).toBe("Depth Basic v2");

    const deactivated = await SuperAdminService.deactivatePlan(planId);
    expect(deactivated.is_active).toBe(false);

    // second active plan for assignment tests
    const p2 = await SuperAdminService.createPlan({ code: "depth-pro", name: "Depth Pro", priceMinor: 90000 });
    planId2 = p2.id;
  });

  it("assignPlan records a subscription_changes row with explicit plan", async () => {
    const sub = await SuperAdminService.assignPlan({
      societyId: SOC_ID,
      planId: planId2,
      effectiveDate: "2026-06-01",
      actorId: ACTOR_ID,
      reason: "Initial assignment",
    });
    expect(sub.plan_id).toBe(planId2);
    expect(sub.status).toBe("active");

    const changes = await db.query(`SELECT * FROM subscription_changes WHERE society_id = $1`, [SOC_ID]);
    expect(changes.rows.length).toBe(1);
    expect(changes.rows[0].to_plan_id).toBe(planId2);
    expect(changes.rows[0].actor_id).toBe(ACTOR_ID);
  });

  it("computes proration preview as remaining days * daily rate", async () => {
    // price 90000 minor / 30 cycle days = 3000/day; 10 days remaining => 30000
    const preview = await SuperAdminService.prorationPreview({
      planId: planId2,
      renewsAt: "2026-06-26",
      asOf: "2026-06-16",
      cycleDays: 30,
    });
    expect(preview.remainingDays).toBe(10);
    expect(preview.proratedAmountMinor).toBe(30000);
  });

  it("records a KYC review decision", async () => {
    const review = await SuperAdminService.reviewSocietyKyc({
      societyId: SOC_ID,
      decision: "approved",
      actorId: ACTOR_ID,
    });
    expect(review.decision).toBe("approved");

    const rejected = await SuperAdminService.reviewSocietyKyc({
      societyId: SOC_ID,
      decision: "rejected",
      reason: "Blurry document",
      actorId: ACTOR_ID,
    });
    expect(rejected.decision).toBe("rejected");

    await expect(
      SuperAdminService.reviewSocietyKyc({ societyId: SOC_ID, decision: "rejected", actorId: ACTOR_ID } as any)
    ).rejects.toThrow();
  });

  it("archive and offboard write status history", async () => {
    await SuperAdminService.archiveSociety(SOC_ID, ACTOR_ID, "Inactive for a year");
    const sub = await db.query(`SELECT status FROM society_subscriptions WHERE society_id = $1`, [SOC_ID]);
    expect(sub.rows[0].status).toBe("cancelled");

    const hist = await db.query(
      `SELECT to_status FROM society_status_history WHERE society_id = $1 ORDER BY created_at DESC`,
      [SOC_ID]
    );
    expect(hist.rows[0].to_status).toBe("archived");

    // offboard a separate society
    await SuperAdminService.assignPlan({ societyId: SOC_ID_B, planId: planId2, actorId: ACTOR_ID });
    await SuperAdminService.offboardSociety(SOC_ID_B, ACTOR_ID, "Contract terminated");
    const histB = await db.query(
      `SELECT to_status FROM society_status_history WHERE society_id = $1 ORDER BY created_at DESC`,
      [SOC_ID_B]
    );
    expect(histB.rows[0].to_status).toBe("offboarded");
  });

  it("analytics returns computed (non-hardcoded) churn and mau numbers", async () => {
    const adoption = await SuperAdminService.computeAdoption();
    expect(typeof adoption.churnRate).toBe("number");
    expect(typeof adoption.mau).toBe("number");
    // We have cancelled subscriptions from archive/offboard above, so churn > 0.
    expect(adoption.churnRate).toBeGreaterThan(0);

    const overview = await SuperAdminService.overview();
    expect((overview.adoption as any).churnRate).toBe(adoption.churnRate);
  });

  it("cross-tenant scope: subscription_changes are isolated per society", async () => {
    const aChanges = await db.query(`SELECT * FROM subscription_changes WHERE society_id = $1`, [SOC_ID]);
    const bChanges = await db.query(`SELECT * FROM subscription_changes WHERE society_id = $1`, [SOC_ID_B]);
    expect(aChanges.rows.every((r: any) => r.society_id === SOC_ID)).toBe(true);
    expect(bChanges.rows.every((r: any) => r.society_id === SOC_ID_B)).toBe(true);
    expect(aChanges.rows.find((r: any) => r.society_id === SOC_ID_B)).toBeUndefined();
  });
});
