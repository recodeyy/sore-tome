import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { withTx } from "../finance/ledger";
import { toCsv } from "../../shared/csv";

const DEFAULT_RETENTION_DAYS = 30;

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

  /**
   * Capability 91: execute a queued (or running) report job end-to-end —
   * build a CSV artifact (formula-injection safe), persist it as the job's
   * output, set a retention window (expires_at) and mark the job completed.
   * Returns the completed job row including output_content.
   */
  async generateJob(
    societyId: string,
    jobId: string,
    opts: { retentionDays?: number } = {}
  ) {
    return withTx(async (client) => {
      const cur = await client.query(
        `SELECT * FROM report_jobs WHERE id = $1 AND society_id = $2 FOR UPDATE`, [jobId, societyId]
      );
      const job = cur.rows[0];
      if (!job) throw err("Job not found", "NOT_FOUND");
      if (job.status === "completed" || job.status === "failed") {
        throw err("Job already finalized", "INVALID_STATE");
      }

      let csv: string;
      try {
        csv = await buildArtifact(client, societyId, job);
      } catch (e: any) {
        await client.query(
          `UPDATE report_jobs SET status = 'failed', error = $3, updated_at = now()
            WHERE id = $1 AND society_id = $2`,
          [jobId, societyId, e.message]
        );
        throw err(`Report generation failed: ${e.message}`, "GENERATION_FAILED");
      }

      const days = opts.retentionDays && opts.retentionDays > 0 ? opts.retentionDays : DEFAULT_RETENTION_DAYS;
      const fileName = `report_${job.kind}_${jobId}.csv`;
      const fileUrl = `/api/v2/reports/jobs/${jobId}/artifact`;

      const { rows } = await client.query(
        `UPDATE report_jobs
            SET status = 'completed', output_content = $3, content_type = 'text/csv',
                file_name = $4, file_url = $5, error = NULL,
                expires_at = now() + ($6 || ' days')::interval, updated_at = now()
          WHERE id = $1 AND society_id = $2 RETURNING *`,
        [jobId, societyId, csv, fileName, fileUrl, String(days)]
      );
      logger.info({ societyId, jobId, bytes: csv.length }, "Report job generated");
      return rows[0];
    });
  },

  /** Fetch a completed job's artifact (CSV) for download, tenant-scoped. */
  async getArtifact(societyId: string, jobId: string) {
    const { rows } = await db.query(
      `SELECT id, status, output_content, content_type, file_name, expires_at
         FROM report_jobs WHERE id = $1 AND society_id = $2`,
      [jobId, societyId]
    );
    const job = rows[0];
    if (!job) throw err("Job not found", "NOT_FOUND");
    if (job.status !== "completed" || job.output_content == null) {
      throw err("Artifact not available", "INVALID_STATE");
    }
    if (job.expires_at && new Date(job.expires_at).getTime() < Date.now()) {
      throw err("Artifact has expired", "EXPIRED");
    }
    return {
      content: job.output_content as string,
      contentType: (job.content_type as string) || "text/csv",
      fileName: (job.file_name as string) || `report_${jobId}.csv`,
    };
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

/**
 * Build the CSV artifact body for a job. Each branch is tenant-scoped; failures
 * (e.g. missing source table) propagate so generateJob can mark the job failed.
 * Output goes through toCsv() which applies formula-injection escaping.
 */
async function buildArtifact(client: any, societyId: string, job: any): Promise<string> {
  switch (job.kind) {
    case "finance": {
      const { rows } = await client.query(
        `SELECT id, category, amount, vendor, status, created_at
           FROM expenses WHERE society_id = $1 ORDER BY created_at DESC LIMIT 5000`,
        [societyId]
      );
      return toCsv(["id", "category", "amount", "vendor", "status", "created_at"], rows);
    }
    case "complaints": {
      const { rows } = await client.query(
        `SELECT id, title, category, status, priority, created_at
           FROM complaints WHERE society_id = $1 ORDER BY created_at DESC LIMIT 5000`,
        [societyId]
      );
      return toCsv(["id", "title", "category", "status", "priority", "created_at"], rows);
    }
    case "staff": {
      const { rows } = await client.query(
        `SELECT id, name, role, status, created_at
           FROM staff WHERE society_id = $1 ORDER BY created_at DESC LIMIT 5000`,
        [societyId]
      );
      return toCsv(["id", "name", "role", "status", "created_at"], rows);
    }
    default: {
      // occupancy / custom: emit the supplied params as a single-row CSV so the
      // artifact is always well-formed and the escaping path is exercised.
      const params = job.params || {};
      const headers = Object.keys(params);
      if (headers.length === 0) return toCsv(["kind", "generated_at"], [{ kind: job.kind, generated_at: new Date().toISOString() }]);
      return toCsv(headers, [params]);
    }
  }
}
