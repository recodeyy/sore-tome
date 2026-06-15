import { db } from "../../shared/Database";

/**
 * Configurable dashboard widgets and saved filters per admin (capability 8).
 * One row per (society_id, user_id), tenant-scoped and upserted so the admin's
 * layout survives across sessions. `widgets`/`saved_filters` are opaque JSON
 * arrays owned by the client; the server only persists and scopes them.
 */

const DEFAULTS = { widgets: [], saved_filters: [] };

export const PreferenceService = {
  /** Fetch the caller's preferences, or sensible defaults if none saved yet. */
  async get(societyId: string, userId: string) {
    const { rows } = await db.query(
      `SELECT widgets, saved_filters FROM dashboard_preferences
        WHERE society_id = $1 AND user_id = $2`,
      [societyId, userId]
    );
    if (!rows[0]) return { ...DEFAULTS };
    return { widgets: rows[0].widgets, savedFilters: rows[0].saved_filters };
  },

  /** Upsert the caller's preferences. Either field is optional. */
  async save(
    societyId: string,
    userId: string,
    input: { widgets?: any[]; savedFilters?: any[] }
  ) {
    const widgets = JSON.stringify(input.widgets ?? []);
    const savedFilters = JSON.stringify(input.savedFilters ?? []);
    const { rows } = await db.query(
      `INSERT INTO dashboard_preferences (society_id, user_id, widgets, saved_filters)
       VALUES ($1,$2,$3::jsonb,$4::jsonb)
       ON CONFLICT (society_id, user_id) DO UPDATE
         SET widgets = EXCLUDED.widgets,
             saved_filters = EXCLUDED.saved_filters,
             updated_at = now()
       RETURNING widgets, saved_filters`,
      [societyId, userId, widgets, savedFilters]
    );
    return { widgets: rows[0].widgets, savedFilters: rows[0].saved_filters };
  },
};
