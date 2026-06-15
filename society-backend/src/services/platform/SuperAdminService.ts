import { db } from "../../shared/Database";

type QueryParams = Array<string | number | boolean | null>;

async function queryRows<T = any>(sql: string, params: QueryParams = []): Promise<T[]> {
  try {
    const result = await db.query(sql, params);
    return result.rows as T[];
  } catch (error: any) {
    if (error?.code === "42P01" || error?.code === "42703") {
      return [];
    }
    throw error;
  }
}

async function queryOne<T = any>(sql: string, params: QueryParams = [], fallback: T): Promise<T> {
  const rows = await queryRows<T>(sql, params);
  return rows[0] ?? fallback;
}

function clampLimit(value: unknown, fallback = 25): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(Math.max(parsed, 1), 100);
}

function offsetFromCursor(cursor: unknown): number {
  const parsed = Number(cursor);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 0;
}

export class SuperAdminService {
  static normalizeRole(role?: string): string {
    return role === "superadmin" ? "super_admin" : role || "";
  }

  static isSuperAdmin(role?: string): boolean {
    return this.normalizeRole(role) === "super_admin";
  }

  static async overview() {
    const societyBreakdown = await queryOne(
      `
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE status = 'active')::int AS active,
          COUNT(*) FILTER (WHERE status = 'trial')::int AS trial,
          COUNT(*) FILTER (WHERE status = 'suspended')::int AS suspended,
          COUNT(*) FILTER (WHERE status = 'grace')::int AS payment_due
        FROM society_subscriptions
      `,
      [],
      { total: 0, active: 0, trial: 0, suspended: 0, payment_due: 0 }
    );

    const applications = await queryOne(
      `
        SELECT
          COUNT(*) FILTER (WHERE status = 'pending')::int AS pending_approvals,
          COUNT(*) FILTER (WHERE status = 'approved')::int AS approved,
          COUNT(*) FILTER (WHERE status = 'rejected')::int AS rejected
        FROM society_applications
      `,
      [],
      { pending_approvals: 0, approved: 0, rejected: 0 }
    );

    const users = await queryOne(
      `
        SELECT
          COUNT(*)::int AS total_users,
          COUNT(*) FILTER (WHERE status = 'approved')::int AS active_users
        FROM members
      `,
      [],
      { total_users: 0, active_users: 0 }
    );

    const revenue = await queryOne(
      `
        SELECT
          COALESCE(SUM(sp.price_minor) FILTER (WHERE ss.status IN ('active', 'trial', 'grace')), 0)::bigint AS mrr_minor,
          COALESCE(SUM(sp.price_minor * 12) FILTER (WHERE ss.status IN ('active', 'trial', 'grace')), 0)::bigint AS arr_minor,
          COUNT(*) FILTER (WHERE ss.status = 'grace')::int AS failed_payments
        FROM society_subscriptions ss
        LEFT JOIN subscription_plans sp ON sp.id = ss.plan_id
      `,
      [],
      { mrr_minor: 0, arr_minor: 0, failed_payments: 0 }
    );

    const support = await queryOne(
      `
        SELECT
          COUNT(*) FILTER (WHERE status IN ('open', 'in_progress'))::int AS open_tickets,
          COUNT(*) FILTER (WHERE priority = 'urgent' AND status IN ('open', 'in_progress'))::int AS urgent_tickets
        FROM support_tickets
      `,
      [],
      { open_tickets: 0, urgent_tickets: 0 }
    );

    return {
      asOf: new Date().toISOString(),
      societies: societyBreakdown,
      applications,
      users,
      revenue,
      support,
      systemHealth: {
        status: "operational",
        api: "ok",
        database: "ok",
        queue: "unknown",
        aiProviders: "unknown",
      },
      adoption: {
        dau: 0,
        mau: Number(users.active_users || 0),
        churnRate: 0,
        activeModules: ["notices", "complaints", "finance", "ai_copilot"],
      },
    };
  }

