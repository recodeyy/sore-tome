import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ParkingService } from "../src/services/parking/ParkingService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-prk-${Date.now()}`;
const SOC_B = `test-prk-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM parking_violations WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM visitor_parking WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM parking_requests WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM parking_allocations WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM vehicles WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM parking_slots WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("ParkingService (integration)", () => {
  it("allows only one active allocation per slot", async () => {
    const slot = await ParkingService.createSlot(SOC, { code: "A-1" });
    await ParkingService.allocate(SOC, { slotId: slot.id, allocatedTo: "u1" });
    await expect(ParkingService.allocate(SOC, { slotId: slot.id, allocatedTo: "u2" })).rejects.toMatchObject({ code: "SLOT_TAKEN" });
  });

  it("lets exactly one of two concurrent allocations win the same slot", async () => {
    const slot = await ParkingService.createSlot(SOC, { code: "A-2" });
    const results = await Promise.allSettled([
      ParkingService.allocate(SOC, { slotId: slot.id, allocatedTo: "x" }),
      ParkingService.allocate(SOC, { slotId: slot.id, allocatedTo: "y" }),
    ]);
    expect(results.filter((r) => r.status === "fulfilled").length).toBe(1);
    expect(results.filter((r) => r.status === "rejected").length).toBe(1);
  });

  it("releases a slot and promotes the oldest waiting request", async () => {
    const slot = await ParkingService.createSlot(SOC, { code: "A-3" });
    const alloc = await ParkingService.allocate(SOC, { slotId: slot.id, allocatedTo: "owner" });
    const req = await ParkingService.requestSlot(SOC, { requestedBy: "waiter", unitId: "U-9" });

    const out = await ParkingService.release(SOC, alloc.id);
    expect(out.promoted).toBeTruthy();
    expect(out.promoted!.requestId).toBe(req.id);

    const reqs = await ParkingService.listRequests(SOC, { status: "allocated" });
    expect(reqs.find((r: any) => r.id === req.id)).toBeTruthy();
  });

  it("rejects a duplicate vehicle plate in the same society", async () => {
    await ParkingService.registerVehicle(SOC, { plate: "MH12 AB 1234", ownerId: "u1" });
    await expect(ParkingService.registerVehicle(SOC, { plate: "mh12ab1234" })).rejects.toMatchObject({ code: "ALREADY_EXISTS" });
  });

  it("expires visitor passes past their validity", async () => {
    await ParkingService.createVisitorPass(SOC, { plate: "GUEST1", validUntil: "2020-01-01T00:00:00Z" });
    const n = await ParkingService.expireVisitorPasses(SOC);
    expect(n).toBeGreaterThanOrEqual(1);
  });

  it("does not leak slots across tenants", async () => {
    const slot = await ParkingService.createSlot(SOC, { code: "ISO-1" });
    const listB = await ParkingService.listSlots(SOC_B);
    expect(listB.find((s: any) => s.id === slot.id)).toBeUndefined();
  });
});
