import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { AnalyticsService } from "../src/services/dashboard/AnalyticsService";
import { SearchService } from "../src/services/dashboard/SearchService";
import { ActivityService } from "../src/services/dashboard/ActivityService";
import { PreferenceService } from "../src/services/dashboard/PreferenceService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-dash-${Date.now()}`;
const SOC_B = `test-dash-b-${Date.now()}`;

beforeAll(async () => {
  // Seed minimal tenant-scoped data the analytics/search services read from.
  await db.query(
    `INSERT INTO members (society_id, name, status) VALUES
       ($1,'Pending Pat','pending'),($1,'Approved Amy','approved')`,
    [SOC]
  );
  await db.query(
    `INSERT INTO members (society_id, name, status) VALUES ($1,'Other Society Member','pending')`,
    [SOC_B]
  );
  await db.query(
    `INSERT INTO staff (society_id, name, status) VALUES ($1,'Guard Gita','active')`,
    [SOC]
  );
});

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM members WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM staff WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM dashboard_preferences WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("Dashboard analytics (integration)", () => {
  it("returns tenant-scoped summary counters", async () => {
    const s = await AnalyticsService.summary(SOC);
    expect(s.pendingApprovals).toBe(1); // only SOC's pending member, not SOC_B's
    expect(s.staffOnDuty).toBe(1);
    expect(typeof s.todaysCollectionMinor).toBe("number");
    expect(typeof s.openComplaints).toBe("number");
  });

  it("does not count another tenant's data", async () => {
    const sB = await AnalyticsService.summary(SOC_B);
    expect(sB.pendingApprovals).toBe(1); // only SOC_B's own
    expect(sB.staffOnDuty).toBe(0);
  });

  it("returns a bounded trends window with collections and expenses arrays", async () => {
    const t = await AnalyticsService.trends(SOC);
    expect(Array.isArray(t.collections)).toBe(true);
    expect(Array.isArray(t.expenses)).toBe(true);
    expect(t.from <= t.to).toBe(true);
  });

  it("swaps reversed date ranges", async () => {
    const t = await AnalyticsService.trends(SOC, "2026-03-31", "2026-01-01");
    expect(t.from).toBe("2026-01-01");
    expect(t.to).toBe("2026-03-31");
  });

  it("returns an alerts array", async () => {
    const a = await AnalyticsService.alerts(SOC);
    expect(Array.isArray(a)).toBe(true);
  });
});

describe("Dashboard global search (integration)", () => {
  it("finds members by name, tenant-scoped", async () => {
    const r = await SearchService.search(SOC, "Approved");
    const hit = r.results.find((h) => h.type === "member" && h.label === "Approved Amy");
    expect(hit).toBeDefined();
  });

  it("does not leak results across tenants", async () => {
    const r = await SearchService.search(SOC, "Other Society Member");
    expect(r.results.length).toBe(0);
  });

  it("returns empty results for a blank query", async () => {
    const r = await SearchService.search(SOC, "   ");
    expect(r.results).toEqual([]);
  });
});

describe("Dashboard activity feed (integration)", () => {
  it("returns recent items, newest first, tenant-scoped", async () => {
    const { items } = await ActivityService.feed(SOC);
    expect(Array.isArray(items)).toBe(true);
    expect(items.length).toBeGreaterThanOrEqual(2); // the two seeded members
    // sorted descending by timestamp
    for (let i = 1; i < items.length; i++) {
      expect(items[i - 1].at >= items[i].at).toBe(true);
    }
    // no item references SOC_B's member
    expect(items.find((it) => it.title.includes("Other Society Member"))).toBeUndefined();
  });

  it("respects the limit cap", async () => {
    const { items } = await ActivityService.feed(SOC, 1);
    expect(items.length).toBe(1);
  });
});

describe("Dashboard preferences (integration)", () => {
  it("returns defaults when nothing is saved", async () => {
    const p = await PreferenceService.get(SOC, "admin-x");
    expect(p.widgets).toEqual([]);
  });

  it("saves and reloads per-admin widgets and filters, tenant-scoped", async () => {
    await PreferenceService.save(SOC, "admin-1", {
      widgets: [{ id: "collections", w: 2 }],
      savedFilters: [{ name: "overdue", q: "status=overdue" }],
    });
    const p = await PreferenceService.get(SOC, "admin-1");
    expect(p.widgets[0].id).toBe("collections");
    expect(p.savedFilters[0].name).toBe("overdue");

    // upsert overwrites, not duplicates
    await PreferenceService.save(SOC, "admin-1", { widgets: [{ id: "alerts" }] });
    const p2 = await PreferenceService.get(SOC, "admin-1");
    expect(p2.widgets.length).toBe(1);
    expect(p2.widgets[0].id).toBe("alerts");

    // another tenant's admin-1 is isolated
    const pB = await PreferenceService.get(SOC_B, "admin-1");
    expect(pB.widgets).toEqual([]);
  });
});
