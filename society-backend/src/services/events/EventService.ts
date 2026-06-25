import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { Recipients } from "../notifications/Recipients";

/**
 * Society events with RSVP, capacity & waitlist. Tenant-scoped by society_id.
 *
 * RSVP capacity is enforced atomically inside a transaction: the event row is
 * locked FOR UPDATE, current confirmed seats (sum of 1 + guests over 'going'
 * RSVPs) are counted, and if a new RSVP would exceed capacity it is placed on
 * the waitlist instead. Cancelling a confirmed RSVP promotes the oldest
 * waitlisted RSVP back to 'going' when capacity frees up — all in one tx.
 */
export const EventService = {
  async createEvent(
    societyId: string,
    input: {
      title: string;
      description?: string;
      location?: string;
      startsAt: string;
      endsAt?: string;
      capacity?: number | null;
    },
    createdBy?: string
  ) {
    const { rows } = await db.query(
      `INSERT INTO events (society_id, title, description, location, starts_at, ends_at, capacity, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        societyId,
        input.title,
        input.description || null,
        input.location || null,
        input.startsAt,
        input.endsAt || null,
        input.capacity == null ? null : input.capacity,
        createdBy || null,
      ]
    );
    logger.info({ societyId, eventId: rows[0].id }, "Event created (draft)");
    return rows[0];
  },

  /** Move a draft event to published so members can RSVP. */
  async publish(societyId: string, eventId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM events WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [eventId, societyId]
      );
      const event = rows[0];
      if (!event) throw Object.assign(new Error("Event not found"), { code: "NOT_FOUND" });
      if (event.status !== "draft") {
        throw Object.assign(new Error(`Cannot publish an event that is ${event.status}`), { code: "INVALID_STATE" });
      }
      const upd = await client.query(
        `UPDATE events SET status = 'published', version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [eventId, societyId]
      );

      // Cross-role: a published event is announced to every approved member with
      // a linked login (default society-wide audience, mirrors notice publish).
      const r = await client.query(
        `SELECT DISTINCT user_id FROM members
          WHERE society_id = $1 AND status = 'approved' AND user_id IS NOT NULL`,
        [societyId]
      );
      const recipients = r.rows.map((x: any) => x.user_id);
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: "event.published",
        payload: { id: eventId, title: upd.rows[0].title, startsAt: upd.rows[0].starts_at },
        recipients,
        notification: {
          title: "New event",
          body: upd.rows[0].title,
          type: "event",
          data: { eventId, deepLink: `sero://events/${eventId}` },
        },
      });
      logger.info({ societyId, eventId, notified }, "Event published + residents notified");
      return upd.rows[0];
    });
  },

  /** Cancel an event (only draft/published events can be cancelled). */
  async cancel(societyId: string, eventId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM events WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [eventId, societyId]
      );
      const event = rows[0];
      if (!event) throw Object.assign(new Error("Event not found"), { code: "NOT_FOUND" });
      if (event.status !== "draft" && event.status !== "published") {
        throw Object.assign(new Error(`Cannot cancel an event that is ${event.status}`), { code: "INVALID_STATE" });
      }
      const upd = await client.query(
        `UPDATE events SET status = 'cancelled', version = version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [eventId, societyId]
      );
      logger.info({ societyId, eventId }, "Event cancelled");
      return upd.rows[0];
    });
  },

  async listEvents(
    societyId: string,
    opts: { status?: string; upcoming?: boolean; limit?: number } = {}
  ) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    if (opts.upcoming) {
      where += ` AND starts_at >= now()`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM events WHERE ${where} ORDER BY starts_at ASC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /** Fetch a single event with RSVP counts (going / waitlist). Tenant-scoped. */
  async getEvent(societyId: string, eventId: string) {
    const { rows } = await db.query(
      `SELECT * FROM events WHERE id = $1 AND society_id = $2`,
      [eventId, societyId]
    );
    const event = rows[0];
    if (!event) return null;

    const counts = await db.query(
      `SELECT
         COALESCE(SUM(CASE WHEN status = 'going' THEN 1 + guests ELSE 0 END), 0)::int   AS going,
         COALESCE(SUM(CASE WHEN status = 'waitlist' THEN 1 + guests ELSE 0 END), 0)::int AS waitlist
       FROM event_rsvps WHERE event_id = $1 AND society_id = $2`,
      [eventId, societyId]
    );
    return { event, counts: counts.rows[0] };
  },

  /**
   * Atomically RSVP to an event. Locks the event row, counts confirmed seats,
   * and assigns 'going' if capacity allows (or capacity is unlimited),
   * otherwise 'waitlist'. Upserts on (event_id, user_id).
   */
  async rsvp(societyId: string, eventId: string, userId: string, guests = 0) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM events WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [eventId, societyId]
      );
      const event = rows[0];
      if (!event) throw Object.assign(new Error("Event not found"), { code: "NOT_FOUND" });
      if (event.status !== "published") {
        throw Object.assign(new Error(`Cannot RSVP to an event that is ${event.status}`), { code: "INVALID_STATE" });
      }

      // Seats this RSVP wants to occupy.
      const seats = 1 + guests;

      let nextStatus: "going" | "waitlist" = "going";
      if (event.capacity != null) {
        // Confirmed seats currently taken, excluding this user's own RSVP so
        // an update does not double-count their existing seats.
        const cnt = await client.query(
          `SELECT COALESCE(SUM(1 + guests), 0)::int AS taken
           FROM event_rsvps
           WHERE event_id = $1 AND society_id = $2 AND status = 'going' AND user_id <> $3`,
          [eventId, societyId, userId]
        );
        const taken = cnt.rows[0].taken;
        if (taken + seats > event.capacity) {
          nextStatus = "waitlist";
        }
      }

      const { rows: upRows } = await client.query(
        `INSERT INTO event_rsvps (society_id, event_id, user_id, status, guests)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (event_id, user_id)
         DO UPDATE SET status = EXCLUDED.status, guests = EXCLUDED.guests, updated_at = now()
         RETURNING *`,
        [societyId, eventId, userId, nextStatus, guests]
      );
      logger.info({ societyId, eventId, userId, status: nextStatus, guests }, "RSVP recorded");
      return upRows[0];
    });
  },

  /**
   * Cancel a user's RSVP. If they were 'going', promote the oldest waitlisted
   * RSVP to 'going' when the freed capacity can accommodate it — same tx.
   */
  async cancelRsvp(societyId: string, eventId: string, userId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM events WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [eventId, societyId]
      );
      const event = rows[0];
      if (!event) throw Object.assign(new Error("Event not found"), { code: "NOT_FOUND" });

      const { rows: rsvpRows } = await client.query(
        `SELECT * FROM event_rsvps WHERE event_id = $1 AND society_id = $2 AND user_id = $3`,
        [eventId, societyId, userId]
      );
      const rsvp = rsvpRows[0];
      if (!rsvp) throw Object.assign(new Error("RSVP not found"), { code: "NOT_FOUND" });

      const wasGoing = rsvp.status === "going";

      const { rows: cancelled } = await client.query(
        `UPDATE event_rsvps SET status = 'cancelled', updated_at = now()
         WHERE event_id = $1 AND society_id = $2 AND user_id = $3 RETURNING *`,
        [eventId, societyId, userId]
      );

      // Promote the oldest waitlisted RSVP if a 'going' seat was freed.
      let promoted: any = null;
      if (wasGoing) {
        const { rows: wl } = await client.query(
          `SELECT * FROM event_rsvps
           WHERE event_id = $1 AND society_id = $2 AND status = 'waitlist'
           ORDER BY created_at ASC
           FOR UPDATE`,
          [eventId, societyId]
        );
        for (const candidate of wl) {
          let canPromote = true;
          if (event.capacity != null) {
            const cnt = await client.query(
              `SELECT COALESCE(SUM(1 + guests), 0)::int AS taken
               FROM event_rsvps
               WHERE event_id = $1 AND society_id = $2 AND status = 'going'`,
              [eventId, societyId]
            );
            canPromote = cnt.rows[0].taken + (1 + candidate.guests) <= event.capacity;
          }
          if (canPromote) {
            const { rows: pr } = await client.query(
              `UPDATE event_rsvps SET status = 'going', updated_at = now()
               WHERE id = $1 AND society_id = $2 RETURNING *`,
              [candidate.id, societyId]
            );
            promoted = pr[0];
            logger.info({ societyId, eventId, userId: candidate.user_id }, "Waitlisted RSVP promoted to going");
            break; // freeing one seat promotes at most the oldest fitting entry
          }
        }
      }

      logger.info({ societyId, eventId, userId }, "RSVP cancelled");
      return { rsvp: cancelled[0], promoted };
    });
  },

  /** Mark (or unmark) attendance for a user's RSVP. Tenant-scoped. */
  async markAttended(societyId: string, eventId: string, userId: string, attended: boolean) {
    const { rows } = await db.query(
      `UPDATE event_rsvps SET attended = $4, updated_at = now()
       WHERE event_id = $1 AND society_id = $2 AND user_id = $3 RETURNING *`,
      [eventId, societyId, userId, attended]
    );
    if (!rows[0]) throw Object.assign(new Error("RSVP not found"), { code: "NOT_FOUND" });
    logger.info({ societyId, eventId, userId, attended }, "Attendance updated");
    return rows[0];
  },
};
