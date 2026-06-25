import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { NotificationService } from "../src/services/notifications/NotificationService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-notif-${Date.now()}`;
const SOC_B = `test-notif-b-${Date.now()}`;
const USER = "user-1";

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(
      `DELETE FROM notification_deliveries WHERE society_id = $1`,
      [sId]
    );
    await db.query(`DELETE FROM notifications WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM device_tokens WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("NotificationService (integration)", () => {
  it("registers a device idempotently on the token", async () => {
    const d1 = await NotificationService.registerDevice(SOC, USER, "tok-abc", "android");
    const d2 = await NotificationService.registerDevice(SOC, USER, "tok-abc", "ios");
    expect(d1.id).toBe(d2.id); // same row, upserted
    expect(d2.platform).toBe("ios");
  });

  it("queues one delivery per active device", async () => {
    await NotificationService.registerDevice(SOC, USER, "tok-abc", "android");
    const { notification, deliveries } = await NotificationService.notifyUser(SOC, USER, {
      title: "Bill published",
      body: "Your maintenance bill is ready",
      type: "finance",
    });
    expect(notification.title).toBe("Bill published");
    expect(deliveries).toBeGreaterThanOrEqual(1);
  });

  it("processes the queue and marks deliveries sent", async () => {
    const { sent, failed } = await NotificationService.processQueue();
    expect(sent).toBeGreaterThanOrEqual(1);
    expect(failed).toBe(0);
  });

  it("lists a user's notifications, tenant-scoped", async () => {
    const list = await NotificationService.listForUser(SOC, USER);
    expect(list.length).toBeGreaterThanOrEqual(1);
    const listB = await NotificationService.listForUser(SOC_B, USER);
    expect(listB.length).toBe(0);
  });
});
