import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";

/**
 * Reports module (Phase 6, capability 91): report templates, generation jobs,
 * and scheduled reports. Tenant-scoped by society_id.
 *
 * Job lifecycle: queued -> running -> completed | failed. Transitions are guarded
 * (INVALID_STATE). Missing records raise NOT_FOUND.
 */

function err(message: string, code: string) {
  return Object.assign(new Error(message), { code });
}

type Kind = "finance" | "complaints" | "staff" | "occupancy" | "custom";

export const ReportService = {
  // ---- Templates --------------------------------------------------------
  async createTemplate(
    societyId: string,
    input: { name: string; kind?: Kind; format?: "pdf" | "excel" | "csv"; config?: any }
  ) {
    try {
      const { rows } = await db.query(
        `INSERT INTO report_templates (society_id, name, kind, format, config)
         VALUES ($1,$2,$3,$4,$5) RETURNING *`,
        [societyId, input.name, input.kind || "custom", input.format || "pdf", JSON.stringify(input.config ?? {})]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23505") throw err("Template name already exists", "ALREADY_EXISTS");
      throw e;
    }
  },

  async listTemplates(societyId: string) {
    const { rows } = await db.query(
      `SELECT * FROM report_templates WHERE society_id = $1 ORDER BY created_at DESC`, [societyId]
    );
    return rows;
  },

  // ---- Jobs -------------------------------------------------------------
  async enqueueJob(
    societyId: string,
    input: { templateId?: string; kind?: Kind; params?: any; requestedBy?: string }
  ) {
    let kind: Kind = input.kind || "custom";
    if (input.templateId) {
      const tpl = await db.query(
        `SELECT * FROM report_templates WHERE id = $1 AND society_id = $2`, [input.templateId, societyId]
      );
      if (!tpl.rows[0]) throw err("Template not found", "NOT_FOUND");
      kind = input.kind || tpl.rows[0].kind;
    }
    const { rows } = await db.query(
      `INSERT INTO report_jobs (society_id, template_id, kind, status, params, requested_by)
       VALUES ($1,$2,$3,'queued',$4,$5) RETURNING *`,
      [societyId, input.templateId || null, kind, JSON.stringify(input.params ?? {}), input.requestedBy || null]
    );
    logger.info({ societyId, jobId: rows[0].id, kind }, "Report job enqueued");
    return rows[0];
  },

  async markRunning(societyId: string, jobId: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM report_jobs WHERE id = $1 AND society_id = $2 FOR UPDATE`, [jobId, societyId]
      );
      if (!cur.rows[0]) throw err("Job not found", "NOT_FOUND");
      if (cur.rows[0].status !== "queued") throw err("Job is not queued", "INVALID_STATE");
      const { rows } = await client.query(
        `UPDATE report_jobs SET status = 'running', updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [jobId, societyId]
      );
      return rows[0];
    });
  },

  async completeJob(societyId: string, jobId: string, fileUrl: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM report_jobs WHERE id = $1 AND society_id = $2 FOR UPDATE`, [jobId, societyId]
      );
      if (!cur.rows[0]) throw err("Job not found", "NOT_FOUND");
      if (cur.rows[0].status !== "running") throw err("Job is not running", "INVALID_STATE");
      const { rows } = await client.query(
        `UPDATE report_jobs SET status = 'completed', file_url = $3, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [jobId, societyId, fileUrl]
      );
      return rows[0];
    });
  },

  async failJob(societyId: string, jobId: string, error: string) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM report_jobs WHERE id = $1 AND society_id = $2 FOR UPDATE`, [jobId, societyId]
      );
      if (!cur.rows[0]) throw err("Job not found", "NOT_FOUND");
      if (cur.rows[0].status === "completed" || cur.rows[0].status === "failed") {
        throw err("Job already finalized", "INVALID_STATE");
      }
      const { rows } = await client.query(
        `UPDATE report_jobs SET status = 'failed', error = $3, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [jobId, societyId, error]
      );
      return rows[0];
    });
  },

  async listJobs(societyId: string, opts: { status?: string; limit?: number } = {}) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) { params.push(opts.status); where += ` AND status = $${params.length}`; }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM report_jobs WHERE ${where} ORDER BY created_at DESC LIMIT $${params.length}`, params
    );
    return rows;
  },

  async getJob(societyId: string, jobId: string) {
    const { rows } = await db.query(
      `SELECT * FROM report_jobs WHERE id = $1 AND society_id = $2`, [jobId, societyId]
    );
    if (!rows[0]) throw err("Job not found", "NOT_FOUND");
    return rows[0];
  },

  // ---- Schedules --------------------------------------------------------
  async createSchedule(societyId: string, templateId: string, cron: string, nextRunAt?: string) {
    try {
      const { rows } = await db.query(
        `INSERT INTO report_schedules (society_id, template_id, cron, next_run_at)
         VALUES ($1,$2,$3,$4) RETURNING *`,
        [societyId, templateId, cron, nextRunAt || null]
      );
      return rows[0];
    } catch (e: any) {
      if (e.code === "23503") throw err("Template not found", "NOT_FOUND");
      throw e;
    }
  },

  /** Active schedules whose next_run_at is at or before `now` (ISO string). */
  async dueSchedules(societyId: string, now: string) {
    const { rows } = await db.query(
      `SELECT * FROM report_schedules
        WHERE society_id = $1 AND is_active = true
          AND next_run_at IS NOT NULL AND next_run_at <= $2
        ORDER BY next_run_at ASC`,
      [societyId, now]
    );
    return rows;
  },
};