  static async societies(filters: { status?: string; q?: string; limit?: unknown; cursor?: unknown }) {
    const limit = clampLimit(filters.limit);
    const offset = offsetFromCursor(filters.cursor);
    const params: QueryParams = [];
    const clauses: string[] = [];

    if (filters.status && filters.status !== "all") {
      params.push(filters.status);
      clauses.push(`ss.status = $${params.length}`);
    }
    if (filters.q) {
      params.push(`%${filters.q.toLowerCase()}%`);
      clauses.push(`LOWER(COALESCE(sa.society_name, ss.society_id)) LIKE $${params.length}`);
    }

    params.push(limit + 1, offset);
    const where = clauses.length ? `WHERE ${clauses.join(" AND ")}` : "";

    const rows = await queryRows(
      `
        SELECT
          ss.society_id AS id,
          COALESCE(sa.society_name, ss.society_id) AS name,
          COALESCE(sa.contact_email, '') AS contact_email,
          ss.status,
          ss.renews_at,
          ss.effective_date,
          sp.name AS plan_name,
          sp.code AS plan_code,
          sp.price_minor,
          COALESCE(member_counts.member_count, 0)::int AS member_count,
          ss.updated_at,
          ss.created_at
        FROM society_subscriptions ss
        LEFT JOIN subscription_plans sp ON sp.id = ss.plan_id
        LEFT JOIN society_applications sa ON sa.society_id = ss.society_id
        LEFT JOIN (
          SELECT society_id, COUNT(*) AS member_count
          FROM members
          GROUP BY society_id
        ) member_counts ON member_counts.society_id = ss.society_id
        ${where}
        ORDER BY ss.updated_at DESC NULLS LAST, ss.created_at DESC
        LIMIT $${params.length - 1} OFFSET $${params.length}
      `,
      params
    );

    const hasMore = rows.length > limit;
    const data = hasMore ? rows.slice(0, limit) : rows;
    return {
      data,
      nextCursor: hasMore ? String(offset + limit) : null,
    };
  }

  static async societyDetail(societyId: string) {
    const summary = await queryOne(
      `
        SELECT
          ss.society_id AS id,
          COALESCE(sa.society_name, ss.society_id) AS name,
          COALESCE(sa.contact_email, '') AS contact_email,
          ss.status,
          ss.renews_at,
          ss.effective_date,
          sp.id AS plan_id,
          sp.name AS plan_name,
          sp.code AS plan_code,
          sp.price_minor,
          sp.currency,
          sp.interval,
          ss.created_at,
          ss.updated_at
        FROM society_subscriptions ss
        LEFT JOIN subscription_plans sp ON sp.id = ss.plan_id
        LEFT JOIN society_applications sa ON sa.society_id = ss.society_id
        WHERE ss.society_id = $1
      `,
      [societyId],
      null as any
    );

    if (!summary) return null;

    const memberCounts = await queryOne(
      `
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE status = 'approved')::int AS active,
          COUNT(*) FILTER (WHERE role IN ('main_admin', 'admin', 'secretary', 'treasurer'))::int AS admins
        FROM members
        WHERE society_id = $1
      `,
      [societyId],
      { total: 0, active: 0, admins: 0 }
    );

    const features = await queryRows(
      `
        SELECT pf.key, pf.name, COALESCE(sfo.enabled, pf.default_enabled) AS enabled
        FROM platform_features pf
        LEFT JOIN society_feature_overrides sfo
          ON sfo.feature_key = pf.key AND sfo.society_id = $1
        ORDER BY pf.name ASC
      `,
      [societyId]
    );

    const support = await queryRows(
      `
        SELECT id, subject, priority, status, assignee_id, created_at, updated_at
        FROM support_tickets
        WHERE society_id = $1
        ORDER BY updated_at DESC
        LIMIT 10
      `,
      [societyId]
    );

    return { ...summary, members: memberCounts, features, support };
  }

  static async applications(status = "pending") {
    return queryRows(
      `
        SELECT id, society_name, contact_email, status, society_id, reviewer_id, reject_reason, version, created_at, updated_at
        FROM society_applications
        WHERE ($1 = 'all' OR status = $1)
        ORDER BY created_at ASC
        LIMIT 100
      `,
      [status]
    );
  }

  static async reviewApplication(id: string, action: "approve" | "reject", actorId: string, reason?: string) {
    if (action === "reject" && !reason?.trim()) {
      const error = new Error("Reject reason is required");
      (error as any).statusCode = 400;
      throw error;
    }

    const status = action === "approve" ? "approved" : "rejected";
    const rows = await queryRows(
      `
        UPDATE society_applications
        SET status = $2,
            reviewer_id = $3,
            reject_reason = $4,
            updated_at = NOW(),
            version = version + 1,
            society_id = COALESCE(society_id, CASE WHEN $2 = 'approved' THEN 'soc_' || replace(id::text, '-', '') ELSE society_id END)
        WHERE id = $1 AND status = 'pending'
        RETURNING *
      `,
      [id, status, actorId, reason || null]
    );

    return rows[0] ?? null;
  }

