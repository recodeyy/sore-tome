import { Router, Request, Response } from "express";
import { AIChatService } from "../services/ai/AIChatService";
import { AIQueueService } from "../services/ai/AIQueueService";
import { AIExtractionService } from "../services/ai/AIExtractionService";
import { AIToolService } from "../services/ai/AIToolService";
import { ParserService } from "../services/ai/ParserService";
import { logger } from "../shared/Logger";
import { z } from "zod";

// @ts-ignore
import { authMiddleware } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";
import { VectorStoreService } from "../services/ai/VectorStoreService";
import rateLimit from "express-rate-limit";

// Rate limiting for costly AI Ingestion
const uploadRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 documents per hour max
  message: { error: "Upload quota exceeded per hour." },
  keyGenerator: (req: any) => req.user?.society_id || req.ip,
  validate: { default: false },
});

const router = Router();

/**
 * POST /ai/chat
 * High-performance RAG chat with society context.
 */
router.post("/chat", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const { message, base64Image, stream = false, context: contextData } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).societyId;

    // 1. Validation
    if (!message || typeof message !== "string" || message.trim().length === 0) {
      if (!base64Image) {
        return res.status(400).json({ error: "message or image is required" });
      }
    }

    const MAX_SIZE = 2 * 1024 * 1024; // 2MB Limit
    if (base64Image && base64Image.length > MAX_SIZE) {
      return res.status(413).json({ error: "Image too large (max 2MB)" });
    }

    const aiService = AIChatService.getInstance();

    // SSE Streaming Mode
    if (stream === true || req.headers.accept === "text/event-stream") {
      return aiService.chatStreaming(userId, societyId, message || "", res);
    }

    // JSON Mode (Flutter/default)
    const { history = [] } = req.body;
    const userRole = (req as any).user?.role || "resident";
    
    const result = await aiService.chatNonStreaming(userId, societyId, message || "", base64Image, contextData, userRole, history);
    return res.status(200).json(result);

  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/chat failed");
    return res.status(500).json({ error: "AI processing failed" });
  }
});

/**
 * POST /ai/extract-receipt
 */
router.post("/extract-receipt", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const { base64Image } = req.body;
    const userId = (req as any).user?.uid || "anonymous";
    const societyId = (req as any).societyId;
    const requestId = `rec_${Date.now()}`;

    if (!base64Image) return res.status(400).json({ error: "receipt image is required" });

    const receiptSchema = z.object({
      vendor: z.string(),
      date: z.string(),
      amount: z.number(),
      category: z.string(),
      note: z.string().optional(),
    });

    const parser = ParserService.getInstance();
    const extractionService = AIExtractionService.getInstance();

    const { content } = await parser.parseBase64(base64Image, { requestId, userId, societyId });
    const result = await extractionService.extractForm(content, receiptSchema, { requestId, userId, societyId });

    if (result && result.parsed) {
      result.parsed.category = extractionService.autoMapCategory(result.parsed.category || "");
    }

    return res.status(200).json(result);
  } catch (error: any) {
    return res.status(500).json({ error: "Extraction failed" });
  }
});

/**
 * POST /ai/upload-document
 */
router.post("/upload-document", authMiddleware, tenantMiddleware, uploadRateLimiter, async (req: Request, res: Response) => {
  try {
    const { fileUrl, fileName, fileType, documentType = "general" } = req.body;
    const societyId = (req as any).societyId;
    const userId = (req as any).user?.uid;

    if (!fileUrl || !fileName) return res.status(400).json({ error: "fileUrl and fileName are required" });

    // SSRF & Security Validation
    if (!fileUrl.startsWith("https://") || fileUrl.includes("localhost")) {
       return res.status(403).json({ error: "Invalid file URL." });
    }
    
    const queueService = AIQueueService.getInstance();
    await queueService.addJob("DOC_INGESTION", { 
      filePath: fileUrl, 
      fileName,
      fileType,
      documentType,
      society_id: societyId,
      userId: userId
    });

    return res.status(202).json({ message: "Ingestion verified and started", status: "Processing" });
  } catch (error: any) {
    return res.status(500).json({ error: "Upload failed" });
  }
});

// AI V2.4: Direct Multipart Upload
const multer = require("multer");
const { getStorage } = require("../../config/firebase");
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

