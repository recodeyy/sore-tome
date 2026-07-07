import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import {
  AIToolService,
  resolveLanguage,
  languageName,
  SUPPORTED_LANGUAGES,
} from "../src/services/ai/AIToolService";
import { dbManager } from "../src/shared/Database";

afterAll(async () => {
  await dbManager.close();
});

describe("AI Multilingual handling", () => {
  it("resolves every allow-listed language code", () => {
    for (const code of SUPPORTED_LANGUAGES) {
      expect(resolveLanguage(code)).toBe(code);
    }
  });

  it("normalizes locale variants (e.g. HI-IN, en_US)", () => {
    expect(resolveLanguage("HI-IN")).toBe("hi");
    expect(resolveLanguage("en_US")).toBe("en");
    expect(resolveLanguage(" Mr ")).toBe("mr");
  });

  it("falls back to en for unknown/empty codes", () => {
    expect(resolveLanguage("fr")).toBe("en");
    expect(resolveLanguage("")).toBe("en");
    expect(resolveLanguage(undefined)).toBe("en");
    expect(resolveLanguage(null)).toBe("en");
  });

  it("exposes a human-readable language name", () => {
    expect(languageName("hi")).toBe("Hindi");
    expect(languageName("en")).toBe("English");
  });
});

describe("AI expanded tool registry (cross-role)", () => {
  const svc = AIToolService.getInstance();

  it("guard can create a visitor pass, resident cannot", () => {
    expect(svc.isToolAllowed("guard", "create_visitor_pass")).toBe(true);
    expect(svc.isToolAllowed("resident_owner", "create_visitor_pass")).toBe(false);
  });

  it("residents can read notices and meeting schedule", () => {
    expect(svc.isToolAllowed("resident_owner", "get_notices")).toBe(true);
    expect(svc.isToolAllowed("resident_tenant", "get_meeting_schedule")).toBe(true);
  });

  it("new tools resolve via the permission map (sensible roles)", () => {
    expect(svc.isToolAllowed("staff", "get_attendance")).toBe(true);
    expect(svc.isToolAllowed("resident_owner", "get_attendance")).toBe(false);
    expect(svc.isToolAllowed("resident_tenant", "get_parking_status")).toBe(true);
    expect(svc.isToolAllowed("secretary", "approve_member")).toBe(true);
    expect(svc.isToolAllowed("treasurer", "approve_member")).toBe(false);
    expect(svc.isToolAllowed("facility_manager", "assign_complaint")).toBe(true);
    expect(svc.getToolsForRole("guard")).toContain("create_visitor_pass");
  });

  it("still denies an unknown tool", () => {
    expect(svc.isToolAllowed("admin", "delete_everything")).toBe(false);
  });
});
