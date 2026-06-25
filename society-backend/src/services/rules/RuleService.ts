import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import type { PoolClient } from "pg";

/**
 * Rules & Society Documents (Phase 4, capability 58).
 *
 * Rules (bylaws/rules/NOCs/policies) carry edit history: every update snapshots
 * the prior content into rule_versions and bumps current_version. Documents track
 * file revisions in document_versions. Full-text search runs over rules (title+body)
 * with an ILIKE fallback. Everything is tenant-scoped by society_id.
 */

async function withTx<T>(fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

export const RuleService = {
  // ---- Rules ------------------------------------------------------------

  async createRule(
    societyId: string,
    input: { title: string; body: string; category?: string },
    createdBy?: string
  ) {
    const { rows } = await db.query(
      `INSERT INTO rules (society_id, title, category, body, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [societyId, input.title, input.category || "rule", input.body, createdBy || null]
    );
    logger.info({ societyId, ruleId: rows[0].id }, "Rule created (draft)");
    return rows[0];
  },

  /**
   * Update title/body/category. Snapshots the prior content into rule_versions
   * and bumps current_version, all in one transaction.
   */
  async updateRule(
    societyId: string,
    ruleId: string,
    input: { title?: string; body?: string; category?: string },
    editedBy?: string
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM rules WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [ruleId, societyId]
      );
      const rule = rows[0];
      if (!rule) throw Object.assign(new Error("Rule not found"), { code: "NOT_FOUND" });

      // Snapshot the current (pre-edit) content as a version row.
      await client.query(
        `INSERT INTO rule_versions (society_id, rule_id, version, title, body, edited_by)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [societyId, ruleId, rule.current_version, rule.title, rule.body, editedBy || null]
      );

      const upd = await client.query(
        `UPDATE rules
         SET title = $3, body = $4, category = $5, current_version = current_version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2
         RETURNING *`,
        [
          ruleId,
          societyId,
          input.title ?? rule.title,
          input.body ?? rule.body,
          input.category ?? rule.category,
        ]
      );
      logger.info({ societyId, ruleId, version: upd.rows[0].current_version }, "Rule updated + version snapshot");
      return upd.rows[0];
    });
  },

  /** draft/archived -> active */
  async activate(societyId: string, ruleId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM rules WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [ruleId, societyId]
      );
      const rule = rows[0];
      if (!rule) throw Object.assign(new Error("Rule not found"), { code: "NOT_FOUND" });
      if (rule.status === "active") {
        throw Object.assign(new Error("Rule already active"), { code: "INVALID_STATE" });
      }
      const upd = await client.query(
        `UPDATE rules SET status = 'active', updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [ruleId, societyId]
      );
      logger.info({ societyId, ruleId }, "Rule activated");
      return upd.rows[0];
    });
  },

  /** -> archived */
  async archive(societyId: string, ruleId: string) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM rules WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [ruleId, societyId]
      );
      const rule = rows[0];
      if (!rule) throw Object.assign(new Error("Rule not found"), { code: "NOT_FOUND" });
      if (rule.status === "archived") {
        throw Object.assign(new Error("Rule already archived"), { code: "INVALID_STATE" });
      }
      const upd = await client.query(
        `UPDATE rules SET status = 'archived', updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [ruleId, societyId]
      );
      logger.info({ societyId, ruleId }, "Rule archived");
      return upd.rows[0];
    });
  },

  async listRules(
    societyId: string,
    opts: { status?: string; category?: string; limit?: number } = {}
  ) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.status) {
      params.push(opts.status);
      where += ` AND status = $${params.length}`;
    }
    if (opts.category) {
      params.push(opts.category);
      where += ` AND category = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM rules WHERE ${where} ORDER BY updated_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  async getRule(societyId: string, ruleId: string) {
    const { rows } = await db.query(
      `SELECT * FROM rules WHERE id = $1 AND society_id = $2`,
      [ruleId, societyId]
    );
    const rule = rows[0];
    if (!rule) return null;
    const { rows: versions } = await db.query(
      `SELECT * FROM rule_versions WHERE rule_id = $1 AND society_id = $2 ORDER BY version DESC`,
      [ruleId, societyId]
    );
    return { rule, versions };
  },

  /**
   * Full-text search over rules (title + body), tenant-scoped.
   * Falls back to listing recent rules when q is empty.
   */
  async searchRules(societyId: string, q: string) {
    const term = (q || "").trim();
    if (!term) {
      return this.listRules(societyId, {});
    }
    const { rows } = await db.query(
      `SELECT * FROM rules
       WHERE society_id = $1
         AND to_tsvector('english', coalesce(title,'') || ' ' || coalesce(body,'')) @@ plainto_tsquery('english', $2)
       ORDER BY updated_at DESC
       LIMIT 200`,
      [societyId, term]
    );
    if (rows.length > 0) return rows;
    // ILIKE fallback for partial / non-lexeme matches.
    const like = `%${term}%`;
    const { rows: fallback } = await db.query(
      `SELECT * FROM rules
       WHERE society_id = $1 AND (title ILIKE $2 OR body ILIKE $2)
       ORDER BY updated_at DESC
       LIMIT 200`,
      [societyId, like]
    );
    return fallback;
  },

  // ---- Documents --------------------------------------------------------

  async createDocument(
    societyId: string,
    input: { title: string; docType?: string },
    createdBy?: string
  ) {
    const { rows } = await db.query(
      `INSERT INTO society_documents (society_id, title, doc_type, created_by)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [societyId, input.title, input.docType || "other", createdBy || null]
    );
    logger.info({ societyId, documentId: rows[0].id }, "Society document created");
    return rows[0];
  },

  /**
   * Attach a new file revision: bumps current_version and inserts the version row.
   */
  async addDocumentVersion(
    societyId: string,
    documentId: string,
    input: {
      fileUrl: string;
      fileName?: string;
      mimeType?: string;
      checksum?: string;
      uploadedBy?: string;
    }
  ) {
    return withTx(async (client) => {
      const { rows } = await client.query(
        `SELECT * FROM society_documents WHERE id = $1 AND society_id = $2 FOR UPDATE`,
        [documentId, societyId]
      );
      const doc = rows[0];
      if (!doc) throw Object.assign(new Error("Document not found"), { code: "NOT_FOUND" });

      const upd = await client.query(
        `UPDATE society_documents
         SET current_version = current_version + 1, updated_at = now()
         WHERE id = $1 AND society_id = $2 RETURNING *`,
        [documentId, societyId]
      );
      const nextVersion = upd.rows[0].current_version;

      const ins = await client.query(
        `INSERT INTO document_versions
           (society_id, document_id, version, file_url, file_name, mime_type, checksum, uploaded_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          societyId,
          documentId,
          nextVersion,
          input.fileUrl,
          input.fileName || null,
          input.mimeType || null,
          input.checksum || null,
          input.uploadedBy || null,
        ]
      );
      logger.info({ societyId, documentId, version: nextVersion }, "Document version added");
      return { document: upd.rows[0], version: ins.rows[0] };
    });
  },

  async listDocuments(
    societyId: string,
    opts: { docType?: string; limit?: number } = {}
  ) {
    const params: any[] = [societyId];
    let where = `society_id = $1`;
    if (opts.docType) {
      params.push(opts.docType);
      where += ` AND doc_type = $${params.length}`;
    }
    params.push(Math.min(opts.limit || 50, 200));
    const { rows } = await db.query(
      `SELECT * FROM society_documents WHERE ${where} ORDER BY updated_at DESC LIMIT $${params.length}`,
      params
    );
    return rows;
  },

  async getDocument(societyId: string, documentId: string) {
    const { rows } = await db.query(
      `SELECT * FROM society_documents WHERE id = $1 AND society_id = $2`,
      [documentId, societyId]
    );
    const document = rows[0];
    if (!document) return null;
    const { rows: versions } = await db.query(
      `SELECT * FROM document_versions WHERE document_id = $1 AND society_id = $2 ORDER BY version DESC`,
      [documentId, societyId]
    );
    return { document, versions };
  },
};
