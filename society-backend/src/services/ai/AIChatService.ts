import { Response } from "express";
import { logger } from "../../shared/Logger";
import { ProviderService } from "./ProviderService";
import { AIMemoryService } from "./AIMemoryService";
import { VectorStoreService } from "./VectorStoreService";
import { SemanticCacheService } from "./SemanticCacheService";
import { AIGuardrailsService } from "./AIGuardrailsService";
import { ParserService } from "./ParserService";
import { AIRateLimitingService } from "./AIRateLimitingService";
import { ChatPromptTemplate, MessagesPlaceholder } from "@langchain/core/prompts";
import { HumanMessage, AIMessage, SystemMessage } from "@langchain/core/messages";
import { AIToolService, ToolAction } from "./AIToolService";

export class AIChatService {
  private static instance: AIChatService;
  private provider: ProviderService;
  private memory: AIMemoryService;
  private vectorStore: VectorStoreService;
  private cache: SemanticCacheService;
  private guardrails: AIGuardrailsService;
  private parser: ParserService;

  private constructor() {
    this.provider = ProviderService.getInstance();
    this.memory = AIMemoryService.getInstance();
    this.vectorStore = VectorStoreService.getInstance();
    this.cache = SemanticCacheService.getInstance();
    this.guardrails = AIGuardrailsService.getInstance();
    this.parser = ParserService.getInstance();
  }


  public static getInstance(): AIChatService {
    if (!AIChatService.instance) {
      AIChatService.instance = new AIChatService();
    }
    return AIChatService.instance;
  }

