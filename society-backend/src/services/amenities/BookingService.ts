import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

function aerr(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

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

  // ---- Enhancements (Phase 5, 80–85) -----------------------------------

  /** Set pricing / deposit / approval / cap / operating hours on an amenity. */
  async setPricing(
    societyId: string,
    amenityId: string,
    input: {
      priceMinor?: number; depositMinor?: number; requiresApproval?: boolean;
      maxPerMember?: number; openMinutes?: number; closeMinutes?: number;
    }
  ) {
    const { rows } = await db.query(
      `UPDATE amenities SET
         price_minor = COALESCE($3, price_minor),
         deposit_minor = COALESCE($4, deposit_minor),
         requires_approval = COALESCE($5, requires_approval),
         max_per_member = COALESCE($6, max_per_member),
         open_minutes = COALESCE($7, open_minutes),
         close_minutes = COALESCE($8, close_minutes)
       WHERE id = $1 AND society_id = $2 RETURNING *`,
      [amenityId, societyId, input.priceMinor ?? null, input.depositMinor ?? null,
       input.requiresApproval ?? null, input.maxPerMember ?? null,
       input.openMinutes ?? null, input.closeMinutes ?? null]
    );
    if (!rows[0]) throw aerr("Amenity not found", "NOT_FOUND");
    return rows[0];
  },

  /** Register a blackout window during which the amenity cannot be booked. */
  async addBlackout(
    societyId: string,
    amenityId: string,
    input: { fromAt: string; toAt: string; reason?: string }
  ) {
    const owns = await db.query(`SELECT id FROM amenities WHERE id = $1 AND society_id = $2`, [amenityId, societyId]);
    if (!owns.rows[0]) throw aerr("Amenity not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO amenity_blackouts (society_id, amenity_id, from_at, to_at, reason)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [societyId, amenityId, input.fromAt, input.toAt, input.reason || null]
    );
    return rows[0];
  },

  /**
   * Enhanced booking. Checks blackout overlap, operating hours and per-member
   * cap, then inserts. requires_approval -> status 'pending', else 'confirmed'.
   * Overlap on confirmed bookings is rejected by the DB EXCLUDE constraint.
   */
  async requestBooking(
    societyId: string,
    input: { amenityId: string; memberId?: string; startAt: string; endAt: string }
  ) {
    return withTx(async (client) => {
      const am = await client.query(
        `SELECT * FROM amenities WHERE id = $1 AND society_id = $2`,
        [input.amenityId, societyId]
      );
      const amenity = am.rows[0];
      if (!amenity) throw aerr("Amenity not found", "NOT_FOUND");

      const start = new Date(input.startAt);
      const end = new Date(input.endAt);
      if (!(end > start)) throw aerr("End time must be after start time", "INVALID_RANGE");

      // Blackout overlap.
      const bl = await client.query(
        `SELECT 1 FROM amenity_blackouts
          WHERE amenity_id = $1 AND society_id = $2 AND tstzrange(from_at, to_at) && tstzrange($3, $4)
          LIMIT 1`,
        [input.amenityId, societyId, input.startAt, input.endAt]
      );
      if (bl.rows[0]) throw aerr("Amenity is blacked out for this period", "BLACKOUT");

      // Operating hours (minutes since midnight, UTC).
      const open = amenity.open_minutes ?? 0;
      const close = amenity.close_minutes ?? 1440;
      const startMin = start.getUTCHours() * 60 + start.getUTCMinutes();
      let endMin = end.getUTCHours() * 60 + end.getUTCMinutes();
      if (endMin === 0) endMin = 1440;
      if (startMin < open || endMin > close) {
        throw aerr("Requested time is outside operating hours", "OUTSIDE_HOURS");
      }

      // Per-member cap (active bookings).
      if (amenity.max_per_member != null && input.memberId) {
        const cnt = await client.query(
          `SELECT count(*)::int n FROM amenity_bookings
            WHERE amenity_id = $1 AND society_id = $2 AND member_id = $3
              AND status IN ('confirmed','pending')`,
          [input.amenityId, societyId, input.memberId]
        );
        if (cnt.rows[0].n >= Number(amenity.max_per_member)) {
          throw aerr("Per-member booking limit reached", "LIMIT_REACHED");
        }
      }

      const status = amenity.requires_approval ? "pending" : "confirmed";
      let booking;
      try {
        const ins = await client.query(
          `INSERT INTO amenity_bookings (society_id, amenity_id, member_id, start_at, end_at, status)
           VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
          [societyId, input.amenityId, input.memberId || null, input.startAt, input.endAt, status]
        );
        booking = ins.rows[0];
      } catch (err: any) {
        if (err.code === "23P01") throw aerr("That slot is already booked", "SLOT_TAKEN");
        if (err.code === "23514") throw aerr("End time must be after start time", "INVALID_RANGE");
        throw err;
      }

      const price = Number(amenity.price_minor || 0);
      const deposit = Number(amenity.deposit_minor || 0);
      if (price > 0 || deposit > 0) {
        await client.query(
          `INSERT INTO booking_payments (society_id, booking_id, amount_minor, deposit_minor, status)
           VALUES ($1,$2,$3,$4,'pending')`,
          [societyId, booking.id, price, deposit]
        );
      }
      logger.info({ societyId, bookingId: booking.id, status }, "Booking requested");
      return booking;
    });
  },

  /** Approve a pending booking -> confirmed (overlap re-checked by constraint). */
  async approveBooking(societyId: string, bookingId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM amenity_bookings WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [bookingId, societyId]
      );
      const bk = rows[0];
      if (!bk) throw aerr("Booking not found", "NOT_FOUND");
      if (bk.status !== "pending") throw aerr(`Booking is ${bk.status}`, "INVALID_STATE");
      try {
        const upd = await client.query(
          `UPDATE amenity_bookings SET status = 'confirmed' WHERE id = $1 RETURNING *`,
          [bookingId]
        );
        return upd.rows[0];
      } catch (err: any) {
        if (err.code === "23P01") throw aerr("That slot is already booked", "SLOT_TAKEN");
        throw err;
      }
    });
  },

  /** Reject a pending booking. */
  async rejectBooking(societyId: string, bookingId: string) {
    const { rows } = await db.query(
      `UPDATE amenity_bookings SET status = 'rejected'
         WHERE id = $1 AND society_id = $2 AND status = 'pending' RETURNING *`,
      [bookingId, societyId]
    );
    if (!rows[0]) throw aerr("Booking not found or not pending", "INVALID_STATE");
    return rows[0];
  },

  /** Cancel a booking; optionally refund the associated payment(s). */
  async cancelBooking(societyId: string, bookingId: string, withRefund = false) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM amenity_bookings WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [bookingId, societyId]
      );
      const bk = rows[0];
      if (!bk) throw aerr("Booking not found", "NOT_FOUND");
      if (!["confirmed", "pending"].includes(bk.status)) throw aerr(`Booking is ${bk.status}`, "INVALID_STATE");
      const upd = await client.query(
        `UPDATE amenity_bookings SET status = 'cancelled' WHERE id = $1 RETURNING *`,
        [bookingId]
      );
      if (withRefund) {
        await client.query(
          `UPDATE booking_payments SET status = 'refunded' WHERE booking_id = $1 AND society_id = $2`,
          [bookingId, societyId]
        );
      }
      logger.info({ societyId, bookingId, withRefund }, "Booking cancelled");
      return upd.rows[0];
    });
  },

  /** Mark a confirmed booking as a no-show. */
  async markNoShow(societyId: string, bookingId: string) {
    const { rows } = await db.query(
      `UPDATE amenity_bookings SET status = 'no_show'
         WHERE id = $1 AND society_id = $2 AND status = 'confirmed' RETURNING *`,
      [bookingId, societyId]
    );
    if (!rows[0]) throw aerr("Booking not found or not confirmed", "INVALID_STATE");
    return rows[0];
  },
};
