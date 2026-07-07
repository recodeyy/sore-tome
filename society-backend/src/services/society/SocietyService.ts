import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { StructureService } from "../structure/StructureService";

/**
 * Admin Society Setup (capabilities 9, 10, 21, 22): society profile, logo/branding,
 * society settings, and onboarding checklist. Tenant-scoped by society_id.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

export const SocietyService = {
  // ---- Cap 9: Society profile -------------------------------------------
  async getProfile(societyId: string) {
    const { rows } = await db.query(`SELECT * FROM society_profiles WHERE society_id = $1`, [societyId]);
    return rows[0] || null;
  },

  /** Create-or-update the society profile (one row per society). */
  async upsertProfile(
    societyId: string,
    input: {
      name?: string; registrationNo?: string; address?: string; timezone?: string;
      currency?: string; financialYearStart?: string; contacts?: any[];
    }
  ) {
    const { rows } = await db.query(
      `INSERT INTO society_profiles
         (society_id, name, registration_no, address, timezone, currency, financial_year_start, contacts)
       VALUES ($1,$2,$3,$4, COALESCE($5,'Asia/Kolkata'), COALESCE($6,'INR'), COALESCE($7,'04-01'), COALESCE($8,'[]')::jsonb)
       ON CONFLICT (society_id) DO UPDATE SET
         name = COALESCE($2, society_profiles.name),
         registration_no = COALESCE($3, society_profiles.registration_no),
         address = COALESCE($4, society_profiles.address),
         timezone = COALESCE($5, society_profiles.timezone),
         currency = COALESCE($6, society_profiles.currency),
         financial_year_start = COALESCE($7, society_profiles.financial_year_start),
         contacts = COALESCE($8::jsonb, society_profiles.contacts),
         version = society_profiles.version + 1,
         updated_at = now()
       RETURNING *`,
      [societyId, input.name ?? null, input.registrationNo ?? null, input.address ?? null,
       input.timezone ?? null, input.currency ?? null, input.financialYearStart ?? null,
       input.contacts ? JSON.stringify(input.contacts) : null]
    );
    return rows[0];
  },

  // ---- Cap 21: Society settings -----------------------------------------
  async getSettings(societyId: string) {
    const { rows } = await db.query(`SELECT * FROM society_settings WHERE society_id = $1`, [societyId]);
    return rows[0] || null;
  },

  /** Create-or-update settings; each jsonb section is merged (shallow) when provided. */
  async upsertSettings(
    societyId: string,
    input: {
      numbering?: any; billingDefaults?: any; notificationPrefs?: any;
      bookingPolicy?: any; featureFlags?: any;
    }
  ) {
    const j = (v: any) => (v === undefined ? null : JSON.stringify(v));
    const { rows } = await db.query(
      `INSERT INTO society_settings
         (society_id, numbering, billing_defaults, notification_prefs, booking_policy, feature_flags)
       VALUES ($1, COALESCE($2::jsonb,'{}'), COALESCE($3::jsonb,'{}'), COALESCE($4::jsonb,'{}'), COALESCE($5::jsonb,'{}'), COALESCE($6::jsonb,'{}'))
       ON CONFLICT (society_id) DO UPDATE SET
         numbering = society_settings.numbering || COALESCE($2::jsonb, '{}'::jsonb),
         billing_defaults = society_settings.billing_defaults || COALESCE($3::jsonb, '{}'::jsonb),
         notification_prefs = society_settings.notification_prefs || COALESCE($4::jsonb, '{}'::jsonb),
         booking_policy = society_settings.booking_policy || COALESCE($5::jsonb, '{}'::jsonb),
         feature_flags = society_settings.feature_flags || COALESCE($6::jsonb, '{}'::jsonb),
         version = society_settings.version + 1,
         updated_at = now()
       RETURNING *`,
      [societyId, j(input.numbering), j(input.billingDefaults), j(input.notificationPrefs),
       j(input.bookingPolicy), j(input.featureFlags)]
    );
    return rows[0];
  },

  // ---- Cap 10: Logo / branding ------------------------------------------
  async getLogo(societyId: string) {
    const { rows } = await db.query(
      `SELECT * FROM society_logos WHERE society_id = $1 AND is_current = true AND deleted_at IS NULL`,
      [societyId]
    );
    return rows[0] || null;
  },

  /** Set or replace the logo — supersedes the previous current logo (version + 1). */
  async setLogo(societyId: string, fileUrl: string) {
    return withTx(async (client) => {
      const prev = await client.query(
        `SELECT max(version) AS v FROM society_logos WHERE society_id = $1`, [societyId]
      );
      const nextVersion = (prev.rows[0]?.v || 0) + 1;
      await client.query(
        `UPDATE society_logos SET is_current = false WHERE society_id = $1 AND is_current = true`, [societyId]
      );
      const { rows } = await client.query(
        `INSERT INTO society_logos (society_id, file_url, version, is_current)
         VALUES ($1,$2,$3,true) RETURNING *`,
        [societyId, fileUrl, nextVersion]
      );
      logger.info({ societyId, version: nextVersion }, "Society logo set");
      return rows[0];
    });
  },

  /** Soft-delete the current logo (no current logo remains). */
  async deleteLogo(societyId: string) {
    const { rows } = await db.query(
      `UPDATE society_logos SET is_current = false, deleted_at = now()
        WHERE society_id = $1 AND is_current = true AND deleted_at IS NULL RETURNING *`,
      [societyId]
    );
    if (!rows[0]) throw err("No current logo", "NOT_FOUND");
    return rows[0];
  },

  // ---- Cap 22: Onboarding checklist -------------------------------------
  /** Setup completion % + blockers across profile, structure, members, finance. */
  async setupProgress(societyId: string) {
    const [profile, settings, logo, structure, memberCount, financeCount] = await Promise.all([
      this.getProfile(societyId),
      this.getSettings(societyId),
      this.getLogo(societyId),
      StructureService.summary(societyId),
      db.query(`SELECT count(*)::int n FROM members WHERE society_id = $1`, [societyId]),
      db.query(`SELECT count(*)::int n FROM journal_entries WHERE society_id = $1`, [societyId])
        .catch(() => ({ rows: [{ n: 0 }] })),
    ]);

    const items = [
      { key: "profile", label: "Society profile", done: !!(profile && profile.name) },
      { key: "branding", label: "Logo / branding", done: !!logo },
      { key: "settings", label: "Society settings", done: !!settings },
      { key: "structure", label: "Units created", done: structure.units > 0 },
      { key: "members", label: "Members added", done: memberCount.rows[0].n > 0 },
      { key: "finance", label: "Finance initialized", done: financeCount.rows[0].n > 0 },
    ];

    const completed = items.filter((i) => i.done).length;
    const percent = Math.round((completed / items.length) * 100);
    const blockers = items.filter((i) => !i.done).map((i) => i.key);

    return { percent, completed, total: items.length, items, blockers, structure };
  },
};
