import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { StaffService, toCsv } from "../src/services/staff/StaffService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-stfpk-${Date.now()}`;
const SOC_B = `test-stfpk-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM payroll_runs WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM staff WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM society_holidays WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM leave_types WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("Staff pack (integration)", () => {
  it("71 — sets and checks staff permissions", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Guard P", permissions: ["visitor.manage"] });
    expect(await StaffService.hasPermission(SOC, st.id, "visitor.manage")).toBe(true);
    expect(await StaffService.hasPermission(SOC, st.id, "payroll.approve")).toBe(false);
    await StaffService.setPermissions(SOC, st.id, ["visitor.manage", "parcel.manage"]);
    expect(await StaffService.hasPermission(SOC, st.id, "parcel.manage")).toBe(true);
  });

  it("76 — computes overtime, late minutes and holiday flag", async () => {
    const st = await StaffService.createStaff(SOC, {
      name: "OT Worker", standardShiftMinutes: 480, lateGraceMinutes: 10, overtimeRateMinor: 12000,
    });
    await StaffService.addHoliday(SOC, "2026-06-03", "Founders Day");
    // Insert a controlled attendance row (check-in 09:30 UTC, 9h worked).
    const ins = await db.query(
      `INSERT INTO attendance_entries (society_id, staff_id, work_date, check_in_at, check_out_at, worked_minutes, status, source)
       VALUES ($1,$2,'2026-06-03', '2026-06-03 09:30:00+00', '2026-06-03 18:30:00+00', 540, 'present','manual') RETURNING *`,
      [SOC, st.id]
    );
    // Derive the stored check-in minute-of-day (tz-independent) for a deterministic late check.
    const ci = new Date(ins.rows[0].check_in_at);
    const ciMins = ci.getUTCHours() * 60 + ci.getUTCMinutes();
    const computed = await StaffService.computeOvertimeAndLate(SOC, ins.rows[0].id, { shiftStartMinutes: ciMins });
    expect(computed.overtime_minutes).toBe(60); // 540 worked - 480 std
    expect(computed.is_holiday).toBe(true);
    expect(computed.late_minutes).toBe(0); // shift starts exactly at check-in, within grace
    // Late case: shift started 30m before check-in, grace 10m -> 20m late.
    const late = await StaffService.computeOvertimeAndLate(SOC, ins.rows[0].id, { shiftStartMinutes: ciMins - 30 });
    expect(late.late_minutes).toBe(20);

    const ot = await StaffService.overtimeReport(SOC, "2026-06");
    const row = ot.find((r: any) => r.staff_id === st.id);
    expect(row.overtime_minutes).toBe(60);
    expect(Number(row.overtime_value_minor)).toBe(12000); // 60min * 12000/60
  });

  it("77 — KYC/cert expiry reminder query finds expiring docs", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Cert Holder" });
    await StaffService.addDocument(SOC, { staffId: st.id, docType: "certification", title: "Fire Safety", expiresOn: "2026-06-20" });
    await StaffService.addDocument(SOC, { staffId: st.id, docType: "contract", title: "Long Contract", expiresOn: "2030-01-01" });
    const exp = await StaffService.expiringDocuments(SOC, 30); // ref date 2026-06-16
    const titles = exp.filter((d: any) => d.staff_id === st.id).map((d: any) => d.title);
    expect(titles).toContain("Fire Safety");
    expect(titles).not.toContain("Long Contract");
  });

  it("79 — report aggregations and CSV export", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Reportee", monthlyWageMinor: 1000000 });
    await db.query(
      `INSERT INTO attendance_entries (society_id, staff_id, work_date, worked_minutes, status, source)
       VALUES ($1,$2,'2026-06-05', 480, 'present','manual')`,
      [SOC, st.id]
    );
    const rep = await StaffService.attendanceReport(SOC, "2026-06");
    const row = rep.find((r: any) => r.staff_id === st.id);
    expect(row.present_days).toBe(1);

    const staffing = await StaffService.staffingReport(SOC);
    expect(staffing.total).toBeGreaterThan(0);

    const csv = toCsv([{ a: 1, b: "=cmd" }]);
    expect(csv).toContain("\"'=cmd\""); // formula injection neutralized
  });

  it("isolation — pack features are tenant-scoped", async () => {
    const st = await StaffService.createStaff(SOC, { name: "Tenant A" });
    await expect(StaffService.setPermissions(SOC_B, st.id, ["x"])).rejects.toMatchObject({ code: "NOT_FOUND" });
    await expect(StaffService.addDocument(SOC_B, { staffId: st.id, docType: "kyc", title: "X" })).rejects.toMatchObject({ code: "NOT_FOUND" });
    const expB = await StaffService.expiringDocuments(SOC_B, 365);
    expect(expB.find((d: any) => d.staff_id === st.id)).toBeUndefined();
  });
});
