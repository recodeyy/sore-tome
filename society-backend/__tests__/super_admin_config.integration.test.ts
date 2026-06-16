import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { SuperAdminService } from "../src/services/platform/SuperAdminService";
import { db, dbManager } from "../src/shared/Database";

const SOC_ID = "test-config-soc";

beforeAll(async () => {
  await db.query(`DELETE FROM feature_rollouts WHERE feature_key = $1`, ["test_config_feature"]);
  await db.query(`DELETE FROM white_label_profiles WHERE society_id = $1`, [SOC_ID]);
  await db.query(`DELETE FROM api_clients WHERE society_id = $1`, [SOC_ID]);
  await db.query(`DELETE FROM webhook_endpoints WHERE society_id = $1`, [SOC_ID]);
  await db.query(`DELETE FROM integration_connections WHERE society_id = $1`, [SOC_ID]);
});

afterAll(async () => {
  await db.query(`DELETE FROM feature_rollouts WHERE feature_key = $1`, ["test_config_feature"]);
  await db.query(`DELETE FROM white_label_profiles WHERE society_id = $1`, [SOC_ID]);
  await db.query(`DELETE FROM api_clients WHERE society_id = $1`, [SOC_ID]);
  await db.query(`DELETE FROM webhook_endpoints WHERE society_id = $1`, [SOC_ID]);
  await db.query(`DELETE FROM integration_connections WHERE society_id = $1`, [SOC_ID]);
  await dbManager.close();
});

describe("Super Admin Platform Configuration (Integration)", () => {
  it("cap 20: sets and evaluates a feature rollout", async () => {
    await SuperAdminService.setRollout({
      featureKey: "test_config_feature",
      cohort: { societies: [SOC_ID] },
      percentage: 0,
      status: "active",
    });

    const inCohort = await SuperAdminService.evaluateRollout("test_config_feature", SOC_ID);
    expect(inCohort.enabled).toBe(true);
    expect(inCohort.reason).toBe("cohort");

    const other = await SuperAdminService.evaluateRollout("test_config_feature", "some-other-soc");
    expect(other.enabled).toBe(false);

    // Inactive rollouts are never enabled.
    await SuperAdminService.setRollout({ featureKey: "test_config_feature", percentage: 100, status: "draft" });
    const drafted = await SuperAdminService.evaluateRollout("test_config_feature", "any-soc");
    expect(drafted.enabled).toBe(false);
    expect(drafted.reason).toBe("inactive");
  });

  it("cap 21: white-label upsert bumps version and publish flips status", async () => {
    const v1 = await SuperAdminService.upsertWhiteLabel({
      societyId: SOC_ID,
      brandName: "Acme Homes",
      colors: { primary: "#123456" },
      logoUrl: "https://cdn/logo.png",
    });
    expect(v1.version).toBe(1);
    expect(v1.status).toBe("draft");

    const v2 = await SuperAdminService.upsertWhiteLabel({ societyId: SOC_ID, brandName: "Acme Homes 2" });
    expect(v2.version).toBe(2);

    const published = await SuperAdminService.publishWhiteLabel(SOC_ID);
    expect(published.status).toBe("published");

    const fetched = await SuperAdminService.getWhiteLabel(SOC_ID);
    expect(fetched.brand_name).toBe("Acme Homes 2");
  });

  it("cap 22: api key returned once, only hash stored, revoke disables", async () => {
    const created = await SuperAdminService.createApiClient({
      societyId: SOC_ID,
      name: "Mobile App",
      scopes: ["read:notices"],
      quotaPerDay: 500,
    });
    expect(created.apiKey).toMatch(/^sk_/);
    expect(created.quota_per_day).toBe(500);

    // Plaintext key must NOT be persisted anywhere in the row.
    const stored = await db.query(`SELECT * FROM api_clients WHERE id = $1`, [created.id]);
    expect(stored.rows.length).toBe(1);
    expect(stored.rows[0].key_hash).not.toBe(created.apiKey);
    expect(JSON.stringify(stored.rows[0])).not.toContain(created.apiKey);

    const list = await SuperAdminService.listApiClients(SOC_ID);
    expect(list.length).toBe(1);

    const revoked = await SuperAdminService.revokeApiClient(created.id);
    expect(revoked.is_active).toBe(false);
  });

  it("cap 23: webhook stores secret hash not plaintext; integration upserts", async () => {
    const hook = await SuperAdminService.createWebhook({
      societyId: SOC_ID,
      url: "https://example.com/hook",
      events: ["invoice.paid"],
      secret: "my-plaintext-secret",
    });
    expect(hook.secret).toBe("my-plaintext-secret");

    const stored = await db.query(`SELECT * FROM webhook_endpoints WHERE id = $1`, [hook.id]);
    expect(stored.rows[0].secret_hash).not.toBe("my-plaintext-secret");
    expect(JSON.stringify(stored.rows[0])).not.toContain("my-plaintext-secret");

    const list = await SuperAdminService.listWebhooks(SOC_ID);
    expect(list.length).toBe(1);

    const integ = await SuperAdminService.setIntegration({
      societyId: SOC_ID,
      provider: "slack",
      config: { channel: "#alerts" },
      status: "connected",
    });
    expect(integ.provider).toBe("slack");
    expect(integ.config.channel).toBe("#alerts");

    const updated = await SuperAdminService.setIntegration({
      societyId: SOC_ID,
      provider: "slack",
      config: { channel: "#ops" },
      status: "connected",
    });
    expect(updated.id).toBe(integ.id);
    expect(updated.config.channel).toBe("#ops");
  });
});
