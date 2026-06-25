import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ComplaintService } from "../src/services/complaints/ComplaintService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-esc-${Date.now()}`;
const SOC_B = `test-esc-b-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    await db.query(`DELETE FROM complaints WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

/** Force a complaint past its SLA by backdating due_at. */
async function makeOverdue(id: string) {
  await db.query(`UPDATE complaints SET due_at = now() - interval '1 hour' WHERE id = $1`, [id]);
}

describe("Complaint escalation worker (cap 65)", () => {
  it("escalates a breached complaint and is idempotent for the same breach", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Overdue", description: "x" }, "u-r");
    await makeOverdue(c.id);

    const r1 = await ComplaintService.runEscalations(SOC);
    expect(r1.escalated).toBeGreaterThanOrEqual(1);

    const rows1 = await db.query(`SELECT * FROM complaint_escalations WHERE complaint_id = $1`, [c.id]);
    expect(rows1.rows.length).toBe(1);
    expect(rows1.rows[0].level).toBe(1);

    const breached = await db.query(`SELECT sla_breached FROM complaints WHERE id = $1`, [c.id]);
    expect(breached.rows[0].sla_breached).toBe(true);

    // Re-run for the same breach window — no duplicate escalation row.
    await ComplaintService.runEscalations(SOC);
    const rows2 = await db.query(`SELECT * FROM complaint_escalations WHERE complaint_id = $1`, [c.id]);
    expect(rows2.rows.length).toBe(1);
  });

  it("does not escalate resolved/closed complaints", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Done", description: "x" }, "u-r");
    await makeOverdue(c.id);
    await ComplaintService.changeStatus(SOC, c.id, "resolved", "u-admin");
    await ComplaintService.runEscalations(SOC);
    const rows = await db.query(`SELECT * FROM complaint_escalations WHERE complaint_id = $1`, [c.id]);
    expect(rows.rows.length).toBe(0);
  });

  it("scopes escalations by tenant", async () => {
    const c = await ComplaintService.createComplaint(SOC_B, { title: "B-overdue", description: "x" }, "u-b");
    await makeOverdue(c.id);
    // Running for SOC must not touch SOC_B's complaint.
    await ComplaintService.runEscalations(SOC);
    const rows = await db.query(`SELECT * FROM complaint_escalations WHERE complaint_id = $1`, [c.id]);
    expect(rows.rows.length).toBe(0);
  });
});

describe("Complaint attachments (cap 67)", () => {
  it("adds and lists attachments scoped by society", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Photo", description: "x" }, "u-r");
    const a = await ComplaintService.addAttachment(SOC, c.id, {
      fileUrl: "https://cdn/x.jpg", mime: "image/jpeg", kind: "before", uploadedBy: "u-r",
    });
    expect(a.file_url).toBe("https://cdn/x.jpg");
    expect(a.scan_status).toBe("pending");

    const list = await ComplaintService.listAttachments(SOC, c.id);
    expect(list.length).toBe(1);
  });

  it("rejects cross-tenant attachment access", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Secret", description: "x" }, "u-r");
    await ComplaintService.addAttachment(SOC, c.id, { fileUrl: "https://cdn/y.jpg" });
    await expect(ComplaintService.listAttachments(SOC_B, c.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
    await expect(
      ComplaintService.addAttachment(SOC_B, c.id, { fileUrl: "https://cdn/z.jpg" })
    ).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