router.post("/upload-document-direct", authMiddleware, tenantMiddleware, uploadRateLimiter, upload.single("file"), async (req: Request, res: Response) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });
    
    const { documentType = "general" } = req.body;
    const societyId = (req as any).societyId;
    const userId = (req as any).user?.uid;
    const fileName = `${Date.now()}_${req.file.originalname}`;

    // 1. Upload to Firebase Storage
    const bucket = getStorage().bucket();
    const file = bucket.file(`documents/${societyId}/${fileName}`);
    
    await file.save(req.file.buffer, {
      metadata: { 
        contentType: req.file.mimetype,
        metadata: {
          uploadedBy: userId,
          society_id: societyId,
          documentType
        }
      },
      public: true,
    });

    const fileUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;

    // 2. Queue for AI Ingestion
    const queueService = AIQueueService.getInstance();
    await queueService.addJob("DOC_INGESTION", { 
      filePath: fileUrl, 
      fileName: req.file.originalname,
      fileType: req.file.mimetype,
      documentType,
      society_id: societyId,
      userId: userId
    });

    return res.status(202).json({ 
      message: "File uploaded and ingestion started", 
      fileUrl,
      status: "Processing" 
    });
  } catch (error: any) {
    logger.error({ error: error.message }, "/ai/upload-document-direct failed");
    return res.status(500).json({ error: "Direct upload failed" });
  }
});

/**
 * DELETE /ai/document
 */
router.delete("/document", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const { documentId } = req.body;
    const societyId = (req as any).societyId;
    const role = (req as any).user?.role;
    
    if (!["admin", "main_admin"].includes(role)) return res.status(403).json({ error: "Forbidden: Admins only" });

    const vectorStore = VectorStoreService.getInstance();
    const count = await vectorStore.deleteDocument(documentId, societyId);
    
    return res.status(200).json({ message: "Document chunks deleted", count });
  } catch (error: any) {
    return res.status(500).json({ error: "Delete failed" });
  }
});

/**
 * GET /ai/digest
 */
router.get("/digest", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).societyId;
    const toolService = AIToolService.getInstance();
    const digest = await toolService.getSocietyDigest(societyId);
    return res.status(200).json(digest);
  } catch (error: any) {
    return res.status(500).json({ error: "Digest failed" });
  }
});

/**
 * POST /ai/execute-tool
 */
router.post("/execute-tool", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const { actionId } = req.body;
    const userId = (req as any).user?.uid;
    const societyId = (req as any).societyId;
    const role = (req as any).user?.role || "resident";

    if (!actionId) return res.status(400).json({ error: "actionId is required" });

    const toolService = AIToolService.getInstance();
    const result = await toolService.executeAction(actionId, userId, societyId, role);

    return res.status(200).json({ message: "Action executed successfully", result });
  } catch (error: any) {
    return res.status(400).json({ error: error.message });
  }
});

/**
 * GET /ai/logs
 */
router.get("/logs", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const role = (req as any).user?.role;
    const societyId = (req as any).societyId;

    if (!["admin", "main_admin"].includes(role)) return res.status(403).json({ error: "Forbidden: Admins only" });

    const { limit = 50, offset = 0 } = req.query;
    const vectorStore = VectorStoreService.getInstance();
    const pool = (vectorStore as any).pool;

    const query = `
      SELECT action_id, tool_id, user_id, action, params, status, created_at, error_message
      FROM ai_audit_logs 
      WHERE society_id = $1
      ORDER BY created_at DESC
      LIMIT $2 OFFSET $3
    `;
    const result = await pool.query(query, [societyId, limit, offset]);

    return res.status(200).json({ logs: result.rows });
  } catch (error: any) {
    return res.status(500).json({ error: "Failed to fetch logs" });
  }
});

/**
 * GET /ai/rules
 */
router.get("/rules", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).societyId;
    const vectorStore = VectorStoreService.getInstance();
    const store = await vectorStore.getVectorStore();
    
    const result = await (store as any).pool.query(`
      SELECT DISTINCT ON (content) content, metadata->>'source' as source
      FROM document_chunks
      WHERE (metadata->>'society_id')::text = $1 AND metadata->>'documentType' = 'rules'
      ORDER BY content
    `, [societyId]);

    const rules = result.rows.map((row: any) => ({
      rule: row.content,
      source: row.source
    }));

    return res.status(200).json({ success: true, rules });
  } catch (error: any) {
    return res.status(500).json({ error: "Failed to fetch rules" });
  }
});

/**
 * GET /ai/stats
 */
router.get("/stats", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).societyId;
    const toolService = AIToolService.getInstance();
    const stats = await toolService.getSocietyStats(societyId);
    return res.status(200).json(stats);
  } catch (error: any) {
    return res.status(500).json({ error: "Failed to fetch stats" });
  }
});

/**
 * GET /ai/finance-analysis
 */
router.get("/finance-analysis", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const societyId = (req as any).societyId;
    const toolService = AIToolService.getInstance();
    const analysis = await toolService.analyzeExpenses(societyId);
    return res.status(200).json(analysis);
  } catch (error: any) {
    return res.status(500).json({ error: "Failed to perform financial analysis" });
  }
});

export default router;

