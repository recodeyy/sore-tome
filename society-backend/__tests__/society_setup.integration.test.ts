import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { SocietyService } from "../src/services/society/SocietyService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-soc-${Date.now()}`;
const SOC_B = `test-soc-b-${Date.now()}`;

afterAll(async () => {
  for (const sId of [SOC, SOC_B]) {
    await db.query(`DELETE FROM society_profiles WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM society_settings WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM society_logos WHERE society_id = $1`, [sId]);
    await db.query(`DELETE FROM members WHERE society_id = $1`, [sId]);
  }
  await dbManager.close();
});

describe("SocietyService (integration)", () => {
  it("upserts and merges the society profile", async () => {
    const created = await SocietyService.upsertProfile(SOC, { name: "Green Acres", currency: "INR" });
    expect(created.name).toBe("Green Acres");
    expect(created.version).toBe(0);

    const updated = await SocietyService.upsertProfile(SOC, {
      registrationNo: "REG-123",
      contacts: [{ label: "Office", phone: "9990001111" }],
    });
    expect(updated.name).toBe("Green Acres"); // preserved
    expect(updated.registration_no).toBe("REG-123");
    expect(updated.contacts.length).toBe(1);
    expect(updated.version).toBe(1);
  });

  it("upserts and shallow-merges settings sections", async () => {
    const a = await SocietyService.upsertSettings(SOC, { numbering: { invoicePrefix: "INV" }, featureFlags: { polls: true } });
    expect(a.numbering.invoicePrefix).toBe("INV");

    const b = await SocietyService.upsertSettings(SOC, { numbering: { receiptPrefix: "RCT" } });
    expect(b.numbering.invoicePrefix).toBe("INV"); // merged, not replaced
    expect(b.numbering.receiptPrefix).toBe("RCT");
    expect(b.feature_flags.polls).toBe(true);
    expect(b.version).toBe(1);
  });

  it("versions, replaces and deletes the logo", async () => {
    const v1 = await SocietyService.setLogo(SOC, "https://x/logo1.png");
    expect(v1.version).toBe(1);
    expect(v1.is_current).toBe(true);

    const v2 = await SocietyService.setLogo(SOC, "https://x/logo2.png");
    expect(v2.version).toBe(2);

    const current = await SocietyService.getLogo(SOC);
    expect(current.file_url).toBe("https://x/logo2.png");

    await SocietyService.deleteLogo(SOC);
    expect(await SocietyService.getLogo(SOC)).toBeNull();
    await expect(SocietyService.deleteLogo(SOC)).rejects.toMatchObject({ code: "NOT_FOUND" });
  });

  it("computes onboarding progress with blockers", async () => {
    const before = await SocietyService.setupProgress(SOC_B);
    expect(before.percent).toBe(0);
    expect(before.blockers).toContain("profile");
    expect(before.blockers).toContain("members");

    await SocietyService.upsertProfile(SOC_B, { name: "Blue Heights" });
    await SocietyService.upsertSettings(SOC_B, { numbering: { invoicePrefix: "INV" } });
    await SocietyService.setLogo(SOC_B, "https://x/logo.png");
    await db.query(
      `INSERT INTO members (society_id, name) VALUES ($1, $2)`, [SOC_B, "Resident One"]
    );

    const after = await SocietyService.setupProgress(SOC_B);
    expect(after.percent).toBeGreaterThan(before.percent);
    expect(after.blockers).not.toContain("profile");
    expect(after.blockers).not.toContain("members");
    expect(after.total).toBe(6);
  });

  it("isolates society setup data across tenants", async () => {
    await SocietyService.upsertProfile(SOC, { name: "Green Acres" });
    const profileB = await SocietyService.getProfile(SOC_B);
    expect(profileB?.name).not.toBe("Green Acres");
    expect(await SocietyService.getLogo(SOC)).toBeNull(); // deleted earlier; B's logo must not leak in
    const logoB = await SocietyService.getLogo(SOC_B);
    expect(logoB?.society_id).toBe(SOC_B);
  });
});
