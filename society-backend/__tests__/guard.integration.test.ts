import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { GuardService } from "../src/services/guard/GuardService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-guard-${Date.now()}`;
const SOC_B = `test-guard-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM visitor_entries WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM gate_passes WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM patrol_logs WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM security_incidents WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("Guard / Security (integration)", () => {
  it("visitor check-in -> check-out lifecycle; no double check-out", async () => {
    const v = await GuardService.checkInVisitor(SOC, { name: "Alice", phone: "999", purpose: "Meeting", guardId: "g1" });
    expect(v.status).toBe("checked_in");
    expect(v.checked_in_at).toBeTruthy();

    const out = await GuardService.checkOutVisitor(SOC, v.id, "g1");
    expect(out.status).toBe("checked_out");
    expect(out.checked_out_at).toBeTruthy();

    await expect(GuardService.checkOutVisitor(SOC, v.id, "g1")).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("deny only from expected; lists by status", async () => {
    const e = await db.query(
      `INSERT INTO visitor_entries (society_id, name, status) VALUES ($1,'Bob','expected') RETURNING *`, [SOC]
    );
    const denied = await GuardService.denyVisitor(SOC, e.rows[0].id, "g1");
    expect(denied.status).toBe("denied");
    const list = await GuardService.listVisitors(SOC, { status: "denied" });
    expect(list.some((r: any) => r.id === denied.id)).toBe(true);
  });

  it("gate pass: valid pass consumes, expired pass rejected, used pass rejected", async () => {
    const future = new Date(Date.now() + 3600_000).toISOString();
    const ok = await GuardService.createGatePass(SOC, { type: "delivery", code: "PASS-OK", validUntil: future });
    const used = await GuardService.validateGatePass(SOC, ok.code);
    expect(used.status).toBe("used");
    await expect(GuardService.validateGatePass(SOC, ok.code)).rejects.toMatchObject({ code: "INVALID_STATE" });

    const past = new Date(Date.now() - 1000).toISOString();
    await GuardService.createGatePass(SOC, { type: "cab", code: "PASS-EXP", validUntil: past });
    await expect(GuardService.validateGatePass(SOC, "PASS-EXP")).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("incident create + list + status", async () => {
    const inc = await GuardService.reportIncident(SOC, { category: "trespass", description: "fence", severity: "high", guardId: "g1" });
    expect(inc.status).toBe("open");
    const upd = await GuardService.updateIncidentStatus(SOC, inc.id, "resolved");
    expect(upd.status).toBe("resolved");
    const list = await GuardService.listIncidents(SOC, {});
    expect(list.some((r: any) => r.id === inc.id)).toBe(true);
  });

  it("patrol log records and lists", async () => {
    const p = await GuardService.logPatrol(SOC, { checkpoint: "Gate 1", note: "all clear", guardId: "g1" });
    expect(p.checkpoint).toBe("Gate 1");
    const list = await GuardService.listPatrols(SOC, {});
    expect(list.some((r: any) => r.id === p.id)).toBe(true);
  });

  it("cross-tenant isolation: society B cannot check out society A's visitor", async () => {
    const v = await GuardService.checkInVisitor(SOC, { name: "Carol", guardId: "gA" });
    await expect(GuardService.checkOutVisitor(SOC_B, v.id, "gB")).rejects.toMatchObject({ code: "NOT_FOUND" });
    // still checked in under A
    const stillIn = await GuardService.listVisitors(SOC, { status: "checked_in" });
    expect(stillIn.some((r: any) => r.id === v.id)).toBe(true);
  });
});
