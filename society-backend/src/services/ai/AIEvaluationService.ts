import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";

export interface EvaluationData {
  requestId: string;
  userId: string;
  societyId: string;
  hallucinationScore?: number; // 0.0 to 1.0
  accuracyScore?: number;
  relevanceScore?: number;
  metadata?: any;
}

export class AIEvaluationService {
  private static instance: AIEvaluationService;
  private pool = db;

  private constructor() {}

  public static getInstance(): AIEvaluationService {
    if (!AIEvaluationService.instance) {
      AIEvaluationService.instance = new AIEvaluationService();
    }
    return AIEvaluationService.instance;
  }

  /**
   * Logs an automated or LLM-based evaluation of an AI response.
   */
  public async logEvaluation(data: EvaluationData) {
    const sql = `
      INSERT INTO ai_evaluations (request_id, user_id, society_id, hallucination_score, accuracy_score, relevance_score, metadata)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `;
    try {
      await this.pool.query(sql, [
        data.requestId,
        data.userId,
        data.societyId,
        data.hallucinationScore,
        data.accuracyScore,
        data.relevanceScore,
        JSON.stringify(data.metadata || {})
      ]);
      logger.info({ requestId: data.requestId }, "AI Evaluation Logged Successfully");
    } catch (err: any) {
      logger.error({ requestId: data.requestId, error: err.message }, "AI Evaluation Logging Failed");
    }
  }

  /**
   * Logs explicit user feedback for an AI interaction.
   */
  public async logFeedback(requestId: string, feedback: string) {
    const sql = `
      UPDATE ai_evaluations 
      SET user_feedback = $1 
      WHERE request_id = $2
    `;
    try {
      await this.pool.query(sql, [feedback, requestId]);
      logger.info({ requestId }, "User Feedback Logged Successfully");
    } catch (err: any) {
      logger.error({ requestId, error: err.message }, "User Feedback Logging Failed");
    }
  }
}