  static async plans() {
    return queryRows(
      `
        SELECT id, code, name, price_minor, currency, interval, features, is_active, created_at
        FROM subscription_plans
        ORDER BY is_active DESC, price_minor ASC, name ASC
      `
    );
  }

  static async supportTickets(status = "open") {
    return queryRows(
      `
        SELECT id, society_id, subject, body, priority, status, assignee_id, requester_id, version, created_at, updated_at
        FROM support_tickets
        WHERE ($1 = 'all' OR status = $1)
        ORDER BY
          CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END,
          updated_at DESC
        LIMIT 100
      `,
      [status]
    );
  }

  static async setFeatureOverride(societyId: string, featureKey: string, enabled: boolean, actorId: string) {
    const rows = await queryRows(
      `
        INSERT INTO society_feature_overrides (society_id, feature_key, enabled, actor_id, updated_at)
        VALUES ($1, $2, $3, $4, NOW())
        ON CONFLICT (society_id, feature_key)
        DO UPDATE SET enabled = EXCLUDED.enabled, actor_id = EXCLUDED.actor_id, updated_at = NOW()
        RETURNING *
      `,
      [societyId, featureKey, enabled, actorId]
    );
    return rows[0];
  }

  static async startImpersonation(input: {
    actorId: string;
    targetUserId: string;
    societyId?: string;
    reason: string;
    durationMinutes: number;
  }) {
    if (!input.reason?.trim()) {
      const error = new Error("Reason is required");
      (error as any).statusCode = 400;
      throw error;
    }

    const duration = Math.min(Math.max(Number(input.durationMinutes) || 15, 5), 120);
    const rows = await queryRows(
      `
        INSERT INTO impersonation_sessions (actor_id, target_user_id, society_id, reason, expires_at)
        VALUES ($1, $2, $3, $4, NOW() + ($5 || ' minutes')::interval)
        RETURNING *
      `,
      [input.actorId, input.targetUserId, input.societyId || null, input.reason, duration]
    );
    return rows[0];
  }

  static async stopImpersonation(id: string, actorId: string) {
    const rows = await queryRows(
      `
        UPDATE impersonation_sessions
        SET status = 'ended', ended_at = NOW()
        WHERE id = $1 AND actor_id = $2 AND status = 'active'
        RETURNING *
      `,
      [id, actorId]
    );
    return rows[0] ?? null;
  }

  static async stopCurrentImpersonation(actorId: string) {
    const rows = await queryRows(
      `
        UPDATE impersonation_sessions
        SET status = 'ended', ended_at = NOW()
        WHERE actor_id = $1 AND status = 'active'
        RETURNING *
      `,
      [actorId]
    );
    return rows[0] ?? null;
  }

  static async auditLogs(limitInput?: unknown) {
    const limit = clampLimit(limitInput, 50);
    return queryRows(
      `
        SELECT id, action_id, tool_id, user_id, society_id, action, status, error_message, created_at
        FROM ai_audit_logs_partitioned
        ORDER BY created_at DESC
        LIMIT $1
      `,
      [limit]
    );
  }

  static async societyActivity(societyId: string, limitInput?: unknown) {
    const limit = clampLimit(limitInput, 50);
    return queryRows(
      `
        SELECT id, action_id, tool_id, user_id, society_id, action, status, error_message, created_at
        FROM ai_audit_logs_partitioned
        WHERE society_id = $1
        ORDER BY created_at DESC
        LIMIT $2
      `,
      [societyId, limit]
    );
  }

  static async suspendSociety(societyId: string, actorId: string, reason: string) {
    await queryRows(
      `
        UPDATE society_subscriptions
        SET status = 'suspended',
            updated_at = NOW()
        WHERE society_id = $1
      `,
      [societyId]
    );
    await queryRows(
      `
        INSERT INTO society_status_history (society_id, from_status, to_status, actor_id, reason)
        VALUES ($1, 'active', 'suspended', $2, $3)
      `,
      [societyId, actorId, reason]
    );
  }

  static async reactivateSociety(societyId: string, actorId: string, reason: string) {
    await queryRows(
      `
        UPDATE society_subscriptions
        SET status = 'active',
            updated_at = NOW()
        WHERE society_id = $1
      `,
      [societyId]
    );
    await queryRows(
      `
        INSERT INTO society_status_history (society_id, from_status, to_status, actor_id, reason)
        VALUES ($1, 'suspended', 'active', $2, $3)
      `,
      [societyId, actorId, reason]
    );
  }

