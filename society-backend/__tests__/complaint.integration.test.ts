import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ComplaintService } from "../src/services/complaints/ComplaintService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-cmp-${Date.now()}`;
const SOC_B = `test-cmp-b-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    await db.query(`DELETE FROM complaints WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

describe("ComplaintService (integration)", () => {
  it("creates a complaint with an SLA due time and open status", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "No water", description: "Tap dry since morning" }, "u-resident");
    expect(c.status).toBe("open");
    expect(c.ref).toMatch(/^CMP-\d{4}$/);
    expect(c.due_at).toBeTruthy();
  });

  it("assign -> resolve flow records first response and resolution", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Lift stuck", description: "Lift B not working" }, "u-resident");
    const assigned = await ComplaintService.assign(SOC, c.id, "staff-1", "staff", "u-admin", "nearest technician");
    expect(assigned.status).toBe("in_progress");
    expect(assigned.assigned_to).toBe("staff-1");
    expect(assigned.first_response_at).toBeTruthy();

    const resolved = await ComplaintService.changeStatus(SOC, c.id, "resolved", "u-admin", "Reset controller");
    expect(resolved.status).toBe("resolved");
    expect(resolved.resolved_at).toBeTruthy();
  });

  it("rejects an illegal status transition", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Noise", description: "Loud party" }, "u-resident");
    await ComplaintService.changeStatus(SOC, c.id, "resolved", "u-admin");
    await ComplaintService.changeStatus(SOC, c.id, "closed", "u-admin");
    // closed -> open is not allowed by the state machine
    await expect(ComplaintService.changeStatus(SOC, c.id, "open", "u-admin")).rejects.toMatchObject({ code: "INVALID_TRANSITION" });
  });

  it("separates internal notes from resident-visible comments", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Leak", description: "Ceiling leak" }, "u-resident");
    await ComplaintService.addComment(SOC, c.id, { body: "internal: vendor called", visibility: "internal", authorId: "u-admin" });
    await ComplaintService.addComment(SOC, c.id, { body: "We are on it", visibility: "resident", authorId: "u-admin" });

    const residentView = await ComplaintService.getComplaint(SOC, c.id, false);
    expect(residentView!.comments.every((cm: any) => cm.visibility === "resident")).toBe(true);

    const adminView = await ComplaintService.getComplaint(SOC, c.id, true);
    expect(adminView!.comments.length).toBe(2);
  });

  it("accepts CSAT only once and only after resolution", async () => {
    const c = await ComplaintService.createComplaint(SOC, { title: "Pest", description: "Ants" }, "u-resident");
    await expect(ComplaintService.submitFeedback(SOC, c.id, 5)).rejects.toMatchObject({ code: "INVALID_STATE" });
    await ComplaintService.changeStatus(SOC, c.id, "resolved", "u-admin");
    const fb = await ComplaintService.submitFeedback(SOC, c.id, 4, "ok", "u-resident");
    expect(fb.rating).toBe(4);
    await expect(ComplaintService.submitFeedback(SOC, c.id, 1)).rejects.toMatchObject({ code: "ALREADY_EXISTS" });
  });

  it("does not leak complaints across tenants", async () => {
    const a = await ComplaintService.createComplaint(SOC, { title: "A-only", description: "x" }, "u-a");
    const fromB = await ComplaintService.getComplaint(SOC_B, a.id, true);
    expect(fromB).toBeNull();
    const listB = await ComplaintService.listComplaints(SOC_B, {});
    expect(listB.find((c: any) => c.id === a.id)).toBeUndefined();
  });
});
