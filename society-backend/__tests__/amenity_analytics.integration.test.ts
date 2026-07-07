import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { BookingService } from "../src/services/amenities/BookingService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-amana-${Date.now()}`;
const OTHER = `test-amana-other-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, OTHER]) {
    await db.query(`DELETE FROM amenity_reviews WHERE society_id = $1`, [s]);
    await db.query(`DELETE FROM booking_payments WHERE society_id = $1`, [s]);
    await db.query(`DELETE FROM amenity_bookings WHERE society_id = $1`, [s]);
    await db.query(`DELETE FROM amenity_blackouts WHERE society_id = $1`, [s]);
    await db.query(`DELETE FROM amenities WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

describe("Amenities cap 85 + reschedule (integration)", () => {
  it("reschedules a confirmed booking to a new slot", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Court" });
    await BookingService.setPricing(SOC, am.id, { openMinutes: 0, closeMinutes: 1440 });
    const bk = await BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m1", startAt: "2026-10-01T10:00:00Z", endAt: "2026-10-01T11:00:00Z" });
    const moved = await BookingService.rescheduleBooking(SOC, bk.id, { startAt: "2026-10-01T14:00:00Z", endAt: "2026-10-01T15:00:00Z" });
    expect(new Date(moved.start_at).toISOString()).toBe("2026-10-01T14:00:00.000Z");
  });

  it("rejects a reschedule into a blackout window", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Court2" });
    await BookingService.setPricing(SOC, am.id, { openMinutes: 0, closeMinutes: 1440 });
    await BookingService.addBlackout(SOC, am.id, { fromAt: "2026-10-05T08:00:00Z", toAt: "2026-10-05T18:00:00Z" });
    const bk = await BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m1", startAt: "2026-10-04T10:00:00Z", endAt: "2026-10-04T11:00:00Z" });
    await expect(
      BookingService.rescheduleBooking(SOC, bk.id, { startAt: "2026-10-05T10:00:00Z", endAt: "2026-10-05T11:00:00Z" })
    ).rejects.toMatchObject({ code: "BLACKOUT" });
  });

  it("records reviews and computes average rating", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Spa" });
    await BookingService.addReview(SOC, am.id, { rating: 5, comment: "great", memberId: "m1" });
    await BookingService.addReview(SOC, am.id, { rating: 3, memberId: "m2" });
    const r = await BookingService.listReviews(SOC, am.id);
    expect(r.count).toBe(2);
    expect(r.averageRating).toBe(4);
  });

  it("computes utilization + revenue analytics", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Banquet" });
    await BookingService.setPricing(SOC, am.id, { openMinutes: 0, closeMinutes: 1440, priceMinor: 50000 });
    await BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m1", startAt: "2026-11-01T10:00:00Z", endAt: "2026-11-01T12:00:00Z" });
    const a = await BookingService.analytics(SOC, am.id, "2026-11-01T00:00:00Z", "2026-11-02T00:00:00Z");
    expect(a.bookings.confirmed).toBe(1);
    expect(a.revenueMinor).toBe(50000);
    expect(a.bookedSeconds).toBe(7200);
    expect(a.utilization).toBeGreaterThan(0);
    expect(a.utilization).toBeLessThanOrEqual(1);
  });

  it("does not leak analytics or reviews across tenants", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Private" });
    await expect(BookingService.analytics(OTHER, am.id, "2026-11-01T00:00:00Z", "2026-11-02T00:00:00Z")).rejects.toMatchObject({ code: "NOT_FOUND" });
    await expect(BookingService.addReview(OTHER, am.id, { rating: 5 })).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
