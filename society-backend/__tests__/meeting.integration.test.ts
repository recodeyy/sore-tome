import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { MeetingService } from "../src/services/meetings/MeetingService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-mtg-${Date.now()}`;
const SOC_B = `test-mtg-b-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    await db.query(`DELETE FROM meetings WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

describe("MeetingService (integration)", () => {
  it("creates a meeting with agenda items", async () => {
    const m = await MeetingService.createMeeting(
      SOC,
      { title: "AGM 2026", type: "agm", quorumRequired: 3, agendaItems: [{ title: "Budget" }, { title: "Elections" }] },
      "u-admin"
    );
    expect(m.status).toBe("scheduled");
    expect(m.agenda.length).toBe(2);
  });

  it("computes quorum from present attendees plus proxies", async () => {
    const m = await MeetingService.createMeeting(SOC, { title: "Committee", quorumRequired: 3 }, "u-admin");
    await MeetingService.recordAttendance(SOC, m.id, "u1", true);
    await MeetingService.recordAttendance(SOC, m.id, "u2", true);
    await MeetingService.recordAttendance(SOC, m.id, "u3", false); // absent
    // u3 grants a proxy -> counts toward present headcount
    await MeetingService.grantProxy(SOC, m.id, "u3", "u1");

    const q = await MeetingService.quorumStatus(SOC, m.id);
    expect(q.required).toBe(3);
    expect(q.present).toBe(3); // 2 present + 1 proxy
    expect(q.met).toBe(true);
  });

  it("records a resolution outcome", async () => {
    const m = await MeetingService.createMeeting(SOC, { title: "Vote meeting" }, "u-admin");
    const r = await MeetingService.addResolution(SOC, m.id, { title: "Approve audit", text: "..." });
    const updated = await MeetingService.recordResolutionOutcome(SOC, r.id, "passed", 8, 2);
    expect(updated.outcome).toBe("passed");
    expect(updated.votes_for).toBe(8);
  });

  it("tracks an action item from open to done", async () => {
    const m = await MeetingService.createMeeting(SOC, { title: "Actions" }, "u-admin");
    const a = await MeetingService.addActionItem(SOC, m.id, { description: "Fix gate", ownerId: "u2" });
    expect(a.status).toBe("open");
    const done = await MeetingService.updateActionItem(SOC, a.id, "done");
    expect(done.status).toBe("done");
  });

  it("enforces the status lifecycle scheduled -> in_progress -> completed", async () => {
    const m = await MeetingService.createMeeting(SOC, { title: "Lifecycle" }, "u-admin");
    const started = await MeetingService.startMeeting(SOC, m.id);
    expect(started.status).toBe("in_progress");
    const completed = await MeetingService.completeMeeting(SOC, m.id);
    expect(completed.status).toBe("completed");
    // cannot cancel a completed meeting
    await expect(MeetingService.cancelMeeting(SOC, m.id)).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("does not leak meetings across tenants", async () => {
    const m = await MeetingService.createMeeting(SOC, { title: "A-only" }, "u-a");
    expect(await MeetingService.getMeeting(SOC_B, m.id)).toBeNull();
    await expect(MeetingService.requireMeeting(SOC_B, m.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
