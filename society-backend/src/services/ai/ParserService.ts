import * as fs from "fs";
import * as path from "path";
import { Document } from "@langchain/core/documents";
import { RecursiveCharacterTextSplitter } from "@langchain/textsplitters";
import { OpenAIEmbeddings } from "@langchain/openai";
import { logger } from "../../shared/Logger";
// @ts-ignore
import { createWorker } from "tesseract.js";
// @ts-ignore
import * as pdfjs from "pdfjs-dist/legacy/build/pdf.mjs";
// @ts-ignore
import { createCanvas } from "canvas";
import dotenv from "dotenv";

dotenv.config();

// Regex for manual heading detection (Chapter, Section, Rule, Part, or all-caps short lines)
const HEADING_REGEX = /^(?:[A-Z]{2,}|(?:Chapter|Section|Rule|Part)\s+\d+|[0-9]{1,2}\.\s+[A-Z][a-z]+)/;

import { ProviderService } from "./ProviderService";
import { HumanMessage } from "@langchain/core/messages";

export class ParserService {
  private static instance: ParserService;
  private provider: ProviderService;
  private embeddings: OpenAIEmbeddings;

  private constructor() {
    this.provider = ProviderService.getInstance();
    this.embeddings = new OpenAIEmbeddings({
      apiKey: process.env.OPENAI_API_KEY,
      modelName: "text-embedding-3-small",
    });
  }

  public static getInstance(): ParserService {
    if (!ParserService.instance) {
      ParserService.instance = new ParserService();
    }
    return ParserService.instance;
  }

  /**
   * Processes a Base64 encoded file (Image or PDF) for AI Chat context.
   * V3.9: Intelligent Routing between Tesseract (Standard) and Groq (VLM)
   */
  public async parseBase64(
    base64String: string, 
    options: { requestId: string; userId: string; societyId: string }
  ): Promise<{ content: string; metadata: any }> {
    const startTime = Date.now();
    try {
      // 1. Decode Base64
      const base64Data = base64String.split(';base64,').pop();
      if (!base64Data) throw new Error("Invalid Base64 format");
      const buffer = Buffer.from(base64Data, 'base64');

      // 2. Primary: Tesseract OCR (Fast & Cheap)
      const worker = await createWorker("eng");
      const { data: { text, confidence } } = await worker.recognize(buffer);
      await worker.terminate();

      // 3. V3.9 Routing Logic: If confidence is low or output is sparse, use Groq VLM
      const textLength = text.trim().length;
      const isMessy = confidence < 60 || textLength < 50;

      if (isMessy) {
        logger.info({ ...options, confidence, textLength }, "Vision: Routing to Groq VLM due to messy document");
        
        const visionModel = await this.provider.getVisionModel();
        const response = await visionModel.invoke([
          new HumanMessage({
            content: [
              { type: "text", text: "Describe this document in detail. If it's a receipt, extract all financial data accurately (Vendor, Amount, Date, Category, Items)." },
              { type: "image_url", image_url: { url: base64String } },
            ],
          }),
        ]);

        const visionText = response.content.toString();
        
        logger.info({
          ...options,
          latency_ms: Date.now() - startTime,
          vision_route: "GroqVLM",
          status: "success"
        }, "AI Vision (VLM) Parsed Successfully");

        return {
          content: visionText,
          metadata: {
            description: "Advanced AI Vision extraction (Groq VLM)",
            method: "GroqVLM",
            timestamp: new Date().toISOString()
          }
        };
      }

      logger.info({
        ...options,
        latency_ms: Date.now() - startTime,
        vision_route: "Tesseract",
        status: "success"
      }, "AI Vision (Tesseract) Parsed Successfully");

      return {
        content: text,
        metadata: {
          description: `Extracted text via Standard OCR (${textLength} chars)`,
          method: "Tesseract",
          timestamp: new Date().toISOString()
        }
      };
    } catch (error: any) {
      logger.error({ ...options, error: error.message }, "AI Attachment Parsing Failed");
      throw error;
    }
  }

