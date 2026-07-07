import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { Recipients } from "../notifications/Recipients";

/**
 * Parcels (§8): a guard logs a delivery for a flat, the resident(s) are
 * notified with a one-time collection OTP, and the parcel is handed over when
 * the resident presents that OTP. Tenant-scoped by society_id; updates filter
 * on (id, society_id) so no cross-society mutation is possible.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

function genOtp(): string {
  return String(Math.floor(100000 + Math.random() * 900000)); // 6-digit
}

export const ParcelService = {
  /** Guard logs a new parcel for a unit and notifies its residents. */
  async log(
    societyId: string,
    input: {
      unitId?: string;
      recipientName?: string;
      courier: string;
      trackingCode?: string;
      description?: string;
      photoUrl?: string;
      loggedBy?: string;
    }
  ) {
    return withTx(async (client) => {
      const otp = genOtp();
      const { rows } = await client.query(
        `INSERT INTO parcels
           (society_id, unit_id, recipient_name, courier, tracking_code, description, photo_url, status, otp, logged_by)
         VALUES ($1,$2,$3,$4,$5,$6,$7,'pending',$8,$9) RETURNING *`,
        [societyId, input.unitId || null, input.recipientName || null, input.courier,
         input.trackingCode || null, input.description || null, input.photoUrl || null, otp, input.loggedBy || null]
      );
      const p = rows[0];

      const residents = await Recipients.unitResidentUserIds(client, societyId, p.unit_id);
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: "parcel.received",
        payload: { id: p.id, unitId: p.unit_id, courier: p.courier },
        recipients: residents,
        notification: {
          title: "Parcel at the gate",
          body: `A ${p.courier} parcel has arrived. Show OTP ${otp} at the gate to collect.`,
          type: "parcel",
          data: { parcelId: p.id, otp, deepLink: `sero://parcels/${p.id}` },
        },
      });
      logger.info({ societyId, parcelId: p.id, notified }, "Parcel logged + residents notified");
      return p;
    });
  },

  /** Parcels for a single unit (resident view). */
  async listForUnit(societyId: string, unitId: string | null | undefined, limit = 50) {
    if (!unitId) return [];
    const { rows } = await db.query(
      `SELECT * FROM parcels WHERE society_id = $1 AND unit_id::text = $2::text
        ORDER BY created_at DESC LIMIT $3`,
      [societyId, String(unitId), Math.min(limit, 200)]
    );
    return rows;
  },

  /** All parcels for the society (guard/admin view), optionally by status. */
  async listAll(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let filter = "";
    if (opts.status) {
      params.push(opts.status);
      filter = ` AND status = $2`;
    }
    params.push(Math.min(opts.limit || 100, 500));
    const { rows } = await db.query(
      `SELECT * FROM parcels WHERE society_id = $1${filter}
        ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /**
   * Mark a parcel collected. Requires the resident's OTP (single collection).
   * Idempotent: re-collecting an already-collected parcel returns it unchanged
   * rather than double-notifying.
   */
  async collect(
    societyId: string,
    parcelId: string,
    input: { otp: string; collectedBy?: string }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM parcels WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [parcelId, societyId]
      );
      const p = rows[0];
      if (!p) throw err("Parcel not found", "NOT_FOUND");
      if (p.status === "collected") return p; // idempotent
      if (p.status !== "pending") throw err(`Cannot collect a parcel in '${p.status}' state`, "INVALID_STATE");
      if (!input.otp || String(input.otp).trim() !== String(p.otp)) {
        throw err("Incorrect collection OTP", "INVALID_OTP");
      }

      const { rows: upd } = await client.query(
        `UPDATE parcels SET status='collected', collected_by=$3, collected_at=now()
          WHERE id=$1 AND society_id=$2 RETURNING *`,
        [parcelId, societyId, input.collectedBy || null]
      );
      const collected = upd[0];

      const residents = await Recipients.unitResidentUserIds(client, societyId, collected.unit_id);
      const notified = await Recipients.fanOut(client, {
        societyId,
        eventType: "parcel.collected",
        payload: { id: collected.id, unitId: collected.unit_id },
        recipients: residents,
        notification: {
          title: "Parcel collected",
          body: `Your ${collected.courier} parcel has been handed over.`,
          type: "parcel",
          data: { parcelId: collected.id, deepLink: `sero://parcels/${collected.id}` },
        },
      });
      logger.info({ societyId, parcelId: collected.id, notified }, "Parcel collected + residents notified");
      return collected;
    });
  },
};
