import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";

/**
 * Amenity bookings. Overlap is rejected by the DB EXCLUDE constraint
 * (amenity_bookings_no_overlap), so concurrent requests can never double-book —
 * the loser gets a 23P01 exclusion_violation which we surface as a conflict.
 */
export const BookingService = {
  async createAmenity(societyId: string, input: { name: string; capacity?: number }) {
    const { rows } = await db.query(
      `INSERT INTO amenities (society_id, name, capacity) VALUES ($1, $2, $3) RETURNING *`,
      [societyId, input.name, input.capacity ?? 1]
    );
    return rows[0];
  },

  async book(societyId: string, input: { amenityId: string; memberId?: string; startAt: string; endAt: string }) {
    try {
      const { rows } = await db.query(
        `INSERT INTO amenity_bookings (society_id, amenity_id, member_id, start_at, end_at, status)
         VALUES ($1, $2, $3, $4, $5, 'confirmed')
         RETURNING *`,
        [societyId, input.amenityId, input.memberId || null, input.startAt, input.endAt]
      );
      logger.info({ societyId, bookingId: rows[0].id, amenityId: input.amenityId }, "Amenity booked");
      return rows[0];
    } catch (err: any) {
      if (err.code === "23P01") {
        throw Object.assign(new Error("That slot is already booked"), { code: "SLOT_TAKEN" });
      }
      if (err.code === "23514") {
        throw Object.assign(new Error("End time must be after start time"), { code: "INVALID_RANGE" });
      }
      throw err;
    }
  },

  async cancel(societyId: string, bookingId: string) {
    const { rows } = await db.query(
      `UPDATE amenity_bookings SET status = 'cancelled'
       WHERE id = $1 AND society_id = $2 AND status = 'confirmed'
       RETURNING *`,
      [bookingId, societyId]
    );
    if (rows.length === 0) throw Object.assign(new Error("Booking not found or not active"), { code: "NOT_FOUND" });
    return rows[0];
  },

  async list(societyId: string, amenityId: string) {
    const { rows } = await db.query(
      `SELECT * FROM amenity_bookings
       WHERE society_id = $1 AND amenity_id = $2 AND status = 'confirmed'
       ORDER BY start_at`,
      [societyId, amenityId]
    );
    return rows;
  },
};
