import { db } from "../../shared/Database";
import { ComplaintService } from "../complaints/ComplaintService";
import { BookingService } from "../amenities/BookingService";
import { PollService } from "../polls/PollService";

/**
 * ResidentService — resident self-service surface. Every call is tenant-scoped
 * (society_id) AND resolved to the caller's OWN member/unit record. The unit is
 * always derived server-side from the member row keyed on (society_id, user_id);
 * a client-supplied unit id is never trusted. A resident therefore can never see
 * or act on another unit's dues, complaints, payments, bookings or visitors.
 *
 * Business logic for complaints / bookings / polls is reused from the existing
 * domain services — this module only adds the self-scoping and aggregation.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export type ResidentContext = {
  societyId: string;
  userId: string;
  memberId: string;
  unitId: string | null;
};

export const ResidentService = {
  /** Resolves the active member record for a resident user. Throws NOT_A_MEMBER. */
  async resolveContext(societyId: string, userId: string): Promise<ResidentContext> {
    const { rows } = await db.query(
      `SELECT id, unit_id FROM members
        WHERE society_id = $1 AND user_id = $2 AND status = 'approved'
        ORDER BY created_at DESC LIMIT 1`,
      [societyId, userId]
    );
    const m = rows[0];
    if (!m) throw err("No active membership for this user", "NOT_A_MEMBER");
    return { societyId, userId, memberId: m.id, unitId: m.unit_id || null };
  },

  /** Outstanding published invoices with ageing buckets, scoped to the resident's unit. */
  async dues(ctx: ResidentContext) {
    if (!ctx.unitId) return { items: [], buckets: { "0-30": 0, "31-60": 0, "61-90": 0, "90+": 0 }, totalOutstandingMinor: 0 };
    const { rows } = await db.query(
      `SELECT i.id, i.number, i.total_minor::bigint AS total,
              COALESCE(SUM(pa.amount_minor),0)::bigint AS allocated,
              i.due_date, i.created_at
         FROM invoices i
         LEFT JOIN payment_allocations pa ON pa.invoice_id = i.id AND pa.society_id = $1
        WHERE i.society_id = $1 AND i.status = 'published' AND i.unit_id = $2
        GROUP BY i.id
       HAVING i.total_minor - COALESCE(SUM(pa.amount_minor),0) > 0
        ORDER BY i.due_date NULLS LAST`,
      [ctx.societyId, ctx.unitId]
    );
    const now = Date.now();
    const bucketFor = (d: number) => (d <= 30 ? "0-30" : d <= 60 ? "31-60" : d <= 90 ? "61-90" : "90+");
    const items = rows.map((x: any) => {
      const ref = x.due_date || x.created_at;
      const ageDays = ref ? Math.max(0, Math.floor((now - new Date(ref).getTime()) / 86400000)) : 0;
      return {
        invoiceId: x.id,
        number: x.number,
        totalMinor: Number(x.total),
        allocatedMinor: Number(x.allocated),
        outstandingMinor: Number(x.total) - Number(x.allocated),
        ageDays,
        bucket: bucketFor(ageDays),
      };
    });
    const buckets = { "0-30": 0, "31-60": 0, "61-90": 0, "90+": 0 } as Record<string, number>;
    for (const it of items) buckets[it.bucket] += it.outstandingMinor;
    return { items, buckets, totalOutstandingMinor: items.reduce((s, i) => s + i.outstandingMinor, 0) };
  },

  /** Payment history for the resident's unit (via invoice allocations). */
  async payments(ctx: ResidentContext, limit = 50) {
    if (!ctx.unitId) return [];
    const { rows } = await db.query(
      `SELECT DISTINCT p.id, p.amount_minor, p.status, p.provider, p.created_at,
              i.number AS invoice_number
         FROM payments p
         JOIN payment_allocations pa ON pa.payment_id = p.id AND pa.society_id = p.society_id
         JOIN invoices i ON i.id = pa.invoice_id AND i.society_id = p.society_id
        WHERE p.society_id = $1 AND i.unit_id = $2
        ORDER BY p.created_at DESC
        LIMIT $3`,
      [ctx.societyId, ctx.unitId, Math.min(limit, 200)]
    );
    return rows;
  },

  /** Complaints raised for the resident's unit only. */
  async complaints(ctx: ResidentContext, limit = 50) {
    const { rows } = await db.query(
      `SELECT * FROM complaints
        WHERE society_id = $1 AND unit_id = $2
        ORDER BY created_at DESC LIMIT $3`,
      [ctx.societyId, ctx.unitId, Math.min(limit, 200)]
    );
    return rows;
  },

  /** Raise a complaint — unit is forced to the resident's own unit. */
  async raiseComplaint(
    ctx: ResidentContext,
    input: { title: string; description: string; categoryId?: string; location?: string; priority?: "low" | "medium" | "high" | "critical" }
  ) {
    if (!ctx.unitId) throw err("Resident has no unit assigned", "NO_UNIT");
    return ComplaintService.createComplaint(
      ctx.societyId,
      { ...input, unitId: ctx.unitId },
      ctx.userId
    );
  },

  /** The resident's own amenity bookings. */
  async bookings(ctx: ResidentContext, limit = 50) {
    const { rows } = await db.query(
      `SELECT b.*, a.name AS amenity_name FROM amenity_bookings b
         JOIN amenities a ON a.id = b.amenity_id AND a.society_id = b.society_id
        WHERE b.society_id = $1 AND b.member_id = $2
        ORDER BY b.start_at DESC LIMIT $3`,
      [ctx.societyId, ctx.memberId, Math.min(limit, 200)]
    );
    return rows;
  },

  /** Request a booking — member id is forced to the resident's own member id. */
  async requestBooking(ctx: ResidentContext, input: { amenityId: string; startAt: string; endAt: string }) {
    return BookingService.requestBooking(ctx.societyId, { ...input, memberId: ctx.memberId });
  },

  /** Published notices targeted to the resident (all-audience, their unit, or role). */
  async notices(ctx: ResidentContext, limit = 50) {
    const { rows } = await db.query(
      `SELECT DISTINCT n.id, n.title, n.body, n.type, n.priority, n.ack_required,
              n.published_at, n.created_at,
              (r.id IS NOT NULL) AS read
         FROM notices n
         LEFT JOIN notice_audiences na ON na.notice_id = n.id AND na.society_id = n.society_id
         LEFT JOIN notice_reads r ON r.notice_id = n.id AND r.user_id = $2
        WHERE n.society_id = $1 AND n.status = 'published' AND n.deleted_at IS NULL
          AND (na.id IS NULL
               OR na.audience_type = 'all'
               OR (na.audience_type = 'unit' AND na.audience_value = $3))
        ORDER BY n.published_at DESC NULLS LAST
        LIMIT $4`,
      [ctx.societyId, ctx.userId, ctx.unitId, Math.min(limit, 200)]
    );
    return rows;
  },

  async unreadNoticeCount(ctx: ResidentContext): Promise<number> {
    const list = await this.notices(ctx, 200);
    return list.filter((n: any) => !n.read).length;
  },

  /** Cast a poll vote — reuses the atomic vote service with resident unit eligibility. */
  async vote(ctx: ResidentContext, pollId: string, optionId: string) {
    return PollService.castVote(ctx.societyId, pollId, {
      optionId,
      voterId: ctx.userId,
      unitId: ctx.unitId || undefined,
    });
  },

  /** Visitor pre-approvals for the resident's unit only. */
  async visitors(ctx: ResidentContext, limit = 50) {
    const { rows } = await db.query(
      `SELECT * FROM resident_visitors
        WHERE society_id = $1 AND member_id = $2
        ORDER BY created_at DESC LIMIT $3`,
      [ctx.societyId, ctx.memberId, Math.min(limit, 200)]
    );
    return rows;
  },

  async preApproveVisitor(
    ctx: ResidentContext,
    input: { visitorName: string; visitorPhone?: string; purpose?: string; expectedAt?: string; expiresAt?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO resident_visitors
         (society_id, unit_id, member_id, created_by, visitor_name, visitor_phone, purpose, status, expected_at, expires_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'approved',$8,$9) RETURNING *`,
      [ctx.societyId, ctx.unitId, ctx.memberId, ctx.userId, input.visitorName,
       input.visitorPhone || null, input.purpose || null, input.expectedAt || null, input.expiresAt || null]
    );
    return rows[0];
  },

  /** Aggregated dashboard summary for the resident. */
  async dashboard(ctx: ResidentContext) {
    const [dues, openComplaints, upcomingBookings, unreadNotices] = await Promise.all([
      this.dues(ctx),
      db.query(
        `SELECT count(*)::int n FROM complaints
          WHERE society_id = $1 AND unit_id = $2 AND status NOT IN ('resolved','closed')`,
        [ctx.societyId, ctx.unitId]
      ),
      db.query(
        `SELECT count(*)::int n FROM amenity_bookings
          WHERE society_id = $1 AND member_id = $2
            AND status IN ('confirmed','pending') AND start_at >= now()`,
        [ctx.societyId, ctx.memberId]
      ),
      this.unreadNoticeCount(ctx),
    ]);
    return {
      duesTotalMinor: dues.totalOutstandingMinor,
      duesBuckets: dues.buckets,
      openComplaints: openComplaints.rows[0].n,
      upcomingBookings: upcomingBookings.rows[0].n,
      unreadNotices,
    };
  },
};
