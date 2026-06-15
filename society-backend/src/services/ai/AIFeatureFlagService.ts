import { redis } from "../../shared/Redis";
import { logger } from "../../shared/Logger";

export class AIFeatureFlagService {
  private static instance: AIFeatureFlagService;
  private redis = redis;

  private constructor() {}

  public static getInstance(): AIFeatureFlagService {
    if (!AIFeatureFlagService.instance) {
      AIFeatureFlagService.instance = new AIFeatureFlagService();
    }
    return AIFeatureFlagService.instance;
  }

  /**
   * Fast Redis-based feature toggles.
   * Default to 'true' if not set.
   */
  public async isEnabled(flagName: string): Promise<boolean> {
    const key = `feature:flag:${flagName}`;
    const value = await this.redis.get(key);
    return value !== "false";
  }

  /**
   * Toggle a specific feature for the AI system.
   */
  public async setFlag(flagName: string, value: boolean) {
    const key = `feature:flag:${flagName}`;
    await this.redis.set(key, value.toString());
    logger.info({ flagName, value }, "AI Feature Flag Updated");
  }
}
