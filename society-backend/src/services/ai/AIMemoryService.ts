import { redis } from "../../shared/Redis";
import { logger } from "../../shared/Logger";
import { VectorStoreService } from "./VectorStoreService";
import { Document } from "@langchain/core/documents";

export class AIMemoryService {
  private static instance: AIMemoryService;
  private redis = redis;
  private readonly TTL = 3600; // 1 hour for short-term

  private constructor() {}

  public static getInstance(): AIMemoryService {
    if (!AIMemoryService.instance) {
      AIMemoryService.instance = new AIMemoryService();
    }
    return AIMemoryService.instance;
  }

  /**
   * Short-Term Memory: Get conversation history from Redis.
   */
  public async getShortTermHistory(userId: string, societyId: string, limit: number = 10): Promise<any[]> {
    const key = `chat_memory:${societyId}:${userId}`;
    const history = await this.redis.lrange(key, 0, limit - 1);
    return history.map(h => JSON.parse(h));
  }

  /**
   * Short-Term Memory: Add message to Redis history.
   */
  public async addShortTermMessage(userId: string, societyId: string, message: { role: string; content: string }) {
    const key = `chat_memory:${societyId}:${userId}`;
    await this.redis.lpush(key, JSON.stringify(message));
    await this.redis.ltrim(key, 0, 50); // Keep last 50
    await this.redis.expire(key, this.TTL);
  }

  /**
   * Long-Term Memory: Store summarized interaction in pgvector.
   */
  public async storeLongTermMemory(userId: string, societyId: string, summary: string, options: { requestId: string }) {
    const vectorStore = VectorStoreService.getInstance();
    const store = await vectorStore.getVectorStore();
    
    const doc = new Document({
      pageContent: summary,
      metadata: {
        userId,
        societyId,
        type: "long_term_memory",
        created_at: new Date().toISOString()
      },
    });

    await store.addDocuments([doc]);
    logger.info({ ...options, userId, societyId }, "Long-Term Memory Stored Successfully");
  }
}
