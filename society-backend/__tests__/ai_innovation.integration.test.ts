import "dotenv/config";
import { describe, it, expect, beforeAll, afterAll } from "@jest/globals";
import { AIInnovationService } from "../src/services/ai/AIInnovationService";
import { db, dbManager } from "../src/shared/Database";

const SOC_A = "soc-aiinnov-a";
const SOC_B = "soc-aiinnov-b";

async function clean() {
  for (const soc of [SOC_A, SOC_B]) {
    await db.query(`DELETE FROM maintenance_work_orders WHERE society_id = $1`, [soc]).catch(() => {});
    await db.query(`DELETE FROM assets WHERE society_id = $1`, [soc]).catch(() => {});
    await db.query(`DELETE FROM expenses WHERE society_id = $1`, [soc]).catch(() => {});
    await db.query(`DELETE FROM complaints WHERE society_id = $1`, [soc]).catch(() => {});
    await db.query(`DELETE FROM invoices WHERE society_id = $1`, [soc]).catch(() => {});
  }
}

async function seedComplaint(soc: string, ref: string, unit: string) {
  await db.query(
    `INSERT INTO complaints (society_id, ref, title, description, unit_id, status, sla_minutes, sla_config, created_at)
     VALUES ($1, $2, $3, $4, $5, 'open', 1440, '{}'::jsonb, NOW())`,
    [soc, ref, `T ${ref}`, "leaking water pipe issue", unit]
  );
}

beforeAll(async () => {
  await clean();

  // --- Society A: 3 complaints (same category_id NULL -> 'general' cluster) ---
  await seedComplaint(SOC_A, "C-A1", "A-101");
  await seedComplaint(SOC_A, "C-A2", "A-102");
  await seedComplaint(SOC_A, "C-A3", "A-103");

  // Society B: a single complaint (no cluster, isolation check)
  await seedComplaint(SOC_B, "C-B1", "B-101");

  // --- Expenses: financial anomaly (duplicate vendor+amount) for A ---
  for (let i = 0; i < 2; i++) {
    await db.query(
      `INSERT INTO expenses (society_id, vendor, category, description, amount_minor, status, created_at)
       VALUES ($1, 'AquaVendor', 'plumbing', 'pump repair', 500000, 'approved', NOW())`,
      [SOC_A]
    );
  }
  // Category spike outlier for A: several small baselines + one large spike.
  // avg over 4 rows ~= (10000*3 + 200000)/4 = 57500; spike 200000 > 2*avg.
  for (let i = 0; i < 3; i++) {
    await db.query(
      `INSERT INTO expenses (society_id, vendor, category, description, amount_minor, status, created_at)
       VALUES ($1, 'PowerCo', 'electricity', 'base', 10000, 'approved', NOW())`,
      [SOC_A]
    );
  }
  await db.query(
    `INSERT INTO expenses (society_id, vendor, category, description, amount_minor, status, created_at)
     VALUES ($1, 'PowerCo', 'electricity', 'spike', 200000, 'approved', NOW())`,
    [SOC_A]
  );

  // --- Asset for A: never maintained -> maintenance prediction item ---
  await db.query(
    `INSERT INTO assets (society_id, tag, name, type, status, commissioned_on)
     VALUES ($1, 'LIFT-1', 'Main Lift', 'lift', 'operational', NOW() - INTERVAL '8 years')`,
    [SOC_A]
  );

  // --- Invoices for A: published + overdue ---
  await db.query(
    `INSERT INTO invoices (society_id, number, status, total_minor, due_date, published_at, created_at)
     VALUES ($1, 'INV-A1', 'published', 200000, CURRENT_DATE - 10, NOW(), NOW())`,
    [SOC_A]
  );
});

afterAll(async () => {
  await clean();
  await dbManager.close();
});

describe("AIInnovationService (Integration)", () => {
  it("society pulse returns numeric, tenant-scoped metrics", async () => {
    const pulse = await AIInnovationService.generateSocietyPulse(SOC_A);
    expect(pulse.societyId).toBe(SOC_A);
    expect(typeof pulse.complaintHealth.openCount).toBe("number");
    expect(pulse.complaintHealth.openCount).toBeGreaterThanOrEqual(3);
    expect(typeof pulse.financialHealth.collectionRate).toBe("number");
    expect(typeof pulse.maintenanceHealth.assetsAtRisk).toBe("number");
    expect(pulse.maintenanceHealth.assetsAtRisk).toBeGreaterThanOrEqual(1);
  });

  it("detects a complaint cluster (>=3 grouped)", async () => {
    const clusters = await AIInnovationService.detectComplaintClusters(SOC_A);
    expect(clusters.length).toBeGreaterThanOrEqual(1);
    expect(clusters[0].complaintIds.length).toBeGreaterThanOrEqual(3);
    expect(clusters[0].affectedUnits.length).toBeGreaterThanOrEqual(3);
  });

  it("flags financial anomalies (duplicate + spike)", async () => {
    const anomalies = await AIInnovationService.detectFinancialAnomalies(SOC_A);
    expect(anomalies.length).toBeGreaterThanOrEqual(1);
    const types = anomalies.map((a) => a.type);
    expect(types).toContain("duplicate_invoice");
    expect(types).toContain("unusual_expense");
  });

  it("returns maintenance predictions", async () => {
    const preds = await AIInnovationService.predictMaintenanceNeeds(SOC_A);
    expect(preds.length).toBeGreaterThanOrEqual(1);
    expect(preds[0].failureRiskScore).toBeGreaterThanOrEqual(25);
    expect(["low", "medium", "high", "critical"]).toContain(preds[0].riskLevel);
  });

  it("isolates tenants — society A data absent from society B results", async () => {
    const clustersB = await AIInnovationService.detectComplaintClusters(SOC_B);
    expect(clustersB.length).toBe(0); // B has only 1 complaint

    const anomaliesB = await AIInnovationService.detectFinancialAnomalies(SOC_B);
    expect(anomaliesB.length).toBe(0);

    const predsB = await AIInnovationService.predictMaintenanceNeeds(SOC_B);
    expect(predsB.length).toBe(0);

    const pulseB = await AIInnovationService.generateSocietyPulse(SOC_B);
    expect(pulseB.complaintHealth.openCount).toBe(1);
    expect(pulseB.maintenanceHealth.assetsAtRisk).toBe(0);
  });

  it("degrades gracefully for an unknown society (zeroed, no throw)", async () => {
    const pulse = await AIInnovationService.generateSocietyPulse("soc-does-not-exist");
    expect(pulse.complaintHealth.openCount).toBe(0);
    expect(pulse.maintenanceHealth.assetsAtRisk).toBe(0);
    expect(pulse.autopilotActions).toEqual([]);
  });
});
