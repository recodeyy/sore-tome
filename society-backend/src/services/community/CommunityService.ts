import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";

/**
 * Community module: Marketplace, Carpool, Lost & Found.
 *
 * Tenant-scoped by society_id. Any authenticated member may read and post;
 * posters can mark their items sold/closed/resolved (society-scoped).
 *
 * Prod has no migration-on-deploy, so `ensureSchema()` creates the tables
 * idempotently (CREATE TABLE IF NOT EXISTS) and is invoked once at startup.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

// Attach the poster's display name (members.name) for any of the three tables.
const POSTER_JOIN = (table: string) =>
  `LEFT JOIN members m ON m.user_id = ${table}.posted_by AND m.society_id = ${table}.society_id`;

export const CommunityService = {
  async ensureSchema() {
    await db.query(`
      CREATE TABLE IF NOT EXISTS marketplace_items (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        society_id text NOT NULL,
        posted_by text,
        title text NOT NULL,
        description text,
        price_minor bigint DEFAULT 0,
        category text,
        status text NOT NULL DEFAULT 'available',
        created_at timestamptz NOT NULL DEFAULT now()
      )`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_marketplace_items_society ON marketplace_items (society_id)`);

    await db.query(`
      CREATE TABLE IF NOT EXISTS carpool_rides (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        society_id text NOT NULL,
        posted_by text,
        from_location text NOT NULL,
        to_location text NOT NULL,
        ride_time timestamptz,
        seats int DEFAULT 1,
        notes text,
        status text NOT NULL DEFAULT 'open',
        created_at timestamptz DEFAULT now()
      )`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_carpool_rides_society ON carpool_rides (society_id)`);

    await db.query(`
      CREATE TABLE IF NOT EXISTS lost_found_items (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        society_id text NOT NULL,
        posted_by text,
        kind text NOT NULL DEFAULT 'lost',
        title text NOT NULL,
        description text,
        location text,
        status text NOT NULL DEFAULT 'open',
        created_at timestamptz DEFAULT now()
      )`);
    await db.query(`CREATE INDEX IF NOT EXISTS idx_lost_found_items_society ON lost_found_items (society_id)`);

    logger.info("Community schema ensured (marketplace_items, carpool_rides, lost_found_items)");
  },

  // ---- Marketplace ------------------------------------------------------
  async listMarketplace(societyId: string) {
    const { rows } = await db.query(
      `SELECT marketplace_items.*, m.name AS poster_name
         FROM marketplace_items
         ${POSTER_JOIN("marketplace_items")}
        WHERE marketplace_items.society_id = $1
        ORDER BY marketplace_items.created_at DESC`,
      [societyId]
    );
    return rows;
  },

  async createMarketplaceItem(
    societyId: string,
    input: { title: string; description?: string; priceMinor?: number; category?: string; postedBy?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO marketplace_items (society_id, posted_by, title, description, price_minor, category)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [societyId, input.postedBy || null, input.title, input.description || null,
       input.priceMinor ?? 0, input.category || null]
    );
    return rows[0];
  },

  async markMarketplaceSold(societyId: string, id: string) {
    const { rows } = await db.query(
      `UPDATE marketplace_items SET status = 'sold' WHERE id = $1 AND society_id = $2 RETURNING *`,
      [id, societyId]
    );
    if (!rows[0]) throw err("Marketplace item not found", "NOT_FOUND");
    return rows[0];
  },

  // ---- Carpool ----------------------------------------------------------
  async listCarpool(societyId: string) {
    const { rows } = await db.query(
      `SELECT carpool_rides.*, m.name AS poster_name
         FROM carpool_rides
         ${POSTER_JOIN("carpool_rides")}
        WHERE carpool_rides.society_id = $1
        ORDER BY carpool_rides.created_at DESC`,
      [societyId]
    );
    return rows;
  },

  async createCarpoolRide(
    societyId: string,
    input: { fromLocation: string; toLocation: string; rideTime?: string; seats?: number; notes?: string; postedBy?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO carpool_rides (society_id, posted_by, from_location, to_location, ride_time, seats, notes)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [societyId, input.postedBy || null, input.fromLocation, input.toLocation,
       input.rideTime || null, input.seats ?? 1, input.notes || null]
    );
    return rows[0];
  },

  async closeCarpoolRide(societyId: string, id: string) {
    const { rows } = await db.query(
      `UPDATE carpool_rides SET status = 'closed' WHERE id = $1 AND society_id = $2 RETURNING *`,
      [id, societyId]
    );
    if (!rows[0]) throw err("Carpool ride not found", "NOT_FOUND");
    return rows[0];
  },

  // ---- Lost & Found -----------------------------------------------------
  async listLostFound(societyId: string) {
    const { rows } = await db.query(
      `SELECT lost_found_items.*, m.name AS poster_name
         FROM lost_found_items
         ${POSTER_JOIN("lost_found_items")}
        WHERE lost_found_items.society_id = $1
        ORDER BY lost_found_items.created_at DESC`,
      [societyId]
    );
    return rows;
  },

  async createLostFoundItem(
    societyId: string,
    input: { kind: "lost" | "found"; title: string; description?: string; location?: string; postedBy?: string }
  ) {
    const { rows } = await db.query(
      `INSERT INTO lost_found_items (society_id, posted_by, kind, title, description, location)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [societyId, input.postedBy || null, input.kind, input.title,
       input.description || null, input.location || null]
    );
    return rows[0];
  },

  async resolveLostFoundItem(societyId: string, id: string) {
    const { rows } = await db.query(
      `UPDATE lost_found_items SET status = 'resolved' WHERE id = $1 AND society_id = $2 RETURNING *`,
      [id, societyId]
    );
    if (!rows[0]) throw err("Lost & found item not found", "NOT_FOUND");
    return rows[0];
  },
};
