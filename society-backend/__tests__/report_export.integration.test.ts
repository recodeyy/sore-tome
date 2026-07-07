import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ReportService } from "../src/services/reports/ReportService";
import { PgAuditService } from "../src/services/audit/PgAuditService";
import { escapeCsvCell } from "../src/shared/csv";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-rexp-${Date.now()}`;
const SOC_B = `test-rexp-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM report_jobs WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM report_templates WHERE society_id = $1`, [sId]);
    // audit_logs is append-only; rows for test tenants are harmless and left in place.
  }
  await dbManager.close();
});

describe("Report generation (cap 91)", () => {
  it("generates a job: produces artifact, marks completed, sets retention", async () => {
    const job = await ReportService.enqueueJob(SOC, { kind: "occupancy", params: { units: 42, month: "2026-06" } });
    const done = await ReportService.generateJob(SOC, job.id, { retentionDays: 7 });
    expect(done.status).toBe("completed");
    expect(done.output_content).toContain("units");
    expect(done.expires_at).toBeTruthy();
    // retention ~7 days out
    const days = (new Date(done.expires_at).getTime() - Date.now()) / 86_400_000;
    expect(days).toBeGreaterThan(6);
    expect(days).toBeLessThan(8);

    // Cannot re-generate a finalized job.
    await expect(ReportService.generateJob(SOC, job.id)).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("downloads the artifact, tenant-scoped", async () => {
    const job = await ReportService.enqueueJob(SOC, { kind: "custom", params: { foo: "bar" } });
    await ReportService.generateJob(SOC, job.id);
    const art = await ReportService.getArtifact(SOC, job.id);
    expect(art.contentType).toBe("text/csv");
    expect(art.content).toContain("foo");
    // other tenant cannot read it
    await expect(ReportService.getArtifact(SOC_B, job.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
  });

  it("escapes CSV formula-injection in exported cells", async () => {
    const job = await ReportService.enqueueJob(SOC, { kind: "custom", params: { payload: "=1+2", note: "+cmd", at: "@x", dash: "-3" } });
    const done = await ReportService.generateJob(SOC, job.id);
    expect(done.output_content).toContain("'=1+2");
    expect(done.output_content).toContain("'+cmd");
    expect(done.output_content).toContain("'@x");
    expect(done.output_content).toContain("'-3");
    // unit-level check
    expect(escapeCsvCell("=HYPERLINK()")).toBe("'=HYPERLINK()");
    expect(escapeCsvCell("safe")).toBe("safe");
  });
});

describe("Audit export (cap 92)", () => {
  it("export is tenant-scoped and records its own audit event", async () => {
    await PgAuditService.record({ societyId: SOC, actorId: "u-1", action: "report.create", resource: "r1" });
    await PgAuditService.record({ societyId: SOC, actorId: "u-2", action: "member.update", resource: "m1", before: { x: 1 }, after: { x: 2 } });
    await PgAuditService.record({ societyId: SOC_B, actorId: "u-9", action: "should.not.leak" });

    const before = await PgAuditService.query(SOC);
    const csv = await PgAuditService.exportCsv(SOC, {}, { id: "admin-1", name: "Admin", ip: "1.2.3.4" });

    expect(csv).toContain("report.create");
    expect(csv).toContain("member.update");
    expect(csv).not.toContain("should.not.leak");

    // The export itself was recorded.
    const after = await PgAuditService.query(SOC);
    expect(after.length).toBe(before.length + 1);
    expect(after[0].action).toBe("audit.export");
    expect(after[0].actor_id).toBe("admin-1");
  });

  it("filters by actor and is cross-tenant isolated", async () => {
    const u1 = await PgAuditService.query(SOC, { actorId: "u-1" });
    expect(u1.every((r: any) => r.actor_id === "u-1")).toBe(true);
    const leak = await PgAuditService.query(SOC_B, { actorId: "u-1" });
    expect(leak.length).toBe(0);
  });

  it("audit_logs is append-only (no update/delete)", async () => {
    const row = await PgAuditService.record({ societyId: SOC, actorId: "u-x", action: "test.immutable" });
    await expect(db.query(`UPDATE audit_logs SET action = 'tampered' WHERE id = $1`, [row.id]))
      .rejects.toMatchObject({ message: expect.stringContaining("append-only") });
    await expect(db.query(`DELETE FROM audit_logs WHERE id = $1`, [row.id]))
      .rejects.toMatchObject({ message: expect.stringContaining("append-only") });
  });
});
