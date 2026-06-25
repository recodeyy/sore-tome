import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { NoticeService } from "../src/services/notices/NoticeService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-ntc-${Date.now()}`;
const SOC_B = `test-ntc-b-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    await db.query(`DELETE FROM notices WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

describe("NoticeService (integration)", () => {
  it("create draft -> publish creates a version snapshot and goes published", async () => {
    const n = await NoticeService.createNotice(
      SOC,
      { title: "Water cut", body: "Supply off 9-11am" },
      { id: "u-admin", name: "Admin" }
    );
    expect(n.status).toBe("draft");
    expect(n.version).toBe(0);

    const published = await NoticeService.publish(SOC, n.id, "u-admin");
    expect(published.status).toBe("published");
    expect(published.published_at).toBeTruthy();
    expect(published.version).toBe(1);

    const versions = await db.query(`SELECT * FROM notice_versions WHERE notice_id = $1`, [n.id]);
    expect(versions.rows.length).toBe(1);
    expect(versions.rows[0].version).toBe(1);
    expect(versions.rows[0].title).toBe("Water cut");
  });

  it("update bumps version and snapshots, and archived notices cannot be edited", async () => {
    const n = await NoticeService.createNotice(SOC, { title: "v1", body: "b1" }, { id: "u-admin" });
    const upd = await NoticeService.updateNotice(SOC, n.id, { title: "v2", body: "b2" }, "u-admin");
    expect(upd.version).toBe(1);
    expect(upd.title).toBe("v2");

    await NoticeService.archive(SOC, n.id);
    await expect(NoticeService.updateNotice(SOC, n.id, { title: "v3" }, "u-admin")).rejects.toMatchObject({
      code: "INVALID_STATE",
    });
  });

  it("audience targeting persists and is replaced atomically", async () => {
    const n = await NoticeService.createNotice(SOC, { title: "AGM", body: "Meeting" }, { id: "u-admin" });
    await NoticeService.setAudiences(SOC, n.id, [
      { type: "wing", value: "A" },
      { type: "role", value: "owner" },
    ]);
    let detail = await NoticeService.getNotice(SOC, n.id);
    expect(detail!.audiences.length).toBe(2);

    // Replacing the set leaves exactly the new rows.
    await NoticeService.setAudiences(SOC, n.id, [{ type: "all" }]);
    detail = await NoticeService.getNotice(SOC, n.id);
    expect(detail!.audiences.length).toBe(1);
    expect(detail!.audiences[0].audience_type).toBe("all");
  });

  it("markRead then unread count drops", async () => {
    const n = await NoticeService.createNotice(SOC, { title: "Read me", body: "x" }, { id: "u-admin" });
    await NoticeService.publish(SOC, n.id, "u-admin");

    const before = await NoticeService.unreadCountForUser(SOC, "u-reader");
    expect(before).toBeGreaterThanOrEqual(1);

    await NoticeService.markRead(SOC, n.id, "u-reader");
    // Idempotent — a second read does not error or create a duplicate.
    await NoticeService.markRead(SOC, n.id, "u-reader");

    const after = await NoticeService.unreadCountForUser(SOC, "u-reader");
    expect(after).toBe(before - 1);
  });

  it("acknowledge requires ack_required", async () => {
    const plain = await NoticeService.createNotice(SOC, { title: "No ack", body: "x" }, { id: "u-admin" });
    await NoticeService.publish(SOC, plain.id, "u-admin");
    await expect(NoticeService.acknowledge(SOC, plain.id, "u-reader")).rejects.toMatchObject({
      code: "INVALID_STATE",
    });

    const mustAck = await NoticeService.createNotice(
      SOC,
      { title: "Ack", body: "x", ackRequired: true },
      { id: "u-admin" }
    );
    await NoticeService.publish(SOC, mustAck.id, "u-admin");
    const ack = await NoticeService.acknowledge(SOC, mustAck.id, "u-reader");
    expect(ack.acknowledged).toBe(true);
    expect(ack.acknowledged_at).toBeTruthy();

    const detail = await NoticeService.getNotice(SOC, mustAck.id);
    expect(detail!.readStats.ack_count).toBe(1);
  });

  it("does not leak notices across tenants", async () => {
    const a = await NoticeService.createNotice(SOC, { title: "A-only", body: "x" }, { id: "u-a" });
    const fromB = await NoticeService.getNotice(SOC_B, a.id);
    expect(fromB).toBeNull();

    const listB = await NoticeService.listNotices(SOC_B, {});
    expect(listB.find((x: any) => x.id === a.id)).toBeUndefined();
  });
});
