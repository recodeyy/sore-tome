import { Embeddings, EmbeddingsParams } from "@langchain/core/embeddings";

export interface CloudflareEmbeddingsParams extends EmbeddingsParams {
  accountId: string;
  apiToken: string;
  model?: string;
}

/**
 * Custom Cloudflare Workers AI Embeddings for Node.js (via REST API).
 * Bypasses the binding requirement of the standard library.
 */
export class CloudflareEmbeddings extends Embeddings {
  model = "@cf/baai/bge-small-en-v1.5";
  accountId: string;
  apiToken: string;

  constructor(fields: CloudflareEmbeddingsParams) {
    super(fields);
    this.accountId = fields.accountId;
    this.apiToken = fields.apiToken;
    this.model = fields.model ?? this.model;
  }

  async embedDocuments(texts: string[]): Promise<number[][]> {
    const results: number[][] = [];
    // Process sequentially to avoid Cloudflare rate limits on simultaneous requests
    for (const text of texts) {
      results.push(await this.embedQuery(text));
    }
    return results;
  }

  async embedQuery(text: string): Promise<number[]> {
    const url = `https://api.cloudflare.com/client/v4/accounts/${this.accountId}/ai/run/${this.model}`;
    
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ text: text.replace(/\n/g, " ") }),
      });

      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Cloudflare AI REST Error: ${response.status} - ${error}`);
      }

      const data = (await response.json()) as any;
      
      // Cloudflare bge models return { result: { data: [ [vector] ] } }
      if (data.result && data.result.data && data.result.data[0]) {
        return data.result.data[0];
      }
      
      throw new Error("Invalid response format from Cloudflare AI");
    } catch (err: any) {
      throw new Error(`Cloudflare Embeddings Failed: ${err.message}`);
    }
  }
}
