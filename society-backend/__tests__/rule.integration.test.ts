import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { RuleService } from "../src/services/rules/RuleService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-rule-${Date.now()}`;
const SOC_B = `test-rule-b-${Date.now()}`;

afterAll(async () => {
  for (const s of [SOC, SOC_B]) {
    await db.query(`DELETE FROM rules WHERE society_id = $1`, [s]);
    await db.query(`DELETE FROM society_documents WHERE society_id = $1`, [s]);
  }
  await dbManager.close();
});

describe("RuleService (integration)", () => {
  it("snapshots a version and bumps current_version on update", async () => {
    const r = await RuleService.createRule(SOC, { title: "Parking", body: "Park in allotted slots only", category: "rule" }, "u-admin");
    expect(r.current_version).toBe(1);

    const updated = await RuleService.updateRule(SOC, r.id, { body: "Park in allotted slots; visitors use guest bay" }, "u-admin");
    expect(updated.current_version).toBe(2);

    const detail = await RuleService.getRule(SOC, r.id);
    expect(detail!.versions.length).toBe(1); // the pre-edit snapshot
    expect(detail!.versions[0].version).toBe(1);
  });

  it("activates a rule", async () => {
    const r = await RuleService.createRule(SOC, { title: "Pets", body: "Leash required in common areas" }, "u-admin");
    const active = await RuleService.activate(SOC, r.id);
    expect(active.status).toBe("active");
    await expect(RuleService.activate(SOC, r.id)).rejects.toMatchObject({ code: "INVALID_STATE" });
  });

  it("finds rules by full-text search over the body", async () => {
    await RuleService.createRule(SOC, { title: "Water", body: "Tanker booking via the committee office" }, "u-admin");
    const hits = await RuleService.searchRules(SOC, "tanker");
    expect(hits.some((x: any) => x.title === "Water")).toBe(true);
  });

  it("increments document version when a revision is attached", async () => {
    const d = await RuleService.createDocument(SOC, { title: "Bylaws 2026", docType: "bylaw" }, "u-admin");
    expect(d.current_version).toBe(1);
    const { document, version } = await RuleService.addDocumentVersion(SOC, d.id, { fileUrl: "s3://x/bylaws.pdf", fileName: "bylaws.pdf", mimeType: "application/pdf" });
    expect(document.current_version).toBe(2);
    expect(version.version).toBe(2);
  });

  it("does not leak rules across tenants", async () => {
    const r = await RuleService.createRule(SOC, { title: "A-only", body: "x" }, "u-a");
    expect(await RuleService.getRule(SOC_B, r.id)).toBeNull();
    const listB = await RuleService.listRules(SOC_B, {});
    expect(listB.find((x: any) => x.id === r.id)).toBeUndefined();
  });
});
