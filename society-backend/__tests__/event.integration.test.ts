import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { EventService } from "../src/services/events/EventService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-evt-${Date.now()}`;
const SOC_B = `test-evt-b-${Date.now()}`;

const soon = (mins: number) => new Date(Date.now() + mins * 60_000).toISOString();

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    // event_rsvps cascade-delete with their events
    await db.query(`DELETE FROM events WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

describe("EventService (integration)", () => {
  it("creates a draft event and publishes it", async () => {
    const e = await EventService.createEvent(
      SOC,
      { title: "Holi Bash", description: "Colors", startsAt: soon(60), capacity: 2 },
      "u-admin"
    );
    expect(e.status).toBe("draft");
    const published = await EventService.publish(SOC, e.id);
    expect(published.status).toBe("published");
    // publishing an already-published event is rejected
    await expect(EventService.publish(SOC, e.id)).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("rejects RSVP to an unpublished event", async () => {
    const e = await EventService.createEvent(SOC, { title: "Draft only", startsAt: soon(60), capacity: 5 }, "u-admin");
    await expect(EventService.rsvp(SOC, e.id, "u-1", 0)).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("admits RSVPs within capacity as 'going' and overflow as 'waitlist'", async () => {
    const e = await EventService.createEvent(SOC, { title: "Capacity test", startsAt: soon(60), capacity: 2 }, "u-admin");
    await EventService.publish(SOC, e.id);

    const r1 = await EventService.rsvp(SOC, e.id, "u-a", 0); // 1 seat
    const r2 = await EventService.rsvp(SOC, e.id, "u-b", 0); // 2 seats total -> full
    expect(r1.status).toBe("going");
    expect(r2.status).toBe("going");

    const r3 = await EventService.rsvp(SOC, e.id, "u-c", 0); // beyond capacity
    expect(r3.status).toBe("waitlist");

    const detail = await EventService.getEvent(SOC, e.id);
    expect(detail!.counts.going).toBe(2);
    expect(detail!.counts.waitlist).toBe(1);
  });

  it("counts guests against capacity (1 + guests)", async () => {
    const e = await EventService.createEvent(SOC, { title: "Guests", startsAt: soon(60), capacity: 3 }, "u-admin");
    await EventService.publish(SOC, e.id);

    const r1 = await EventService.rsvp(SOC, e.id, "u-a", 2); // occupies 3 seats -> full
    expect(r1.status).toBe("going");
    const r2 = await EventService.rsvp(SOC, e.id, "u-b", 0); // no room
    expect(r2.status).toBe("waitlist");
  });

  it("promotes the oldest waitlisted RSVP when a 'going' RSVP is cancelled", async () => {
    const e = await EventService.createEvent(SOC, { title: "Promotion", startsAt: soon(60), capacity: 1 }, "u-admin");
    await EventService.publish(SOC, e.id);

    const r1 = await EventService.rsvp(SOC, e.id, "u-first", 0); // going
    expect(r1.status).toBe("going");
    const r2 = await EventService.rsvp(SOC, e.id, "u-second", 0); // waitlist
    const r3 = await EventService.rsvp(SOC, e.id, "u-third", 0); // waitlist (newer)
    expect(r2.status).toBe("waitlist");
    expect(r3.status).toBe("waitlist");

    const result = await EventService.cancelRsvp(SOC, e.id, "u-first");
    expect(result.rsvp.status).toBe("cancelled");
    expect(result.promoted).toBeTruthy();
    expect(result.promoted.user_id).toBe("u-second"); // oldest waitlisted

    const detail = await EventService.getEvent(SOC, e.id);
    expect(detail!.counts.going).toBe(1);
    expect(detail!.counts.waitlist).toBe(1); // u-third remains
  });

  it("marks attendance for a member's RSVP", async () => {
    const e = await EventService.createEvent(SOC, { title: "Attendance", startsAt: soon(60), capacity: 5 }, "u-admin");
    await EventService.publish(SOC, e.id);
    await EventService.rsvp(SOC, e.id, "u-att", 0);
    const updated = await EventService.markAttended(SOC, e.id, "u-att", true);
    expect(updated.attended).toBe(true);
  });

  it("does not leak events across tenants", async () => {
    const a = await EventService.createEvent(SOC, { title: "A-only", startsAt: soon(60), capacity: null }, "u-a");
    const fromB = await EventService.getEvent(SOC_B, a.id);
    expect(fromB).toBeNull();
    const listB = await EventService.listEvents(SOC_B, {});
    expect(listB.find((e: any) => e.id === a.id)).toBeUndefined();
  });
});