  static async approveSociety(societyId: string, actorId: string, reason: string) {
    const app = await queryOne<any>(
      `SELECT id FROM society_applications WHERE society_id = $1 AND status = 'pending'`,
      [societyId],
      null
    );
    if (app) {
      await this.reviewApplication(app.id, "approve", actorId, reason);
    }
    const plan = await queryOne<any>(
      `SELECT id FROM subscription_plans WHERE is_active = true ORDER BY price_minor ASC LIMIT 1`,
      [],
      null
    );
    if (plan) {
      await queryRows(
        `
          INSERT INTO society_subscriptions (society_id, plan_id, status, renews_at, effective_date)
          VALUES ($1, $2, 'active', NOW() + interval '30 days', NOW())
          ON CONFLICT (society_id) 
          DO UPDATE SET status = 'active', plan_id = $2, renews_at = NOW() + interval '30 days', updated_at = NOW()
        `,
        [societyId, plan.id]
      );
    }
  }

  static async rejectSociety(societyId: string, actorId: string, reason: string) {
    const app = await queryOne<any>(
      `SELECT id FROM society_applications WHERE society_id = $1 AND status = 'pending'`,
      [societyId],
      null
    );
    if (app) {
      await this.reviewApplication(app.id, "reject", actorId, reason);
    }
  }

  static async requestSocietyInformation(societyId: string, actorId: string, reason: string, requestedFields: string[]) {
    await queryRows(
      `
        INSERT INTO society_status_history (society_id, from_status, to_status, actor_id, reason)
        VALUES ($1, 'pending', 'pending_info', $2, $3)
      `,
      [societyId, actorId, `${reason} (Requested: ${requestedFields.join(", ")})`]
    );
  }

  static async assignTicket(ticketId: string, assigneeId: string, reason: string, actorId: string) {
    const rows = await queryRows(
      `
        UPDATE support_tickets
        SET assignee_id = $2,
            status = 'in_progress',
            updated_at = NOW(),
            version = version + 1
        WHERE id = $1
        RETURNING *
      `,
      [ticketId, assigneeId]
    );
    await queryRows(
      `
        INSERT INTO support_ticket_comments (ticket_id, author_id, body, internal)
        VALUES ($1, $2, $3, true)
      `,
      [ticketId, actorId, `Ticket assigned to ${assigneeId}. Reason: ${reason}`]
    );
    return rows[0] ?? null;
  }

  static async addInternalNote(ticketId: string, note: string, actorId: string) {
    await queryRows(
      `
        INSERT INTO support_ticket_comments (ticket_id, author_id, body, internal)
        VALUES ($1, $2, $3, true)
      `,
      [ticketId, actorId, note]
    );
  }

  static async resolveTicket(ticketId: string, resolution: string, actorId: string) {
    const rows = await queryRows(
      `
        UPDATE support_tickets
        SET status = 'resolved',
            updated_at = NOW(),
            version = version + 1
        WHERE id = $1
        RETURNING *
      `,
      [ticketId]
    );
    await queryRows(
      `
        INSERT INTO support_ticket_comments (ticket_id, author_id, body, internal)
        VALUES ($1, $2, $3, true)
      `,
      [ticketId, actorId, `Resolved. Resolution: ${resolution}`]
    );
    return rows[0] ?? null;
  }

  static async getFeatures() {
    return queryRows(`SELECT id, key, name, default_enabled, created_at FROM platform_features ORDER BY name ASC`);
  }

  static async getAnnouncements() {
    await db.query(`
      CREATE TABLE IF NOT EXISTS platform_announcements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    return queryRows(`SELECT id, title, body, created_at FROM platform_announcements ORDER BY created_at DESC`);
  }

  static async createAnnouncement(title: string, body: string, actorId: string) {
    await db.query(`
      CREATE TABLE IF NOT EXISTS platform_announcements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    const rows = await queryRows(
      `
        INSERT INTO platform_announcements (title, body)
        VALUES ($1, $2)
        RETURNING *
      `,
      [title, body]
    );
    return rows[0];
  }

  static async requestReport(payload: any, actorId: string) {
    const rows = await queryRows(
      `
        INSERT INTO report_jobs (society_id, kind, status, params, requested_by)
        VALUES ($1, $2, 'queued', $3, $4)
        RETURNING *
      `,
      [payload.societyId || "platform", payload.kind || "custom", JSON.stringify(payload.params || {}), actorId]
    );
    return rows[0];
  }
}
