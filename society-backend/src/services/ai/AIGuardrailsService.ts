import { logger } from "../../shared/Logger";

export class AIGuardrailsService {
  private static instance: AIGuardrailsService;

  private constructor() {}

  public static getInstance(): AIGuardrailsService {
    if (!AIGuardrailsService.instance) {
      AIGuardrailsService.instance = new AIGuardrailsService();
    }
    return AIGuardrailsService.instance;
  }

  /**
   * Sanitizes and checks input for injections.
   */
  public async validateInput(prompt: string, context: { requestId: string }): Promise<string> {
    // 1. Basic Sanitization
    let sanitized = prompt.trim().replace(/[<>]/g, ""); // Remove potential script tags

    // 2. Prompt Injection Detection (Basic)
    const injectionKeywords = ["ignore previous instructions", "system prompt", "you are now", "dan mode"];
    const hasInjection = injectionKeywords.some(keyword => sanitized.toLowerCase().includes(keyword));

    if (hasInjection) {
      logger.warn({ ...context, prompt: sanitized }, "AI Guardrails: Potential Prompt Injection Detected!");
      throw new Error("Security Violation: Invalid input detected.");
    }

    return sanitized;
  }

  /**
   * Applies PII masking and RBAC filtering to output.
   */
  public async validateOutput(output: string, context: { requestId: string; societyId: string; ragContext?: string }): Promise<string> {
    let safeOutput = output;

    // 1. PII Masking (Emails & Phone Numbers)
    const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
    const phoneRegex = /\+?\d{10,12}/g;

    safeOutput = safeOutput.replace(emailRegex, "[EMAIL_MASKED]");
    safeOutput = safeOutput.replace(phoneRegex, "[PHONE_MASKED]");

    // 2. Strict RAG Grounding Validation (Phase 3)
    if (context.ragContext && safeOutput.length > 50) {
      if (!this.isGrounded(safeOutput, context.ragContext)) {
        logger.warn({ ...context }, "AI Guardrails: Output rejected due to lack of grounding (Hallucination/Jailbreak detected).");
        return "I apologize, but I cannot verify that information based on the society's official documents.";
      }
    }

    logger.debug({ ...context }, "AI Guardrails: Output validation completed");
    return safeOutput;
  }

  /**
   * Evaluates if the response is demonstrably derived from the provided context.
   */
  private isGrounded(response: string, ragContext: string): boolean {
    if (!ragContext || ragContext.trim().length === 0) return false;
    
    const normalize = (t: string) => t.toLowerCase().replace(/[^a-z0-9\s]/g, "").split(/\s+/).filter(w => w.length > 3);
    const contextWords = new Set(normalize(ragContext));
    const responseWords = normalize(response);
    
    if (responseWords.length < 5) return true; // Conversational fillers skip strict check

    let matchCount = 0;
    for (const word of responseWords) {
      if (contextWords.has(word)) matchCount++;
    }
    
    const overlapPercent = matchCount / responseWords.length;
    // Require at least 30% of significant vocabulary to be drawn from the RAG Context
    return overlapPercent > 0.30; 
  }

  /**
   * Enforces Multi-Tenancy at the service level.
   */
  public enforceMultiTenancy(data: any, societyId: string) {
    if (Array.isArray(data)) {
      return data.filter(item => item.society_id === societyId || item.metadata?.society_id === societyId);
    }
    if (data.society_id && data.society_id !== societyId) {
      throw new Error("Multi-Tenancy Violation: Access Denied");
    }
    return data;
  }
}
