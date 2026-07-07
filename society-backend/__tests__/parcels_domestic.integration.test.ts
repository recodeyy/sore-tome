import "dotenv/config";
import { describe, it, expect, afterAll, beforeAll } from "@jest/globals";
import { ParcelService } from "../src/services/parcels/ParcelService";
import { DomesticHelpService } from "../src/services/domestic/DomesticHelpService";
import { db, dbManager } from "../src/shared/Database";
import { randomUUID } from "crypto";

const SOC = `test-pd-${Date.now()}`;
const UNIT = randomUUID(); // members.unit_id is a uuid column
const MEMBER_UID = `res-${Date.now()}`;
let MEMBER_ID = "";

const ctx = () => ({ societyId: SOC, userId: MEMBER_UID, memberId: MEMBER_ID, unitId: UNIT });

beforeAll(async () => {
  // A resident member linked to UNIT so unit-resident fan-out resolves a recipient.
  const m = await db.query(
    `INSERT INTO members (society_id, name, role, status, user_id, unit_id)
     VALUES ($1,'Test Resident','resident','approved',$2,$3) RETURNING id`,
    [SOC, MEMBER_UID, UNIT]
  );
  MEMBER_ID = m.rows[0].id;
});

afterAll(async () => {
  await db.query(`DELETE FROM domestic_help_logs WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM domestic_helpers WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM parcels WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM notifications WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM members WHERE society_id = $1`, [SOC]);
  await dbManager.close();
});

describe("Parcels (integration)", () => {
  it("guard logs a parcel -> resident notified with OTP; collect requires the OTP; idempotent", async () => {
    const p = await ParcelService.log(SOC, { unitId: UNIT, courier: "Amazon", description: "Box", loggedBy: "guard1" });
    expect(p.status).toBe("pending");
    expect(p.otp).toMatch(/^\d{6}$/);

    // resident was notified
    const notif = await db.query(
      `SELECT * FROM notifications WHERE society_id=$1 AND user_id=$2 AND type='parcel'`, [SOC, MEMBER_UID]
    );
    expect(notif.rows.length).toBeGreaterThan(0);

    // wrong OTP rejected
    await expect(ParcelService.collect(SOC, p.id, { otp: "000000", collectedBy: "guard1" }))
      .rejects.toMatchObject({ code: "INVALID_OTP" });

    // correct OTP collects
    const c = await ParcelService.collect(SOC, p.id, { otp: p.otp, collectedBy: "guard1" });
    expect(c.status).toBe("collected");
    expect(c.collected_at).toBeTruthy();

    // idempotent re-collect returns collected, does not throw
    const again = await ParcelService.collect(SOC, p.id, { otp: p.otp, collectedBy: "guard1" });
    expect(again.status).toBe("collected");
  });

  it("resident sees only their unit's parcels", async () => {
    await ParcelService.log(SOC, { unitId: UNIT, courier: "Flipkart", loggedBy: "guard1" });
    const mine = await ParcelService.listForUnit(SOC, UNIT);
    expect(mine.every((r: any) => r.unit_id === UNIT)).toBe(true);
    const other = await ParcelService.listForUnit(SOC, "some-other-unit");
    expect(other.length).toBe(0);
  });
});

describe("Domestic help (integration)", () => {
  it("add -> pause/revoke; revoked access blocks gate log; check-in notifies + history", async () => {
    const h = await DomesticHelpService.add(ctx(), { name: "Sita", helperType: "maid", phone: "888" });
    expect(h.access_status).toBe("active");

    // guard check-in notifies resident
    await DomesticHelpService.logAccess(SOC, h.id, "check_in", "guard1");
    const notif = await db.query(
      `SELECT * FROM notifications WHERE society_id=$1 AND user_id=$2 AND type='domestic_help'`, [SOC, MEMBER_UID]
    );
    expect(notif.rows.length).toBeGreaterThan(0);

    // history reflects it
    const hist = await DomesticHelpService.history(ctx(), h.id);
    expect(hist.some((l: any) => l.action === "check_in")).toBe(true);

    // pause then revoke; revoked blocks gate log
    await DomesticHelpService.updateStatus(ctx(), h.id, "paused");
    const revoked = await DomesticHelpService.updateStatus(ctx(), h.id, "revoked");
    expect(revoked.access_status).toBe("revoked");
    await expect(DomesticHelpService.logAccess(SOC, h.id, "check_in", "guard1"))
      .rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("owner isolation: another member cannot update someone else's helper", async () => {
    const h = await DomesticHelpService.add(ctx(), { name: "Ravi", helperType: "driver" });
    const otherCtx = { societyId: SOC, userId: "other-uid", memberId: "00000000-0000-0000-0000-000000000000", unitId: UNIT };
    await expect(DomesticHelpService.updateStatus(otherCtx as any, h.id, "revoked"))
      .rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
