import { db } from "../../shared/Database";
import { toCsv } from "../../shared/csv";

/**
 * Capability 92: immutable, tenant-scoped administrative audit log over the
 * Postgres `audit_logs` table. Rows are append-only (enforced by DB triggers).
 * Provides filtered read + CSV export; the export action is itself recorded.
 */

export interface AuditRecordInput {
  societyId: string;
  actorId?: string | null;
  actorName?: string | null;
  action: string;
  resource?: string | null;
  result?: string;
  ip?: string | null;
  requestId?: string | null;
  reason?: string | null;
  before?: any;
  after?: any;
}

interface QueryOpts {
  actorId?: string;
  from?: string; // ISO
  to?: string; // ISO
  limit?: number;
}

function buildWhere(societyId: string, opts: QueryOpts) {
  const params: any[] = [societyId];
  let where = `society_id = $1`;
  if (opts.actorId) { params.push(opts.actorId); where += ` AND actor_id = $${params.length}`; }
  if (opts.from) { params.push(opts.from); where += ` AND created_at >= $${params.length}`; }
  if (opts.to) { params.push(opts.to); where += ` AND created_at <= $${params.length}`; }
  return { where, params };
}

export const PgAuditService = {
  /** Append a single immutable audit record. */
  async record(input: AuditRecordInput) {
    const { rows } = await db.query(
      `INSERT INTO audit_logs
         (society_id, actor_id, actor_name, action, resource, result, ip, request_id, reason, before, after)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [
        input.societyId, input.actorId || null, input.actorName || null, input.action,
        input.resource || null, input.result || "success", input.ip || null,
        input.requestId || null, input.reason || null,
        JSON.stringify(input.before ?? {}), JSON.stringify(input.after ?? {}),
      ]
    );
    return rows[0];
  },

  /** Tenant-scoped, filtered read. */
  async query(societyId: string, opts: QueryOpts = {}) {
    const { where, params } = buildWhere(societyId, opts);
    params.push(Math.min(opts.limit || 100, 1000));
    const { rows } = await db.query(
      `SELECT * FROM audit_logs WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  /**
   * Export matching audit rows as CSV (formula-injection safe). The export
   * itself is recorded as a new audit event before returning.
   */
  async exportCsv(
    societyId: string,
    opts: QueryOpts = {},
    actor?: { id?: string | null; name?: string | null; ip?: string | null; requestId?: string | null }
  ): Promise<string> {
    const { where, params } = buildWhere(societyId, opts);
    const { rows } = await db.query(
      `SELECT id, created_at, actor_id, actor_name, action, resource, result, ip, request_id, reason
         FROM audit_logs WHERE ${where} ORDER BY created_at DESC`,
      params
    );
    const headers = ["id", "created_at", "actor_id", "actor_name", "action", "resource", "result", "ip", "request_id", "reason"];
    const csv = toCsv(headers, rows);

    await this.record({
      societyId,
      actorId: actor?.id,
      actorName: actor?.name,
      action: "audit.export",
      resource: "audit_logs",
      ip: actor?.ip,
      requestId: actor?.requestId,
      after: { rowCount: rows.length, filters: opts },
    });

    return csv;
  },
};
