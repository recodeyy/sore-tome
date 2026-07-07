import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { BookingService } from "../src/services/amenities/BookingService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-amx-${Date.now()}`;

afterAll(async () => {
  await db.query(`DELETE FROM booking_payments WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM amenity_bookings WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM amenity_blackouts WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM amenities WHERE society_id = $1`, [SOC]);
  await dbManager.close();
});

describe("BookingService enhancements (integration)", () => {
  it("blocks a booking that overlaps a blackout", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Pool" });
    await BookingService.setPricing(SOC, am.id, { openMinutes: 0, closeMinutes: 1440 });
    await BookingService.addBlackout(SOC, am.id, {
      fromAt: "2026-09-01T08:00:00Z", toAt: "2026-09-01T18:00:00Z", reason: "maintenance",
    });
    await expect(
      BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m1", startAt: "2026-09-01T10:00:00Z", endAt: "2026-09-01T11:00:00Z" })
    ).rejects.toMatchObject({ code: "BLACKOUT" });
  });

  it("blocks a booking outside operating hours", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Gym" });
    await BookingService.setPricing(SOC, am.id, { openMinutes: 360, closeMinutes: 1320 }); // 06:00–22:00
    await expect(
      BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m1", startAt: "2026-09-02T23:00:00Z", endAt: "2026-09-02T23:30:00Z" })
    ).rejects.toMatchObject({ code: "OUTSIDE_HOURS" });
  });

  it("creates a pending booking when approval is required, then approves to confirmed", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Hall" });
    await BookingService.setPricing(SOC, am.id, { requiresApproval: true, openMinutes: 0, closeMinutes: 1440 });
    const bk = await BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m2", startAt: "2026-09-03T10:00:00Z", endAt: "2026-09-03T12:00:00Z" });
    expect(bk.status).toBe("pending");
    const approved = await BookingService.approveBooking(SOC, bk.id);
    expect(approved.status).toBe("confirmed");
  });

  it("refunds the booking_payment when cancelling with refund", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "Lawn" });
    await BookingService.setPricing(SOC, am.id, { priceMinor: 50000, depositMinor: 10000, openMinutes: 0, closeMinutes: 1440 });
    const bk = await BookingService.requestBooking(SOC, { amenityId: am.id, memberId: "m3", startAt: "2026-09-04T10:00:00Z", endAt: "2026-09-04T12:00:00Z" });
    expect(bk.status).toBe("confirmed");
    await BookingService.cancelBooking(SOC, bk.id, true);
    const { rows } = await db.query(`SELECT status FROM booking_payments WHERE booking_id = $1`, [bk.id]);
    expect(rows[0].status).toBe("refunded");
  });

  it("does not leak amenities across tenants", async () => {
    const am = await BookingService.createAmenity(SOC, { name: "X-only" });
    await expect(BookingService.setPricing("other-soc", am.id, { priceMinor: 1 })).rejects.toMatchObject({ code: "NOT_FOUND" });
  });
});
