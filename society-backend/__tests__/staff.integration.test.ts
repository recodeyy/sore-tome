import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { StaffService } from "../src/services/staff/StaffService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-stf-${Date.now()}`;
const SOC_B = `test-stf-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    // payroll_items.staff_id has no cascade, so clear payroll runs before staff.
    await db.query(`DELETE FROM payroll_runs WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM staff WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM leave_types WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("StaffService (integration)", () => {
  it("rejects a duplicate check-in for the same day", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Guard A", role: "guard" });
    await StaffService.checkIn(SOC, st.id, "2026-06-01");
    await expect(StaffService.checkIn(SOC, st.id, "2026-06-01")).rejects.toMatchObject({ code: "ALREADY_CHECKED_IN" });
    const out = await StaffService.checkOut(SOC, st.id, "2026-06-01");
    expect(out.check_out_at).toBeTruthy();
    expect(out.worked_minutes).toBeGreaterThanOrEqual(0);
  });

  it("prevents a roster conflict for the same staff/shift/day", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Guard B" });
    const shift = await StaffService.createShiftTemplate(SOC, { name: "Night", startMinutes: 1320, endMinutes: 1800 });
    await StaffService.assignRoster(SOC, { staffId: st.id, dutyDate: "2026-06-02", shiftTemplateId: shift.id });
    await expect(
      StaffService.assignRoster(SOC, { staffId: st.id, dutyDate: "2026-06-02", shiftTemplateId: shift.id })
    ).rejects.toMatchObject({ code: "ROSTER_CONFLICT" });
  });

  it("decrements leave balance on approval and blocks insufficient balance", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Cleaner" });
    const lt = await StaffService.createLeaveType(SOC, { name: "Casual", annualQuotaDays: 5 });
    await StaffService.ensureLeaveBalance(SOC, st.id, lt.id, 2026);
    const req = await StaffService.requestLeave(SOC, { staffId: st.id, leaveTypeId: lt.id, fromDate: "2026-06-10", toDate: "2026-06-12" }); // 3 days
    const approved = await StaffService.decideLeave(SOC, req.id, "approved", "u-admin");
    expect(approved.status).toBe("approved");

    const big = await StaffService.requestLeave(SOC, { staffId: st.id, leaveTypeId: lt.id, fromDate: "2026-07-01", toDate: "2026-07-05" }); // 5 days, only 2 left
    await expect(StaffService.decideLeave(SOC, big.id, "approved", "u-admin")).rejects.toMatchObject({ code: "INSUFFICIENT_BALANCE" });
  });

  it("generates payroll once per period and enforces maker-checker on approval", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Manager", monthlyWageMinor: 3000000 });
    const run = await StaffService.generatePayroll(SOC, "2026-05", "u-maker");
    expect(run.status).toBe("draft");
    expect(Number(run.net_minor)).toBeGreaterThan(0);
    // Re-run protection
    await expect(StaffService.generatePayroll(SOC, "2026-05", "u-maker")).rejects.toMatchObject({ code: "ALREADY_EXISTS" });
    // Maker cannot approve own run
    await expect(StaffService.approvePayroll(SOC, run.id, "u-maker")).rejects.toMatchObject({ code: "MAKER_CHECKER" });
    const approved = await StaffService.approvePayroll(SOC, run.id, "u-checker");
    expect(approved.status).toBe("approved");
    void st;
  });

  it("does not leak staff across tenants", async () => {
    const st = await StaffService.createStaff(SOC, { name: "A-only" });
    const listB = await StaffService.listStaff(SOC_B);
    expect(listB.find((x: any) => x.id === st.id)).toBeUndefined();
    await expect(StaffService.setStatus(SOC_B, st.id, "suspended")).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
