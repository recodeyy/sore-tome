import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { BookingService } from "../src/services/amenities/BookingService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-bk-${Date.now()}`;

afterAll(async () => {
  await db.query(`DELETE FROM amenity_bookings WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM amenities WHERE society_id = $1`, [SOC]);
  await dbManager.close();
});

describe("BookingService (integration)", () => {
  it("rejects an overlapping booking", async () => {
    const amenity = await BookingService.createAmenity(SOC, { name: "Clubhouse" });
    await BookingService.book(SOC, { amenityId: amenity.id, startAt: "2026-07-01T10:00:00Z", endAt: "2026-07-01T12:00:00Z" });

    await expect(
      BookingService.book(SOC, { amenityId: amenity.id, startAt: "2026-07-01T11:00:00Z", endAt: "2026-07-01T13:00:00Z" })
    ).rejects.toMatchObject({ code: "SLOT_TAKEN" });

    // A non-overlapping slot is fine.
    const ok = await BookingService.book(SOC, { amenityId: amenity.id, startAt: "2026-07-01T12:00:00Z", endAt: "2026-07-01T13:00:00Z" });
    expect(ok.status).toBe("confirmed");
  });

  it("lets exactly one of two concurrent bookings win the same slot", async () => {
    const amenity = await BookingService.createAmenity(SOC, { name: "Tennis Court" });
    const slot = { amenityId: amenity.id, startAt: "2026-08-01T08:00:00Z", endAt: "2026-08-01T09:00:00Z" };

    // Fire both at once — the DB EXCLUDE constraint must let only one through.
    const results = await Promise.allSettled([
      BookingService.book(SOC, { ...slot, memberId: "A" }),
      BookingService.book(SOC, { ...slot, memberId: "B" }),
    ]);

    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");
    expect(fulfilled.length).toBe(1);
    expect(rejected.length).toBe(1);

    const { rows } = await db.query(
      `SELECT count(*)::int n FROM amenity_bookings WHERE amenity_id = $1 AND status = 'confirmed'`,
      [amenity.id]
    );
    expect(rows[0].n).toBe(1);
  });
});