  /**
   * Safe JSON Parser for AI Responses
   */
  private safeParseAIResponse(text: string): any {
    try {
      // 1. Try standard JSON extraction
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) return null;

      let cleanText = jsonMatch[0];
      
      // 2. Fix common LLM JSON errors: Unescaped newlines in string values
      // This regex looks for newlines that are NOT preceded by a backslash inside double quotes
      // BUT for simplicity, we first try standard parse, then refined cleaning.
      try {
        return JSON.parse(cleanText);
      } catch {
        // Attempt to escape newlines inside what look like string values
        cleanText = cleanText.replace(/:\s*"([\s\S]*?)"/g, (match, p1) => {
          const escaped = p1.replace(/\n/g, "\\n").replace(/\r/g, "\\r");
          return `: "${escaped}"`;
        });
        return JSON.parse(cleanText);
      }
    } catch (e) {
      // 3. Last resort: Regex extraction of 'reply' if it exists
      const replyMatch = text.match(/"reply":\s*"([\s\S]*?)"/);
      if (replyMatch && replyMatch[1]) {
        return { type: "text", reply: replyMatch[1].replace(/\\n/g, "\n") };
      }
      return null;
    }
  }

  /**
   * JSON-based Non-Streaming Chat for mobile/standard clients.
   */
  public async chatNonStreaming(
    userId: string, 
    societyId: string, 
    userMessage: string,
    base64Image?: string,
    contextData?: any,
    userRole: string = "resident",
    history: any[] = []
  ): Promise<any> {
    const requestId = `chat_json_${Date.now()}`;
    const context = { requestId, userId, societyId, userRole };

    // ✅ BUG-07 FIX: Enforce per-user/per-society sliding-window rate limit
    const rateLimiter = AIRateLimitingService.getInstance();
    const allowed = await rateLimiter.checkLimit(userId, societyId, { requestId });
    if (!allowed) {
      logger.warn({ ...context }, "AI Chat rejected: rate limit exceeded");
      throw Object.assign(new Error("AI rate limit exceeded. Please wait before sending more messages."), { statusCode: 429 });
    }

    try {
      let fileContent = "";
      let ocrFailed = false;
      if (base64Image) {
        try {
          // Hardened OCR with 10s timeout protection
          const parsed: any = await Promise.race([
            this.parser.parseBase64(base64Image, { requestId, userId, societyId }),
            new Promise((_, reject) => 
              setTimeout(() => reject(new Error("OCR processing timeout (10s)")), 10000)
            )
          ]);

          const safeContent = parsed.content?.slice(0, 1500) || "";
          fileContent = `[ATTACHED IMAGE CONTENT]:\n${safeContent}\n[IMAGE DESCRIPTION]:\n${parsed.metadata?.description || "N/A"}`;
          
          logger.info({ ...context, imageSize: base64Image.length }, "Image parsed successfully");
        } catch (err) {
          ocrFailed = true;
          logger.warn({ ...context, error: (err as any).message }, "Image processing fallback: continuing without image context");
        }
      }

      const safeInput = await this.guardrails.validateInput(userMessage, context);

      // V3.12: Avoid cache hits if grounded contextData is provided (prevents hallucination persistence)
      const cached = contextData ? null : await this.cache.get(`${safeInput}_${fileContent.length}`, societyId, context);
      if (cached) {
        const parsed = this.safeParseAIResponse(cached);
        return parsed || { type: "text", reply: cached };
      }

      const { messages, sources, ragContext } = await this.prepareContext(userId, societyId, safeInput, context, fileContent, contextData, userRole, history);

      const model = await this.provider.getRouteModel("RETRIEVAL", context);
      const response = await model.invoke(messages);
      const aiText = response.content.toString();

      const parsed = this.safeParseAIResponse(aiText);
      const responseType = parsed ? parsed.type : "text";

      // V3.9: Propose Action if requested by AI
      if (parsed && parsed.type === "action" && parsed.tool) {
        try {
          const toolService = AIToolService.getInstance();
          const proposal = await toolService.proposeAction(userId, societyId, parsed.tool as ToolAction, parsed.params || {});
          parsed.actionId = proposal.actionId;
          parsed.expires_at = proposal.expires_at;
        } catch (err: any) {
          logger.warn({ ...context, error: err.message }, "Action proposal failed");
          parsed.type = "text";
          parsed.reply = parsed.reply || "I encountered an error while preparing that action.";
        }
      }

      const safeOutput = await this.postProcess(userId, societyId, safeInput, aiText, { ...context, ragContext });
      
      logger.info({ ...context, responseType }, "AI Chat Response Generated");

      const result = parsed || { type: "text", reply: safeOutput };
      
      // If result was parsed but has JSON-like garbage in reply, clean it
      if (result.type === "text" && result.reply.startsWith("{\"type\":")) {
         const reParsed = this.safeParseAIResponse(result.reply);
         if (reParsed && reParsed.reply) result.reply = reParsed.reply;
      }
      
      // Add sources if available
      if (sources && sources.length > 0) {
        (result as any).sources = sources;
      }

      if (ocrFailed) {
        (result as any).warning = "Image processing failed, showing best possible answer";
      }

      return result;
    } catch (error: any) {
      logger.error({ ...context, error: error.message }, "AIChatService.chatNonStreaming Failed");
      throw error;
    }
  }


  /**
   * SSE-based Streaming Chat for web clients.
   */
  public async chatStreaming(
    userId: string, 
    societyId: string, 
    userMessage: string, 
    res: Response,
    base64Image?: string
  ) {
    const requestId = `chat_sse_${Date.now()}`;
    const context = { requestId, userId, societyId };

    // ✅ BUG-19 FIX: Streaming does not support image/OCR — reject early with a clear message
    if (base64Image) {
      res.setHeader("Content-Type", "text/event-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");
      res.write(`data: ${JSON.stringify({ error: "Image input is not supported in streaming mode. Please use the standard (non-streaming) chat endpoint." })}\n\n`);
      res.write("data: [DONE]\n\n");
      return res.end();
    }

    // ✅ BUG-07 FIX: Enforce per-user/per-society rate limit for streaming too
    const rateLimiter = AIRateLimitingService.getInstance();
    const allowed = await rateLimiter.checkLimit(userId, societyId, { requestId });
    if (!allowed) {
      res.setHeader("Content-Type", "text/event-stream");
      res.write(`data: ${JSON.stringify({ error: "AI rate limit exceeded. Please wait before sending more messages.", status: "rate_limited" })}\n\n`);
      res.write("data: [DONE]\n\n");
      return res.end();
    }

    try {
      const safeInput = await this.guardrails.validateInput(userMessage, context);

      let fileContent = ""; // No image support in streaming
      const { messages, sources, ragContext } = await this.prepareContext(userId, societyId, safeInput, context, fileContent);

      res.setHeader("Content-Type", "text/event-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");

      const model = await this.provider.getRouteModel("RETRIEVAL", context);

      // ✅ BUG-08 FIX: Set the timeout BEFORE starting the stream, then clear it
      // as soon as the stream object is obtained (not inside the for-await loop)
      const timeout = setTimeout(() => {
        logger.warn(context, "AI Streaming Timeout: No stream obtained within 7s, sending fallback");
        res.write(`data: ${JSON.stringify({ content: "\n\nSystem busy, please try again.", status: "fallback" })}\n\n`);
        res.write("data: [DONE]\n\n");
        res.end();
      }, 7000);

      const stream = await model.stream(messages);
      clearTimeout(timeout); // Cancel timeout as soon as stream is ready

      let fullResponse = "";
      for await (const chunk of stream) {
        const content = chunk.content.toString();
        fullResponse += content;
        res.write(`data: ${JSON.stringify({ content })}\n\n`);
      }

      await this.postProcess(userId, societyId, safeInput, fullResponse, { ...context, ragContext });

      res.write("data: [DONE]\n\n");
      res.end();

    } catch (error: any) {
      logger.error({ ...context, error: error.message }, "AIChatService.chatStreaming Failed");
      res.write(`data: ${JSON.stringify({ error: error.message })}\n\n`);
      res.end();
    }
  }

  /**
   * Shared helper to prepare RAG and Memory context.
   */
  private async prepareContext(
    userId: string, 
    societyId: string, 
    safeInput: string, 
    context: any,
    fileContent: string = "",
    contextData?: any,
    userRole: string = "resident",
    manualHistory: any[] = []
  ) {
    const relatedDocs = await this.vectorStore.hybridSearch(safeInput, societyId, context, 3);
    const ragContext = relatedDocs.map(d => d.pageContent).join("\n---\n");

    const sources = relatedDocs.map(d => ({
      file: d.metadata.source || "unknown",
      page: d.metadata.page || 0,
      snippet: d.pageContent.slice(0, 120).trim() + "..."
    }));

    // Combine local DB history with optional manual history from UI (UI takes priority for current session)
    const dbHistory = await this.memory.getShortTermHistory(userId, societyId);
    const combinedHistory = manualHistory.length > 0 ? manualHistory : dbHistory;
    
    // AI V3.15: Persona-Based Intelligence
    const isAdmin = ["admin", "main_admin", "secretary", "treasurer"].includes(userRole);
    const persona = isAdmin 
      ? "Sero Society Intelligence (Admin Mode). You have high-clearance access to society data." 
      : "Sero Resident Concierge. You are a helpful assistant for society residents.";

    const systemPrompt = `
      You are ${persona}.
      Your specific role is: ${userRole}.
      
      Use the following context to answer if relevant.
      Context: ${ragContext}
      
      ${fileContent ? `[ATTACHED FILE CONTEXT]:\n${fileContent}\n` : ""}
      ${contextData ? `[CURRENT SCREEN CONTEXT]:\n${JSON.stringify(contextData)}\n` : ""}

      STRICT FORMATTING RULE:
      1. If you are drafting a notice, rule, or announcement:
         Return ONLY a JSON object: {"type": "draft", "title": "Water Shutdown", "content": "Please be advised..."}
      2. If you are proposing a SYSTEM ACTION (create_notice, log_expense, create_complaint):
         Return ONLY a JSON object: {"type": "action", "tool": "create_complaint", "params": {"title": "Basement Leak", "description": "Water leaking from ceiling", "priority": "high"}, "reply": "I've drafted a priority complaint for the basement leak. Shall I submit it?"}
      3. For standard conversation, assistance, or general queries:
         DO NOT use JSON. Return standard, helpful conversational text using markdown.
    `;

    const messages = [
      new SystemMessage(systemPrompt),
      ...combinedHistory.map(h => h.role === "human" || h.role === "user" ? new HumanMessage(h.content) : new AIMessage(h.content)),
      new HumanMessage(safeInput)
    ];

    return { messages, ragContext, sources };
  }


  /**
   * Shared helper for post-processing.
   */
  private async postProcess(userId: string, societyId: string, input: string, output: string, context: any) {
    // 1. Output Guardrails (Phase 3: includes ragContext for grounding)
    const safeOutput = await this.guardrails.validateOutput(output, context);

    // 2. Save to Memory
    await this.memory.addShortTermMessage(userId, societyId, { role: "human", content: input });
    await this.memory.addShortTermMessage(userId, societyId, { role: "ai", content: safeOutput });

    // 3. Cache Result (if safe)
    await this.cache.set(input, safeOutput, societyId, context);

    return safeOutput;
  }

  private sendSSEResponse(res: Response, text: string) {
    res.setHeader("Content-Type", "text/event-stream");
    res.write(`data: ${JSON.stringify({ content: text })}\n\n`);
    res.write("data: [DONE]\n\n");
    res.end();
  }
}

