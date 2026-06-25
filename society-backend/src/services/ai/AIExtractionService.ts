import { ProviderService } from "./ProviderService";
import { StructuredOutputParser } from "@langchain/core/output_parsers";
import { ChatPromptTemplate } from "@langchain/core/prompts";
import { z } from "zod";
import { logger } from "../../shared/Logger";
import dotenv from "dotenv";

dotenv.config();

export interface ExtractionResult {
  raw: string;
  parsed: any;
  confidence: number;
}

export class AIExtractionService {
  private static instance: AIExtractionService;
  private provider: ProviderService;

  private constructor() {
    this.provider = ProviderService.getInstance();
  }

  public static getInstance(): AIExtractionService {
    if (!AIExtractionService.instance) {
      AIExtractionService.instance = new AIExtractionService();
    }
    return AIExtractionService.instance;
  }

  /**
   * Hardened Extract-Verify-Repair loop with Zod and Confidence Scoring.
   * STRICTLY requires multi-tenancy context.
   */
  public async extractForm(
    documentText: string, 
    schema: z.ZodObject<any>, 
    context: { requestId: string; userId: string; societyId: string }
  ): Promise<ExtractionResult> {
    const startTime = Date.now();
    const strictSchema = schema.strict();
    const parser = StructuredOutputParser.fromZodSchema(strictSchema);
    
    const prompt = ChatPromptTemplate.fromTemplate(
      "EXTRACT FORM DATA FROM DOCUMENT.\n{format_instructions}\n\nDOCUMENT:\n{documentText}"
    );

    const model = await this.provider.getRouteModel("EXTRACTION", context);
    const input = await prompt.format({
      documentText,
      format_instructions: parser.getFormatInstructions(),
    });

    try {
      // 1. Initial Attempt: EXTRACT
      const response = await model.invoke(input);
      const rawOutput = response.content.toString();

      try {
        // 2. Initial Validation: VERIFY
        const parsed = await parser.parse(rawOutput);
        
        logger.info({ 
          ...context, 
          latency_ms: Date.now() - startTime,
          status: "success" 
        }, "AI Extraction: Successful on first attempt");

        return { raw: rawOutput, parsed, confidence: 0.95 };

      } catch (parseError: any) {
        // 3. Problem solving: REPAIR
        logger.warn({ ...context, error: parseError.message }, "AI Extraction: Initial parse failed, starting repair loop...");

        const repairPrompt = ChatPromptTemplate.fromTemplate(
          "FIX THE FOLLOWING INVALID JSON TO MATCH THE SCHEMA.\nSchema: {format_instructions}\nInvalid JSON: {invalid_json}\nError: {error}"
        );
        
        const repairInput = await repairPrompt.format({
          format_instructions: parser.getFormatInstructions(),
          invalid_json: rawOutput,
          error: parseError.message,
        });

        try {
          const repairResponse = await model.invoke(repairInput);
          const repairedOutput = repairResponse.content.toString();
          const parsed = await parser.parse(repairedOutput);

          logger.info({ 
            ...context, 
            latency_ms: Date.now() - startTime,
            status: "repaired" 
          }, "AI Extraction: Successful after repair");

          return { raw: rawOutput, parsed, confidence: 0.75 };
        } catch (finalError) {
          logger.error({ ...context, error: (finalError as any).message }, "AI Extraction: Repair failed, returning partial data");
          // Throw a special error that the route can catch to return partialData
          const error: any = new Error("Strict validation failed after repair");
          error.raw = rawOutput;
          throw error;
        }
      }
    } catch (error: any) {
      logger.error({ ...context, error: error.message, status: "failed" }, "AI Extraction: Pipeline failed");
      throw error;
    }
  }

  /**
   * V3.9: Auto-maps extracted text to predefined society categories.
   */
  public autoMapCategory(input: string): string {
    const ALLOWED_CATEGORIES = [
      "Maintenance", "Utilities", "Security", "Repairs", "Landscaping",
      "Stationery", "Events", "Sinking Fund", "Member Dues", "Other"
    ];
    
    const text = input.toLowerCase();

    if (text.includes("electricity") || text.includes("water") || text.includes("power") || text.includes("utility")) 
      return "Utilities";

    if (text.includes("repair") || text.includes("fix") || text.includes("plumbing") || text.includes("electrician")) 
      return "Repairs";

    if (text.includes("security") || text.includes("guard") || text.includes("cctv") || text.includes("watchman")) 
      return "Security";

    if (text.includes("maintenance") || text.includes("service charge"))
      return "Maintenance";

    if (text.includes("society fund") || text.includes("sinking"))
      return "Sinking Fund";

    if (text.includes("member") || text.includes("subscription") || text.includes("dues"))
      return "Member Dues";

    // Strict validation
    const mapped = ALLOWED_CATEGORIES.find(c => c.toLowerCase() === text);
    if (mapped) return mapped;

    return "Other";
  }
}
