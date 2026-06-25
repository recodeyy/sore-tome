import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { Recipients } from "../notifications/Recipients";

/**
 * Members (Phase 2, capabilities 17–20): member directory & lifecycle, committee
 * roles, family members, and KYC documents. Tenant-scoped by society_id.
 *
 * Lifecycle state machine (status):
 *   pending   -> approved | rejected
 *   approved  -> suspended | moved_out
 *   suspended -> approved | deactivated
 *   rejected / deactivated / moved_out are terminal.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

const TRANSITIONS: Record<string, string[]> = {
  pending: ["approved", "rejected"],
  approved: ["suspended", "moved_out"],
  suspended: ["approved", "deactivated"],
  rejected: [],
  deactivated: [],
  moved_out: [],
};

export const MemberService = {
  /** Invite/register a member — always created in the pending state. */
  async register(
    societyId: string,
    input: { name: string; phone?: string; email?: string; userId?: string; unitId?: string; role?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO members (society_id, user_id, name, phone, email, unit_id, role)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [societyId, input.userId || null, input.name, input.phone || null, input.email || null,
       input.unitId || null, input.role || null]
    );
    return rows[0];
  },

  async listMembers(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    params.push(Math.min(opts.limit || 200, 500));
    const { rows } = await db.query(
      `SELECT * FROM members WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`, params
    );
    return rows;
  },

  /** All committee members for a society (joined to the member directory). */
  async listCommittee(societyId: string) {
    const { rows } = await db.query(
      `SELECT cm.*, m.name AS member_name, m.phone AS member_phone,
              m.email AS member_email, m.unit_id, m.user_id
         FROM committee_members cm
         JOIN members m ON m.id = cm.member_id AND m.society_id = cm.society_id
        WHERE cm.society_id = $1
        ORDER BY cm.created_at DESC`,
      [societyId]
    );
    return rows;
  },

  async getMember(societyId: string, memberId: string) {
    const { rows } = await db.query(
      `SELECT * FROM members WHERE id = $1 AND society_id = $2`, [memberId, societyId]
    );
    const member = rows[0];
    if (!member) throw err("Member not found", "NOT_FOUND");
    const [family, committee, kyc] = await Promise.all([
      db.query(`SELECT * FROM family_members WHERE member_id = $1 AND society_id = $2 ORDER BY created_at ASC`, [memberId, societyId]),
      db.query(`SELECT * FROM committee_members WHERE member_id = $1 AND society_id = $2 ORDER BY created_at DESC`, [memberId, societyId]),
      db.query(`SELECT * FROM kyc_documents WHERE member_id = $1 AND society_id = $2 ORDER BY created_at DESC`, [memberId, societyId]),
    ]);
    return { ...member, family: family.rows, committee: committee.rows, kyc: kyc.rows };
  },

  /** Move a member to a new status, enforcing the lifecycle state machine. */
  async transition(societyId: string, memberId: string, to: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM members WHERE id = $1 AND society_id = $2 FOR UPDATE`, [memberId, societyId]
      );
      const member = cur.rows[0];
      if (!member) throw err("Member not found", "NOT_FOUND");
      const allowed = TRANSITIONS[member.status] || [];
      if (!allowed.includes(to)) {
        throw err(`Cannot transition member from ${member.status} to ${to}`, "INVALID_TRANSITION");
      }
      const { rows } = await client.query(
        `UPDATE members SET status = $3, version = version + 1, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [memberId, societyId, to]
      );
      logger.info({ societyId, memberId, from: member.status, to }, "Member transitioned");
      return rows[0];
    });
  },

  async addFamilyMember(
    societyId: string,
    memberId: string,
    input: { name: string; relation?: string; phone?: string; isEmergencyContact?: boolean }
  ) {
    const owner = await db.query(`SELECT id FROM members WHERE id = $1 AND society_id = $2`, [memberId, societyId]);
    if (!owner.rows[0]) throw err("Member not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO family_members (society_id, member_id, name, relation, phone, is_emergency_contact)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [societyId, memberId, input.name, input.relation || null, input.phone || null, input.isEmergencyContact ?? false]
    );
    return rows[0];
  },

  async addCommitteeRole(
    societyId: string,
    memberId: string,
    input: { designation: string; termStart?: string; termEnd?: string }
  ) {
    return withTx(async (client) => {
      const owner = await client.query(
        `SELECT id, name, user_id FROM members WHERE id = $1 AND society_id = $2`,
        [memberId, societyId]
      );
      const member = owner.rows[0];
      if (!member) throw err("Member not found", "NOT_FOUND");
      const { rows } = await client.query(
        `INSERT INTO committee_members (society_id, member_id, designation, term_start, term_end)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [societyId, memberId, input.designation, input.termStart || null, input.termEnd || null]
      );

      // Live notification: the added member + society admins (mirrors the
      // NoBrokerHood/MyGate "you've been added to the committee" behaviour).
      const admins = await Recipients.adminUserIds(client, societyId);
      const recipients = [member.user_id, ...admins].filter((u): u is string => !!u);
      await Recipients.fanOut(client, {
        societyId,
        eventType: "committee.member_added",
        payload: { memberId, designation: input.designation },
        recipients,
        notification: {
          title: "Added to committee",
          body: `${member.name} is now ${input.designation}`,
          type: "committee",
          data: { deepLink: `sero://members/${memberId}` },
        },
      });
      return rows[0];
    });
  },

  async addKyc(
    societyId: string,
    memberId: string,
    input: { docType: string; fileUrl?: string; expiresAt?: string }
  ) {
    const owner = await db.query(`SELECT id FROM members WHERE id = $1 AND society_id = $2`, [memberId, societyId]);
    if (!owner.rows[0]) throw err("Member not found", "NOT_FOUND");
    const { rows } = await db.query(
      `INSERT INTO kyc_documents (society_id, member_id, doc_type, file_url, expires_at)
       VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [societyId, memberId, input.docType, input.fileUrl || null, input.expiresAt || null]
    );
    return rows[0];
  },

  /** Approve or reject a KYC document. */
  async reviewKyc(
    societyId: string,
    kycId: string,
    decision: "approved" | "rejected",
    reason?: string,
    reviewedBy?: string
  ) {
    const { rows } = await db.query(
      `UPDATE kyc_documents
          SET status = $3, reject_reason = $4, reviewed_by = $5, updated_at = now()
        WHERE id = $1 AND society_id = $2 RETURNING *`,
      [kycId, societyId, decision, decision === "rejected" ? (reason || null) : null, reviewedBy || null]
    );
    if (!rows[0]) throw err("KYC document not found", "NOT_FOUND");
    return rows[0];
  },
};
