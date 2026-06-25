import type { PoolClient } from "pg";
import { OutboxService } from "../outbox/OutboxService";

/**
 * Cross-role notification fan-out helpers.
 *
 * These resolve the correct recipient user_ids for a domain event and insert
 * `notifications` rows INSIDE the caller's transaction (the same `withTx`
 * client that performed the state change), exactly mirroring the established
 * pattern in NoticeService.publish. They never modify the OutboxService or
 * NotificationService; they only reuse them.
 *
 * Recipient resolution rules (tenant-scoped by society_id throughout):
 *  - admins      -> members with an administrative/committee role + a linked login
 *  - unit        -> approved members whose unit_id matches (a unit's residents)
 *                   plus any current unit_occupancies.resident_id for that unit
 *  - staff/role  -> active staff rows (optionally filtered by role) with a login
 *
 * All inserts are de-duplicated per user so a single person never receives the
 * same event twice (e.g. an admin who is also a committee member).
 */

/** Administrative + committee roles that should receive "admin" notifications. */
const ADMIN_ROLES = ["main_admin", "admin", "secretary", "treasurer", "president", "committee", "manager"];

/** Staff roles considered "security" for SOS/incident fan-out. */
const SECURITY_ROLES = ["guard", "security_manager", "security", "supervisor"];

export interface NotifyInput {
  title: string;
  body?: string;
  type: string;
  data?: Record<string, unknown>;
}

async function insertNotifications(
  client: PoolClient,
  societyId: string,
  userIds: string[],
  n: NotifyInput
): Promise<number> {
  const unique = Array.from(new Set(userIds.filter((u): u is string => !!u)));
  for (const userId of unique) {
    await client.query(
      `INSERT INTO notifications (society_id, user_id, title, body, type, data)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [societyId, userId, n.title, n.body || null, n.type, JSON.stringify(n.data || {})]
    );
  }
  return unique.length;
}

export const Recipients = {
  /** user_ids of administrators / committee for a society. */
  async adminUserIds(client: PoolClient, societyId: string): Promise<string[]> {
    const { rows } = await client.query(
      `SELECT DISTINCT user_id FROM members
        WHERE society_id = $1 AND status = 'approved'
          AND user_id IS NOT NULL AND role = ANY($2)`,
      [societyId, ADMIN_ROLES]
    );
    return rows.map((r: any) => r.user_id);
  },

  /**
   * user_ids of the residents of a single unit (tenant isolation: only this
   * unit's residents). Resolves both members.unit_id and unit_occupancies.
   * unit_id may be a uuid (members.unit_id) or text; both are matched as text.
   */
  async unitResidentUserIds(client: PoolClient, societyId: string, unitId: string | null | undefined): Promise<string[]> {
    if (!unitId) return [];
    const { rows } = await client.query(
      `SELECT user_id FROM members
         WHERE society_id = $1 AND status = 'approved'
           AND user_id IS NOT NULL AND unit_id::text = $2::text
       UNION
       SELECT resident_id AS user_id FROM unit_occupancies
         WHERE society_id = $1 AND to_date IS NULL
           AND resident_id IS NOT NULL AND unit_id::text = $2::text`,
      [societyId, String(unitId)]
    );
    return rows.map((r: any) => r.user_id).filter((u: any) => !!u);
  },

  /** user_ids of active staff, optionally filtered to a set of roles. */
  async staffUserIds(client: PoolClient, societyId: string, roles?: string[]): Promise<string[]> {
    const params: any[] = [societyId];
    let roleFilter = "";
    if (roles && roles.length) {
      params.push(roles);
      roleFilter = ` AND role = ANY($2)`;
    }
    const { rows } = await client.query(
      `SELECT DISTINCT user_id FROM staff
        WHERE society_id = $1 AND status = 'active' AND user_id IS NOT NULL${roleFilter}`,
      params
    );
    return rows.map((r: any) => r.user_id);
  },

  /** Security/guard staff user_ids for SOS/incident fan-out. */
  async securityStaffUserIds(client: PoolClient, societyId: string): Promise<string[]> {
    return Recipients.staffUserIds(client, societyId, SECURITY_ROLES);
  },

  /**
   * Emit a domain outbox event AND insert notification rows for the given
   * recipients — all on the caller's transaction client. Returns the count of
   * distinct recipients notified. This is the single entry point services call.
   */
  async fanOut(
    client: PoolClient,
    args: {
      societyId: string;
      eventType: string;
      payload?: Record<string, unknown>;
      recipients: string[];
      notification: NotifyInput;
    }
  ): Promise<number> {
    await OutboxService.emit(client, {
      societyId: args.societyId,
      topic: `society:${args.societyId}`,
      type: args.eventType,
      payload: args.payload || {},
    });
    return insertNotifications(client, args.societyId, args.recipients, args.notification);
  },
};
