import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { AssetService } from "../src/services/assets/AssetService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-ast-${Date.now()}`;
const SOC_B = `test-ast-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM amc_contracts WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM assets WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM spare_parts WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("AssetService (integration)", () => {
  it("rejects a duplicate asset tag in a society", async () => {
    await AssetService.createAsset(SOC, { tag: "LIFT-1", name: "Lift 1", type: "lift" });
    await expect(AssetService.createAsset(SOC, { tag: "LIFT-1", name: "Dup" })).rejects.toMatchObject({ code: "ALREADY_EXISTS" });
  });

  it("prevents duplicate open preventive work orders per schedule", async () => {
    const asset = await AssetService.createAsset(SOC, { tag: "GEN-1", name: "Generator", type: "generator" });
    const sch = await AssetService.createSchedule(SOC, { assetId: asset.id, title: "Oil change", intervalDays: 90, firstDueOn: "2026-07-01" });
    await AssetService.generateWorkOrderFromSchedule(SOC, sch.id);
    await expect(AssetService.generateWorkOrderFromSchedule(SOC, sch.id)).rejects.toMatchObject({ code: "DUPLICATE_WO" });
  });

  it("completing a preventive work order advances the schedule", async () => {
    const asset = await AssetService.createAsset(SOC, { tag: "PUMP-1", name: "Pump", type: "pump" });
    const sch = await AssetService.createSchedule(SOC, { assetId: asset.id, title: "Inspect", intervalDays: 30, firstDueOn: "2026-07-01" });
    const wo = await AssetService.generateWorkOrderFromSchedule(SOC, sch.id);
    await AssetService.completeWorkOrder(SOC, wo.id, { costMinor: 50000 });
    // Read the DATE as text so the assertion is timezone-safe (pg returns DATE as
    // a local-midnight Date, which toISOString() would shift across the IST boundary).
    const { rows } = await db.query(
      `SELECT to_char(next_due_on, 'YYYY-MM-DD') AS d FROM maintenance_schedules WHERE id = $1`,
      [sch.id]
    );
    expect(rows[0].d).toBe("2026-07-31");
  });

  it("a breakdown work order takes the asset down and completion restores it", async () => {
    const asset = await AssetService.createAsset(SOC, { tag: "CCTV-1", name: "CCTV", type: "cctv" });
    const wo = await AssetService.createWorkOrder(SOC, { assetId: asset.id, kind: "breakdown", title: "Camera dead" });
    let detail = await AssetService.getAsset(SOC, asset.id);
    expect(detail!.asset.status).toBe("down");
    await AssetService.completeWorkOrder(SOC, wo.id, {});
    detail = await AssetService.getAsset(SOC, asset.id);
    expect(detail!.asset.status).toBe("operational");
    expect(detail!.downtime[0].ended_at).toBeTruthy();
  });

  it("surfaces AMC contracts expiring soon and expires old ones", async () => {
    const asset = await AssetService.createAsset(SOC, { tag: "FIRE-1", name: "Fire panel", type: "fire" });
    await AssetService.createAmc(SOC, { assetId: asset.id, startDate: "2025-01-01", endDate: "2020-01-01", valueMinor: 100000 });
    const expired = await AssetService.expireAmc(SOC);
    expect(expired).toBeGreaterThanOrEqual(1);
  });

  it("does not leak assets across tenants", async () => {
    const asset = await AssetService.createAsset(SOC, { tag: "ISO-1", name: "Iso" });
    expect(await AssetService.getAsset(SOC_B, asset.id)).toBeNull();
    const listB = await AssetService.listAssets(SOC_B);
    expect(listB.find((a: any) => a.id === asset.id)).toBeUndefined();
  });
});
