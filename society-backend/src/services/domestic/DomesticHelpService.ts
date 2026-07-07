import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { Recipients } from "../notifications/Recipients";

/**
 * Domestic help (§7.3): a resident registers a maid/cook/driver with a schedule
 * and an access status the gate honours. The guard logs check-in/check-out,
 * which notifies the resident. Tenant-scoped by society_id.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

type Ctx = { societyId: string; userId: string; memberId: string; unitId: string | null };

const VALID_STATUS = ["active", "paused", "revoked"];
const VALID_TYPES = ["maid", "cook", "driver", "nanny", "other"];

export const DomesticHelpService = {
  async list(ctx: Ctx, limit = 100) {
    const { rows } = await db.query(
      `SELECT * FROM domestic_helpers
        WHERE society_id = $1 AND member_id = $2
        ORDER BY created_at DESC LIMIT $3`,
      [ctx.societyId, ctx.memberId, Math.min(limit, 200)]
    );
    return rows;
  },

  async add(
    ctx: Ctx,
    input: { name: string; phone?: string; helperType?: string; photoUrl?: string; schedule?: Record<string, unknown> }
  ) {
    const helperType = VALID_TYPES.includes(input.helperType || "") ? input.helperType : "maid";
    const { rows } = await db.query(
      `INSERT INTO domestic_helpers
         (society_id, unit_id, member_id, created_by, name, phone, helper_type, photo_url, schedule, access_status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'active') RETURNING *`,
      [ctx.societyId, ctx.unitId, ctx.memberId, ctx.userId, input.name,
       input.phone || null, helperType, input.photoUrl || null, JSON.stringify(input.schedule || {})]
    );
    return rows[0];
  },

  /** Pause / revoke / re-activate gate access. Owner-scoped. */
  async updateStatus(ctx: Ctx, helperId: string, status: string) {
    if (!VALID_STATUS.includes(status)) throw err("Invalid access status", "INVALID_INPUT");
    const { rows } = await db.query(
      `UPDATE domestic_helpers SET access_status=$4
        WHERE id=$1 AND society_id=$2 AND member_id=$3 RETURNING *`,
      [helperId, ctx.societyId, ctx.memberId, status]
    );
    if (!rows[0]) throw err("Helper not found", "NOT_FOUND");
    return rows[0];
  },

  async remove(ctx: Ctx, helperId: string) {
    const { rows } = await db.query(
      `DELETE FROM domestic_helpers
        WHERE id=$1 AND society_id=$2 AND member_id=$3 RETURNING id`,
      [helperId, ctx.societyId, ctx.memberId]
    );
    if (!rows[0]) throw err("Helper not found", "NOT_FOUND");
    return { id: rows[0].id };
  },

  async history(ctx: Ctx, helperId: string, limit = 50) {
    const { rows } = await db.query(
      `SELECT l.* FROM domestic_help_logs l
         JOIN domestic_helpers h ON h.id = l.helper_id AND h.member_id = $3
        WHERE l.society_id = $1 AND l.helper_id = $2
        ORDER BY l.at DESC LIMIT $4`,
      [ctx.societyId, helperId, ctx.memberId, Math.min(limit, 200)]
    );
    return rows;
  },

  /**
   * Guard logs a check-in/check-out for a helper and notifies the owning
   * resident. Rejects a helper whose access is revoked.
   */
  async logAccess(
    societyId: string,
    helperId: string,
    action: "check_in" | "check_out",
    guardId?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM domestic_helpers WHERE id=$1 AND society_id=$2`,
        [helperId, societyId]
      );
      const h = rows[0];
      if (!h) throw err("Helper not found", "NOT_FOUND");
      if (h.access_status === "revoked") throw err("Access revoked for this helper", "INVALID_STATE");

      const { rows: logRows } = await client.query(
        `INSERT INTO domestic_help_logs (society_id, helper_id, unit_id, action, guard_id)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [societyId, helperId, h.unit_id || null, action, guardId || null]
      );
      const log = logRows[0];

      const residents = await Recipients.unitResidentUserIds(client, societyId, h.unit_id);
      const verb = action === "check_in" ? "checked in" : "checked out";
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: `domestic_help.${action}`,
        payload: { helperId, unitId: h.unit_id, action },
        recipients: residents,
        notification: {
          title: `${h.name} ${verb}`,
          body: `Your ${h.helper_type} ${h.name} has ${verb} at the gate.`,
          type: "domestic_help",
          data: { helperId, action, deepLink: `sero://domestic-help/${helperId}` },
        },
      });
      logger.info({ societyId, helperId, action, notified }, "Domestic help access logged + resident notified");
      return log;
    });
  },
};
