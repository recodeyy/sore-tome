import { db } from "../../shared/Database";
import { redis } from "../../shared/Redis";
import { logger } from "../../shared/Logger";

export class AIPromptService {
  private static instance: AIPromptService;
  private pool = db;
  private redis = redis;

  private constructor() {}

  public static getInstance(): AIPromptService {
    if (!AIPromptService.instance) {
      AIPromptService.instance = new AIPromptService();
    }
    return AIPromptService.instance;
  }

  /**
   * Fetches the active version of a prompt, with Redis caching.
   */
  public async getPrompt(name: string): Promise<string | null> {
    const cacheKey = `prompt:active:${name}`;
    
    // 1. Redis Cache Hit
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    // 2. PostgreSQL fallback
    const sql = `
      SELECT content FROM ai_prompts 
      WHERE name = $1 AND is_active = true 
      LIMIT 1
    `;
    const result = await this.pool.query(sql, [name]);
    
    if (result.rows.length > 0) {
      const content = result.rows[0].content;
      await this.redis.set(cacheKey, content, "EX", 3600); // Cache for 1h
      return content;
    }

    return null;
  }

  /**
   * Creates a new version of a prompt.
   */
  public async createPrompt(name: string, content: string) {
    const sql = `
      INSERT INTO ai_prompts (name, content, version)
      VALUES ($1, $2, (SELECT COALESCE(MAX(version), 0) + 1 FROM ai_prompts WHERE name = $1))
      RETURNING version
    `;
    const result = await this.pool.query(sql, [name, content]);
    logger.info({ name, version: result.rows[0].version }, "New AI Prompt Version Created");
    return result.rows[0].version;
  }

  /**
   * Promotes a specific version to 'active'.
   */
  public async activateVersion(name: string, version: number) {
    await this.pool.query("BEGIN");
    try {
      await this.pool.query("UPDATE ai_prompts SET is_active = false WHERE name = $1", [name]);
      await this.pool.query("UPDATE ai_prompts SET is_active = true WHERE name = $1 AND version = $2", [name, version]);
      await this.pool.query("COMMIT");
      
      await this.redis.del(`prompt:active:${name}`); // Invalidate cache
      logger.info({ name, version }, "AI Prompt Version Activated");
    } catch (err) {
      await this.pool.query("ROLLBACK");
      throw err;
    }
  }
}