  /**
   * Processes a document with Heading-Aware Semantic Chunking and OCR Fallback.
   * V3.10: Added onProgress callback for real-time status tracking.
   */
  public async processFile(
    filePath: string, 
    society_id: string, 
    options: { requestId: string; documentType?: string },
    onProgress?: (progress: number) => void
  ): Promise<Document[]> {
    const startTime = Date.now();
    const fileName = path.basename(filePath);

    try {
      // 1. Direct Text Extraction
      if (onProgress) onProgress(5); // Initialized
      const dataBuffer = fs.readFileSync(filePath);
      const loadingTask = pdfjs.getDocument({ data: new Uint8Array(dataBuffer) });
      const pdf = await loadingTask.promise;
      
      if (onProgress) onProgress(15); // Loaded

      let fullText = "";
      const pages = [];
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const content = await page.getTextContent();
        const text = content.items.map((item: any) => item.str).join(" ");
        fullText += text + "\n\n";
        pages.push({ pageNum: i, text });
        
        // Progress within extraction (cap at 30%)
        if (onProgress) onProgress(15 + (i / pdf.numPages * 15));
      }

      // 2. OCR Fallback Check (If text density is too low, process via OCR)
      const textDensity = fullText.trim().length / pdf.numPages;
      if (textDensity < 100 && process.env.TESSERACT_OCR_ENABLED === "true") {
        logger.info({ ...options, fileName, textDensity }, "Low text density detected. Triggering OCR Fallback...");
        if (onProgress) onProgress(35); // Starting OCR
        fullText = await this.processOCR(filePath, pdf, options, (p) => {
           if (onProgress) onProgress(35 + (p * 0.45)); // Map 0-100 to 35-80 range
        });
      }

      // 3. Strict Chunking (Phase 3 Constraints)
      if (onProgress && textDensity >= 100) onProgress(60); // Starting chunking
      const chunks = await this.safeChunking(fullText);
      if (onProgress) onProgress(90); // Chunks generated

      const result = chunks.map((content, idx) => new Document({
        pageContent: content,
        metadata: {
          society_id,
          source: fileName,
          documentType: options.documentType || "general",
          chunk_index: idx,
          processed_at: new Date().toISOString(),
        },
      }));

      if (onProgress) onProgress(100); 

      logger.info({
        ...options,
        fileName,
        chunks_count: result.length,
        latency_ms: Date.now() - startTime,
        status: "success"
      }, "Document Processing & Chunking Completed");

      return result;
    } catch (error: any) {
      logger.error({ ...options, fileName, error: error.message, status: "failed" }, "Document Processing Failed");
      throw error;
    }
  }

  /**
   * Tesseract.js OCR Execution with Page-by-Page chunking as per V3.2 spec.
   */
  private async processOCR(
    filePath: string, 
    pdf: any, 
    options: { requestId: string },
    onProgress?: (progress: number) => void
  ): Promise<string> {
    const worker = await createWorker("eng");
    let ocrFullText = "";

    try {
      // OCR Strategy: 1-2 page chunks (Spec: 10-15 sec per chunk)
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const viewport = page.getViewport({ scale: 2.0 });
        const canvas = createCanvas(viewport.width, viewport.height);
        const context = canvas.getContext("2d");
        
        await page.render({ canvasContext: context as any, viewport }).promise;
        const buffer = canvas.toBuffer("image/png");

        const { data: { text } } = await worker.recognize(buffer);
        ocrFullText += text + "\n\n";
        
        if (onProgress) onProgress(i / pdf.numPages * 100);
        logger.debug({ ...options, pageNum: i }, `OCR Completed for page ${i}`);
      }
      return ocrFullText;
    } finally {
      await worker.terminate();
    }
  }

  /**
   * Safe chunking implementation (Phase 3 Strict Rules)
   * Size: 500-1000 characters
   * Overlap: 10-20% (100 characters max) to maintain context boundaries
   */
  private async safeChunking(text: string): Promise<string[]> {
    const sentenceSplitter = new RecursiveCharacterTextSplitter({
      chunkSize: 800, // Safe spot between 500-1000 limit
      chunkOverlap: 150, // Approx 15-20% 
    });
    
    // Fallback cleanup to remove absolutely empty/junk blocks
    const rawChunks = await sentenceSplitter.splitText(text);
    return rawChunks.map(c => c.trim()).filter(c => c.length > 50);
  }
}

