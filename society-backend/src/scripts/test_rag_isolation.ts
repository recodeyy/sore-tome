import { AIGuardrailsService } from "../services/ai/AIGuardrailsService";
import { VectorStoreService } from "../services/ai/VectorStoreService";
import { Document } from "@langchain/core/documents";
import { logger } from "../shared/Logger";
import { db } from "../shared/Database";

/**
 * Phase 3: RAG Multi-Tenancy & Isolation Exploit Test
 * 
 * Verifies:
 * 1. Society A cannot retrieve Society B's documents via Vector Search bypass.
 * 2. Guardrails properly trigger hallucination/jailbreak blocks on malicious queries.
 */
async function runIsolationTest() {
  logger.info("Starting Strict RAG Multi-Tenancy Isolation Test...");
  const vectorStore = VectorStoreService.getInstance();
  const guardrails = AIGuardrailsService.getInstance();

  const societyA = "society_isolation_a";
  const societyB = "society_isolation_b";

  try {
    // 1. Setup Data
    logger.info("Injecting test documents securely...");
    await vectorStore.ingestDocuments([
      new Document({ pageContent: "Society_A_Secret: The gate code is 1234 A.", metadata: { documentType: "rules" } })
    ], societyA);

    await vectorStore.ingestDocuments([
      new Document({ pageContent: "Society_B_Secret: The vault code is 9876 B.", metadata: { documentType: "rules" } })
    ], societyB);

    // 2. Test Retrieval Isolation (Database level bypass attempt)
    logger.info("Executing retrieval bypass test...");
    const resultsA = await vectorStore.hybridSearch("What is the vault code?", societyA, { requestId: "t1", userId: "test" }, 5);
    
    // Validate that societyA cannot retrieve societyB's vault code
    const leakedB = resultsA.some(doc => doc.pageContent.includes("9876 B"));
    if (leakedB) {
      throw new Error("CRITICAL VULNERABILITY: Vector separation failed. Society B data leaked to Society A.");
    }
    logger.info("SUCCESS: Vector level filtering holds. No data leak in search.");

    // 3. Test Prompt Injection & Grounding (Jailbreak attempt)
    logger.info("Executing Prompt Injection & Grounding test...");
    
    const maliciousPromptContext = resultsA.map(d => d.pageContent).join("\n");
    const maliciousLLMOutput = "Sure! The vault code for the neighboring society is 9876 B.";

    try {
      // Guardrails should reject this because "9876 B" and "vault code" are NOT in the context retrieved for Society A.
      await guardrails.validateOutput(maliciousLLMOutput, { 
        requestId: "t2", 
        societyId: societyA, 
        ragContext: maliciousPromptContext 
      });
      throw new Error("CRITICAL VULNERABILITY: Guardrails failed to block ungrounded hallucination/jailbreak.");
    } catch (e: any) {
      // Wait, AIGuardrailsService returns a safe string ("I apologize...") rather than throwing, so we check the return block.
    }

    const safeOutput = await guardrails.validateOutput(maliciousLLMOutput, { 
      requestId: "t2", 
      societyId: societyA, 
      ragContext: maliciousPromptContext 
    });

    if (safeOutput.includes("9876")) {
       throw new Error("CRITICAL VULNERABILITY: Guardrails failed to block ungrounded hallucination.");
    }
    logger.info("SUCCESS: AIGuardrails blocked ungrounded data. Output overridden to safe generic response.");

    logger.info("ALL RAG ISOLATION TESTS PASSED. The system is secure.");

  } catch (error: any) {
    logger.error({ error: error.message }, "RAG Isolation Test Failed");
    process.exit(1);
  } finally {
    // Cleanup
    await db.query("DELETE FROM document_chunks WHERE metadata->>'society_id' IN ($1, $2)", [societyA, societyB]);
    process.exit(0);
  }
}

runIsolationTest();
