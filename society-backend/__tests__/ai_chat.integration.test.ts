import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { AIChatService } from "../src/services/ai/AIChatService";
import { db, dbManager } from "../src/shared/Database";

const USER_A = "user-ai-test-a";
const USER_B = "user-ai-test-b";
const SOC_A = "soc-ai-test-a";
const SOC_B = "soc-ai-test-b";

beforeAll(async () => {
  // Clear any existing test data
  await db.query(`DELETE FROM ai_messages`);
  await db.query(`DELETE FROM ai_conversations`);
});

afterAll(async () => {
  await db.query(`DELETE FROM ai_messages`);
  await db.query(`DELETE FROM ai_conversations`);
  await dbManager.close();
});

describe("AI Chatbot Conversation Persistence & History (Integration)", () => {
  let convId: string;

  it("creates a new conversation session", async () => {
    const aiService = AIChatService.getInstance();
    const conv = await aiService.createConversation(USER_A, SOC_A, "Test Conversation", "english");
    
    expect(conv).toBeDefined();
    expect(conv.id).toBeDefined();
    expect(conv.title).toBe("Test Conversation");
    expect(conv.user_id).toBe(USER_A);
    expect(conv.society_id).toBe(SOC_A);
    
    convId = conv.id;
  });

  it("lists active conversations for a user/society", async () => {
    const aiService = AIChatService.getInstance();
    const list = await aiService.listConversations(USER_A, SOC_A);
    
    expect(list.length).toBe(1);
    expect(list[0].id).toBe(convId);
  });

  it("does not leak another user's or society's conversations", async () => {
    const aiService = AIChatService.getInstance();
    
    // User B in Society A (no conversations)
    const listB = await aiService.listConversations(USER_B, SOC_A);
    expect(listB.length).toBe(0);

    // User A in Society B (no conversations)
    const listSocB = await aiService.listConversations(USER_A, SOC_B);
    expect(listSocB.length).toBe(0);
  });

  it("saves messages to an active conversation and retrieves them", async () => {
    const aiService = AIChatService.getInstance();
    
    const userMsg = await aiService.addMessage(convId, "user", "Hello Sero!");
    expect(userMsg).toBeDefined();
    expect(userMsg.conversation_id).toBe(convId);
    expect(userMsg.role).toBe("user");
    expect(userMsg.text_content).toBe("Hello Sero!");

    const aiMsg = await aiService.addMessage(convId, "assistant", "Hello! How can I help you today?", { sources: [] });
    expect(aiMsg).toBeDefined();
    expect(aiMsg.role).toBe("assistant");

    const messages = await aiService.getConversationMessages(convId, USER_A, SOC_A);
    expect(messages.length).toBe(2);
    expect(messages[0].role).toBe("user");
    expect(messages[1].role).toBe("assistant");
  });

  it("renames and archives a conversation session", async () => {
    const aiService = AIChatService.getInstance();
    
    const updated = await aiService.updateConversation(convId, USER_A, SOC_A, { title: "Renamed Title" });
    expect(updated).toBeDefined();
    expect(updated.title).toBe("Renamed Title");

    const archived = await aiService.updateConversation(convId, USER_A, SOC_A, { is_archived: true });
    expect(archived).toBeDefined();
    expect(archived.is_archived).toBe(true);

    const list = await aiService.listConversations(USER_A, SOC_A);
    expect(list.length).toBe(0); // Should be empty since it is archived
  });

  it("deletes a conversation session durably", async () => {
    const aiService = AIChatService.getInstance();
    
    const deleted = await aiService.deleteConversation(convId, USER_A, SOC_A);
    expect(deleted).toBeDefined();
    expect(deleted.id).toBe(convId);

    const fetchDeleted = await aiService.getConversation(convId, USER_A, SOC_A);
    expect(fetchDeleted).toBeNull();
  });
});
