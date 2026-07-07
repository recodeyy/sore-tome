import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { StructureService } from "../src/services/structure/StructureService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-str-${Date.now()}`;
const SOC_B = `test-str-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM units WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM blocks WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM wings WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("StructureService (integration)", () => {
  it("builds wing -> block -> unit and rejects duplicate unit number", async () => {
    const wing = await StructureService.createWing(SOC, { name: "A" });
    const block = await StructureService.createBlock(SOC, { name: "A-Tower", wingId: wing.id });
    const unit = await StructureService.createUnit(SOC, { number: "A-101", blockId: block.id, wingId: wing.id, unitType: "2BHK" });
    expect(unit.occupancy_status).toBe("vacant");
    await expect(StructureService.createUnit(SOC, { number: "A-101" })).rejects.toMatchObject({ code: "ALREADY_EXISTS" });
  });

  it("sets occupancy, occupies the unit, and keeps history on owner change", async () => {
    const unit = await StructureService.createUnit(SOC, { number: "B-201" });
    await StructureService.setOccupancy(SOC, unit.id, { residentId: "owner-1", relation: "owner" });
    let units = await StructureService.listUnits(SOC, { occupancyStatus: "occupied" });
    expect(units.find((u: any) => u.id === unit.id)?.ownership_status).toBe("owned");

    // New owner closes the previous current owner occupancy.
    await StructureService.setOccupancy(SOC, unit.id, { residentId: "owner-2", relation: "owner" });
    const history = await StructureService.unitOccupancyHistory(SOC, unit.id);
    expect(history.length).toBe(2);
    const current = history.filter((h: any) => h.to_date === null && h.relation === "owner");
    expect(current.length).toBe(1);
    expect(current[0].resident_id).toBe("owner-2");
  });

  it("vacating the last occupant marks the unit vacant", async () => {
    const unit = await StructureService.createUnit(SOC, { number: "C-301" });
    await StructureService.setOccupancy(SOC, unit.id, { residentId: "t-1", relation: "tenant" });
    const out = await StructureService.vacateUnit(SOC, unit.id, "tenant");
    expect(out.vacant).toBe(true);
    const units = await StructureService.listUnits(SOC, { occupancyStatus: "vacant" });
    expect(units.find((u: any) => u.id === unit.id)).toBeTruthy();
  });

  it("does not leak structure across tenants", async () => {
    const wing = await StructureService.createWing(SOC, { name: "ISO" });
    const listB = await StructureService.listWings(SOC_B);
    expect(listB.find((w: any) => w.id === wing.id)).toBeUndefined();
    await expect(StructureService.updateWing(SOC_B, wing.id, { name: "x" })).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
