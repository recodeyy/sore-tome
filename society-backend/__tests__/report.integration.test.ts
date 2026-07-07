import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ReportService } from "../src/services/reports/ReportService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-rep-${Date.now()}`;
const SOC_B = `test-rep-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM report_schedules WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM report_jobs WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM report_templates WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("ReportService (integration)", () => {
  it("creates a template and rejects duplicate names", async () => {
    const tpl = await ReportService.createTemplate(SOC, { name: "Monthly Finance", kind: "finance", format: "pdf" });
    expect(tpl.kind).toBe("finance");
    expect(tpl.is_active).toBe(true);
    await expect(ReportService.createTemplate(SOC, { name: "Monthly Finance" }))
      .rejects.toMatchObject({ code: "ALREADY_EXISTS" });
  });

  it("runs a job through queued -> running -> completed", async () => {
    const tpl = await ReportService.createTemplate(SOC, { name: "Run-OK", kind: "complaints" });
    const job = await ReportService.enqueueJob(SOC, { templateId: tpl.id, params: { month: "2026-06" }, requestedBy: "u-1" });
    expect(job.status).toBe("queued");
    expect(job.kind).toBe("complaints");

    const running = await ReportService.markRunning(SOC, job.id);
    expect(running.status).toBe("running");

    const done = await ReportService.completeJob(SOC, job.id, "https://files/report.pdf");
    expect(done.status).toBe("completed");
    expect(done.file_url).toBe("https://files/report.pdf");

    // Cannot re-run a completed job.
    await expect(ReportService.markRunning(SOC, job.id)).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("fails a job and records the error", async () => {
    const job = await ReportService.enqueueJob(SOC, { kind: "staff" });
    await ReportService.markRunning(SOC, job.id);
    const failed = await ReportService.failJob(SOC, job.id, "boom");
    expect(failed.status).toBe("failed");
    expect(failed.error).toBe("boom");
    await expect(ReportService.completeJob(SOC, job.id, "x")).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("lists jobs filtered by status", async () => {
    const jobs = await ReportService.listJobs(SOC, { status: "completed" });
    expect(jobs.every((j: any) => j.status === "completed")).toBe(true);
  });

  it("creates a schedule and returns it when due", async () => {
    const tpl = await ReportService.createTemplate(SOC, { name: "Sched-1", kind: "occupancy" });
    const past = new Date(Date.now() - 60_000).toISOString();
    await ReportService.createSchedule(SOC, tpl.id, "0 0 * * *", past);

    const future = new Date(Date.now() + 60_000).toISOString();
    const due = await ReportService.dueSchedules(SOC, future);
    expect(due.find((sch: any) => sch.template_id === tpl.id)).toBeTruthy();

    // Not yet due relative to an earlier instant.
    const earlier = new Date(Date.now() - 120_000).toISOString();
    const none = await ReportService.dueSchedules(SOC, earlier);
    expect(none.find((sch: any) => sch.template_id === tpl.id)).toBeUndefined();
  });

  it("does not leak reports across tenants", async () => {
    const tpl = await ReportService.createTemplate(SOC, { name: "ISO-rep" });
    const job = await ReportService.enqueueJob(SOC, { templateId: tpl.id });
    await expect(ReportService.getJob(SOC_B, job.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
    await expect(ReportService.markRunning(SOC_B, job.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
    const listB = await ReportService.listTemplates(SOC_B);
    expect(listB.find((t: any) => t.id === tpl.id)).toBeUndefined();
  });
});
