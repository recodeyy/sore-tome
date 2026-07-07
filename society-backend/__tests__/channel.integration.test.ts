import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ChannelService } from "../src/services/channels/ChannelService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-chn-${Date.now()}`;
const SOC_B = `test-chn-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM channels WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("ChannelService (integration)", () => {
  it("posts and lists messages with cursor pagination", async () => {
    const ch = await ChannelService.createChannel(SOC, { name: "General" }, "u-admin");
    for (let i = 0; i < 5; i++) {
      await ChannelService.postMessage(SOC, ch.id, { body: `msg ${i}`, authorId: "u1" });
    }
    const page1 = await ChannelService.listMessages(SOC, ch.id, { limit: 3 });
    expect(page1.messages.length).toBe(3);
    expect(page1.nextCursor).toBeTruthy();
    const page2 = await ChannelService.listMessages(SOC, ch.id, { limit: 3, cursor: page1.nextCursor! });
    expect(page2.messages.length).toBe(2);
  });

  it("blocks non-admins from posting in read-only channels", async () => {
    const ch = await ChannelService.createChannel(SOC, { name: "Announcements", isReadOnly: true }, "u-admin");
    await expect(
      ChannelService.postMessage(SOC, ch.id, { body: "hi", authorId: "u-resident", isAdmin: false })
    ).rejects.toMatchObject({ code: "READ_ONLY" });
    const ok = await ChannelService.postMessage(SOC, ch.id, { body: "official", authorId: "u-admin", isAdmin: true });
    expect(ok.id).toBeTruthy();
  });

  it("tracks unread counts against read receipts", async () => {
    const ch = await ChannelService.createChannel(SOC, { name: "Unread" }, "u-admin");
    const m1 = await ChannelService.postMessage(SOC, ch.id, { body: "a", authorId: "u1" });
    await ChannelService.postMessage(SOC, ch.id, { body: "b", authorId: "u1" });
    expect(await ChannelService.unreadCount(SOC, ch.id, "u2")).toBe(2);
    await ChannelService.markRead(SOC, ch.id, "u2", m1.id);
    // After marking read "now", both prior messages are read.
    expect(await ChannelService.unreadCount(SOC, ch.id, "u2")).toBe(0);
  });

  it("reports and soft-deletes a message, masking it for residents", async () => {
    const ch = await ChannelService.createChannel(SOC, { name: "Moderated" }, "u-admin");
    const msg = await ChannelService.postMessage(SOC, ch.id, { body: "spam content", authorId: "u-bad" });
    const report = await ChannelService.reportMessage(SOC, msg.id, "u-reporter", "spam");
    await ChannelService.moderate(SOC, { reportId: report.id, action: "soft_delete", actorId: "u-admin" });

    const residentView = await ChannelService.listMessages(SOC, ch.id, {});
    const masked = residentView.messages.find((m: any) => m.id === msg.id);
    expect(masked.body).toBe("[removed by moderator]");

    const adminView = await ChannelService.listMessages(SOC, ch.id, { includeDeleted: true });
    const raw = adminView.messages.find((m: any) => m.id === msg.id);
    expect(raw.body).toBe("spam content");

    const reports = await ChannelService.listReports(SOC, { status: "actioned" });
    expect(reports.find((r: any) => r.id === report.id)).toBeTruthy();
  });

  it("does not leak channels across tenants", async () => {
    const ch = await ChannelService.createChannel(SOC, { name: "A-only" }, "u-a");
    await expect(ChannelService.requireChannel(SOC_B, ch.id)).rejects.toMatchObject({ code: "NOT_FOUND" });
    const listB = await ChannelService.listChannels(SOC_B);
    expect(listB.find((c: any) => c.id === ch.id)).toBeUndefined();
  });
});
