import { ChatGroq } from "@langchain/groq";
import { CloudflareWorkersAI } from "@langchain/cloudflare";
import { ChatCerebras } from "@langchain/cerebras";
import { Runnable, RunnableConfig } from "@langchain/core/runnables";
import { logger } from "../../shared/Logger";
import { redis } from "../../shared/Redis";
import { CircuitBreaker, CircuitState } from "../../shared/CircuitBreaker";
import dotenv from "dotenv";

dotenv.config();

export type TaskType = "CHITCHAT" | "RETRIEVAL" | "EXTRACTION";

interface ProviderMetadata {
  name: string;
  costPer1MInput: number;
  costPer1MOutput: number;
}

const PROVIDER_METADATA: Record<string, ProviderMetadata> = {
  "llama-3.1-8b-instant": { name: "Groq", costPer1MInput: 0.05, costPer1MOutput: 0.08 },
  "llama-3.3-70b-versatile": { name: "Groq", costPer1MInput: 0.59, costPer1MOutput: 0.79 },
  "llama-3.1-8b": { name: "Cerebras", costPer1MInput: 0.1, costPer1MOutput: 0.1 },
  "llama-3.3-70b": { name: "Cerebras", costPer1MInput: 0.6, costPer1MOutput: 0.6 },
  "@cf/meta/llama-3.1-8b-instruct": { name: "Cloudflare", costPer1MInput: 0.05, costPer1MOutput: 0.05 },
};

type ProviderId = "groq" | "cerebras" | "cloudflare";

export class ProviderService {
  private static instance: ProviderService;
  private redis = redis;
  
  // Enterprise Breakers per Provider
  private breakers: Record<ProviderId, CircuitBreaker> = {
    groq: new CircuitBreaker("Groq-LLM", { failureThreshold: 3, cooldownPeriodMs: 60000 }),
    cerebras: new CircuitBreaker("Cerebras-LLM", { failureThreshold: 3, cooldownPeriodMs: 60000 }),
    cloudflare: new CircuitBreaker("Cloudflare-AI", { failureThreshold: 5, cooldownPeriodMs: 30000 }),
  };

  private constructor() {}

  public static getInstance(): ProviderService {
    if (!ProviderService.instance) {
      ProviderService.instance = new ProviderService();
    }
    return ProviderService.instance;
  }

  /**
   * Smart Model Routing based on Task Type and Provider Health.
   */
  public async getRouteModel(
    taskType: TaskType, 
    context: { requestId: string; userId: string; societyId: string }
  ): Promise<Runnable> {
    const startTime = Date.now();

    // 1. Define Model Instances
    const models = {
      groq: taskType === "EXTRACTION" 
        ? new ChatGroq({ apiKey: process.env.GROQ_API_KEY, model: "llama-3.3-70b-versatile", temperature: 0 })
        : new ChatGroq({ apiKey: process.env.GROQ_API_KEY, model: "llama-3.1-8b-instant", temperature: 0.7 }),
      cerebras: taskType === "EXTRACTION"
        ? new ChatCerebras({ apiKey: process.env.CEREBRAS_API_KEY, model: "llama-3.3-70b", temperature: 0 })
        : new ChatCerebras({ apiKey: process.env.CEREBRAS_API_KEY, model: "llama-3.1-8b", temperature: 0.7 }),
      cloudflare: new CloudflareWorkersAI({
        model: "@cf/meta/llama-3.1-8b-instruct",
        cloudflareAccountId: process.env.CLOUDFLARE_ACCOUNT_ID,
        cloudflareApiToken: process.env.CLOUDFLARE_API_TOKEN,
      }),
    };

    // 2. Dynamic Fallback Chain based on Enterprise Circuit Breakers
    const providerIds: ProviderId[] = ["groq", "cerebras", "cloudflare"];
    const activeProviders: { id: ProviderId; model: any }[] = [];

    for (const id of providerIds) {
      const breaker = this.breakers[id];
      // Allow if CLOSED or HALF_OPEN (test request)
      if (breaker.getState() !== CircuitState.OPEN) {
        activeProviders.push({ id, model: (models as any)[id] });
      }
    }

    if (activeProviders.length === 0) {
      logger.fatal(context, "🚨 All AI Providers Tripped! Falling back to emergency Cloudflare (Unprotected)");
      activeProviders.push({ id: "cloudflare", model: models.cloudflare });
    }

    const primary = activeProviders[0];
    const fallbacks = activeProviders.slice(1).map(p => p.model);

    const resilientModel = primary.model.withFallbacks({ fallbacks });

    // 3. Wrapped Invoke for Logging, Cost Tracking & Circuit Breaker Execution
    const originalInvoke = resilientModel.invoke.bind(resilientModel);
    
    resilientModel.invoke = async (input: any, options?: RunnableConfig) => {
      // Execute through the breaker of the currently active primary
      const breaker = this.breakers[primary.id];

      return await breaker.execute(async () => {

        try {
          const result = await originalInvoke(input, options);
          const duration = Date.now() - startTime;
          
          let modelName = "unknown";
          let usage = { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 };

          if ((result as any).response_metadata) {
            const meta = (result as any).response_metadata;
            modelName = meta.model_name || meta.modelId || "unknown";
            usage = meta.tokenUsage || meta.usage || usage;
          }

          const metadata = PROVIDER_METADATA[modelName] || { name: "Unknown", costPer1MInput: 0, costPer1MOutput: 0 };
          const cost = (usage.prompt_tokens * metadata.costPer1MInput + usage.completion_tokens * metadata.costPer1MOutput) / 1000000;

          logger.info({
            ...context,
            provider: metadata.name,
            model: modelName,
            latency_ms: duration,
            tokens: usage.total_tokens,
            cost_usd: cost.toFixed(6),
            status: "success"
          }, "AI Gateway Request Successful");

          return result;
        } catch (error: any) {
          logger.error({
            ...context,
            error: error.message,
            status: "failed"
          }, "AI Gateway Request Failed");
          throw error;
        }
      });
    };

    return resilientModel;
  }

  /**
   * Specialized Vision Model for V3.9 Adaptive Routing.
   */
  public async getVisionModel(): Promise<ChatGroq> {
    return new ChatGroq({ 
      apiKey: process.env.GROQ_API_KEY, 
      model: "llama-3.2-11b-vision-preview", 
      temperature: 0 
    });
  }
}

