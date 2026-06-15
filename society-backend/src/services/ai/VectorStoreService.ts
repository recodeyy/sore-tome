import { OpenAIEmbeddings } from "@langchain/openai";
import { db } from "../../shared/Database";
import { Document } from "@langchain/core/documents";
import { logger } from "../../shared/Logger";
import dotenv from "dotenv";

dotenv.config();

export class VectorStoreService {
  private static instance: VectorStoreService;
  private pool = db;
  private embeddings: OpenAIEmbeddings;
  private isPostgresAvailable: boolean = true;

  private constructor() {
    this.embeddings = new OpenAIEmbeddings({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "text-embedding-3-small",
    });

    // Infrastructure initialization moved to Knex migrations.
  }



  public static getInstance(): VectorStoreService {
    if (!VectorStoreService.instance) {
      VectorStoreService.instance = new VectorStoreService();
    }
    return VectorStoreService.instance;
  }

  /**
   * Hybrid Search: Combines pgvector (Semantic) and PostgreSQL FTS (Keyword).
   * Uses Reciprocal Rank Fusion (RRF) for result merging.
   * STRICTLY filtered by society_id for multi-tenancy.
   */
  public async hybridSearch(query: string, society_id: string, options: { requestId: string; userId: string }, limit: number = 5) {
    const startTime = Date.now();
    
    try {
      const queryEmbedding = await this.embeddings.embedQuery(query);
      const vectorString = `[${queryEmbedding.join(",")}]`;

      // Reciprocal Rank Fusion (RRF) SQL Query
      const sql = `
        WITH fulltext_search AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(fts_content, plainto_tsquery('english', $1)) DESC) as rank
            FROM document_chunks
            WHERE fts_content @@ plainto_tsquery('english', $1)
            AND COALESCE(society_id, metadata->>'society_id') = $3
            LIMIT 20
        ),
        vector_search AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY vector <=> $2) as rank
            FROM document_chunks
            WHERE COALESCE(society_id, metadata->>'society_id') = $3
            LIMIT 20
        )
        SELECT dc.id, dc.content, dc.metadata, SUM(1.0 / (60 + COALESCE(fts.rank, 1000) + COALESCE(vec.rank, 1000))) as rrf_score
        FROM document_chunks dc
        LEFT JOIN fulltext_search fts ON dc.id = fts.id
        LEFT JOIN vector_search vec ON dc.id = vec.id
        WHERE fts.id IS NOT NULL OR vec.id IS NOT NULL
        GROUP BY dc.id, dc.content, dc.metadata
        ORDER BY rrf_score DESC
        LIMIT $4;
      `;

      const result = await this.pool.query(sql, [query, vectorString, society_id, limit]);
      
      const duration = Date.now() - startTime;
      logger.info({ 
        ...options,
        society_id: society_id, 
        latency_ms: duration, 
        results_counts: result.rows.length,
        status: "success"
      }, "AI Hybrid Search Request Successful");

      return result.rows.map(row => new Document({
        pageContent: row.content,
        metadata: row.metadata
      }));
    } catch (error: any) {
      logger.error({ 
        ...options,
        society_id: society_id, 
        error: error.message, 
        status: "failed" 
      }, "AI Hybrid Search Request Failed");
      throw error;
    }
  }

  /**
   * Added for Phase 3: Strict Document Ingestion with Deduplication and Metadata Enforcement
   */
  public async ingestDocuments(documents: Document[], society_id: string): Promise<boolean> {
    const crypto = require('crypto');
    let addedCount = 0;

    for (const doc of documents) {
      // Strictly Enforce Metadata schema
      if (!doc.metadata.document_id) {
         doc.metadata.document_id = `doc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      }
      doc.metadata.society_id = society_id;

      const contentHash = crypto.createHash("sha256").update(doc.pageContent).digest("hex");
      doc.metadata.content_hash = contentHash;

      // Deduplication: Avoid burning embedding cost if hash already exists
      const duplicateQuery = `SELECT id FROM document_chunks WHERE metadata->>'content_hash' = $1 AND COALESCE(society_id, metadata->>'society_id') = $2 LIMIT 1`;
      const duplicateRes = await this.pool.query(duplicateQuery, [contentHash, society_id]);

      if (duplicateRes.rows.length === 0) {
        const [embedding] = await this.embeddings.embedDocuments([doc.pageContent]);
        const vectorString = `[${embedding.join(",")}]`;
        await this.pool.query(
          `INSERT INTO document_chunks (content, metadata, vector, society_id) VALUES ($1, $2, $3, $4)`,
          [doc.pageContent, JSON.stringify(doc.metadata), vectorString, society_id]
        );
        addedCount++;
      }
    }
    logger.info({ society_id, total: documents.length, added: addedCount }, "Ingested Document Chunks");
    return true;
  }

  /**
   * Phase 3: Vector Store Cleanup
   */
  public async deleteDocument(document_id: string, society_id: string): Promise<number> {
    const res = await this.pool.query(
      `DELETE FROM document_chunks WHERE metadata->>'document_id' = $1 AND COALESCE(society_id, metadata->>'society_id') = $2`,
      [document_id, society_id]
    );
    logger.info({ society_id, document_id, deletedChunks: res.rowCount }, "Deleted Document from Vector Store");
    return res.rowCount || 0;
  }

  /**
   * Legacy method maintained for compatibility but now routed to hybrid search.
   */
  public async search(query: string, society_id: string, options: { requestId: string; userId: string }, limit: number = 5) {
    return this.hybridSearch(query, society_id, options, limit);
  }
}
