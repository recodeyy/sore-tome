import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import {
  AIToolService,
  TOOL_PERMISSIONS,
  CANONICAL_ROLES,
} from "../src/services/ai/AIToolService";
import { db, dbManager } from "../src/shared/Database";

afterAll(async () => {
  await dbManager.close();
});

describe("AI Tool Cross-Role Authorization (Integration)", () => {
  const svc = AIToolService.getInstance();

  it("denies a resident calling an admin-only write tool", () => {
    expect(svc.isToolAllowed("resident_owner", "create_notice")).toBe(false);
    expect(svc.isToolAllowed("resident_tenant", "log_expense")).toBe(false);
    expect(svc.getToolsForRole("resident_owner")).not.toContain("create_notice");
  });

  it("allows a treasurer to call a finance tool", () => {
    expect(svc.isToolAllowed("treasurer", "log_expense")).toBe(true);
    expect(svc.getToolsForRole("treasurer")).toContain("log_expense");
  });

  it("allows secretary/admin to post notices, treasurer cannot", () => {
    expect(svc.isToolAllowed("secretary", "create_notice")).toBe(true);
    expect(svc.isToolAllowed("admin", "create_notice")).toBe(true);
    expect(svc.isToolAllowed("treasurer", "create_notice")).toBe(false);
  });

  it("denies an unknown / unregistered tool for every role", () => {
    for (const role of CANONICAL_ROLES) {
      expect(svc.isToolAllowed(role, "drop_all_tables")).toBe(false);
    }
  });

  it("normalizes legacy 'resident' role to resident_owner", () => {
    expect(svc.isToolAllowed("resident", "create_complaint")).toBe(true);
    expect(svc.isToolAllowed("resident", "log_expense")).toBe(false);
  });

  it("residents and staff can create complaints", () => {
    expect(svc.isToolAllowed("resident_owner", "create_complaint")).toBe(true);
    expect(svc.isToolAllowed("resident_tenant", "create_complaint")).toBe(true);
    expect(svc.isToolAllowed("staff", "create_complaint")).toBe(true);
  });

  it("getToolsForRole only returns tools the role is allowed to call", () => {
    for (const role of CANONICAL_ROLES) {
      for (const tool of svc.getToolsForRole(role)) {
        expect(svc.isToolAllowed(role, tool)).toBe(true);
      }
    }
  });

  it("permission map is consistent: every mapped role is canonical and lists are non-empty", () => {
    for (const [tool, roles] of Object.entries(TOOL_PERMISSIONS)) {
      expect(roles.length).toBeGreaterThan(0);
      for (const role of roles) {
        expect(CANONICAL_ROLES).toContain(role);
      }
      // no duplicate roles per tool
      expect(new Set(roles).size).toBe(roles.length);
      // every mapped tool is allowed for at least one role
      const allowedSomewhere = CANONICAL_ROLES.some((r) => svc.isToolAllowed(r, tool));
      expect(allowedSomewhere).toBe(true);
    }
  });

  it("db handle is importable (mirrors existing ai test wiring)", () => {
    expect(db).toBeDefined();
  });
});
