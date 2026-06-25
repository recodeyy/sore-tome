import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ComplaintService } from "../src/services/complaints/ComplaintService";
import { OutboxService } from "../src/services/outbox/OutboxService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-outbox-${Date.now()}`;

afterAll(async () => {
  await db.query(`DELETE FROM outbox_events WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM complaints WHERE society_id = $1`, [SOC]);
  await dbManager.close();
});

describe("OutboxService (integration)", () => {
  it("creating a complaint enqueues an unpublished complaint.created event", async () => {
    const c = await ComplaintService.createComplaint(
      SOC,
      { title: "Outbox check", description: "should emit event" },
      "u-resident"
    );

    const { rows } = await db.query(
      `SELECT * FROM outbox_events WHERE society_id = $1 AND published = false`,
      [SOC]
    );
    expect(rows.length).toBe(1);
    expect(rows[0].type).toBe("complaint.created");
    expect(rows[0].topic).toBe(`society:${SOC}`);
    expect(rows[0].payload.id).toBe(c.id);
  });

  it("fetchUnpublished returns then marks events published", async () => {
    const first = (await OutboxService.fetchUnpublished()).filter(
      (e: any) => e.society_id === SOC
    );
    expect(first.length).toBeGreaterThanOrEqual(1);
    expect(first.every((e: any) => e.published === true && e.published_at)).toBe(true);

    const remaining = await db.query(
      `SELECT count(*)::int n FROM outbox_events WHERE society_id = $1 AND published = false`,
      [SOC]
    );
    expect(remaining.rows[0].n).toBe(0);
  });
});
