import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { ReconciliationService } from "../src/services/finance/ReconciliationService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-recon-${Date.now()}`;
const SOC_B = `test-recon-b-${Date.now()}`;

async function insertPayment(society: string, amountMinor: number) {
  const { rows } = await db.query(
    `INSERT INTO payments (society_id, amount_minor, status) VALUES ($1,$2,'captured') RETURNING id`,
    [society, amountMinor]
  );
  return rows[0].id as string;
}

afterAll(async () => {
  for (const soc of [SOC, SOC_B]) {
    for (const t of ["bank_statement_lines", "bank_statement_imports", "bank_accounts", "payments"]) {
      await db.query(`DELETE FROM ${t} WHERE society_id = $1`, [soc]);
    }
  }
  await dbManager.close();
});

describe("ReconciliationService (integration)", () => {
  it("creates a bank account", async () => {
    const acct = await ReconciliationService.createAccount(SOC, { name: "HDFC Main", accountNoMasked: "XXXX1234" });
    expect(acct.name).toBe("HDFC Main");
    expect(acct.society_id).toBe(SOC);
  });

  it("imports a statement with lines", async () => {
    const imp = await ReconciliationService.importStatement(SOC, {
      filename: "stmt.csv",
      lines: [
        { amountMinor: 50000, description: "Maintenance" },
        { amountMinor: 99999, description: "No match" },
      ],
    });
    expect(imp.line_count).toBe(2);
  });

  it("auto-matches a captured payment of equal amount, leaves others unmatched", async () => {
    await insertPayment(SOC, 50000);
    const imp = await ReconciliationService.importStatement(SOC, {
      filename: "am.csv",
      lines: [
        { amountMinor: 50000, description: "Match me" },
        { amountMinor: 77777, description: "No payment" },
      ],
    });
    const result = await ReconciliationService.autoMatch(SOC, imp.id);
    expect(result.processed).toBe(2);
    expect(result.matched).toBe(1);
    expect(result.unmatched).toBe(1);
  });

  it("manually matches a line to a payment", async () => {
    const pay = await insertPayment(SOC, 12345);
    const imp = await ReconciliationService.importStatement(SOC, {
      filename: "mm.csv",
      lines: [{ amountMinor: 12345, description: "Manual" }],
    });
    const { rows } = await db.query(
      `SELECT id FROM bank_statement_lines WHERE import_id = $1 LIMIT 1`,
      [imp.id]
    );
    const line = await ReconciliationService.manualMatch(SOC, rows[0].id, pay);
    expect(line.match_status).toBe("matched");
    expect(line.matched_payment_id).toBe(pay);
  });

  it("summarises matched/unmatched counts for an import", async () => {
    await insertPayment(SOC, 60000);
    const imp = await ReconciliationService.importStatement(SOC, {
      filename: "sum.csv",
      lines: [
        { amountMinor: 60000, description: "Match" },
        { amountMinor: 11111, description: "Unmatch" },
      ],
    });
    await ReconciliationService.autoMatch(SOC, imp.id);
    const sum = await ReconciliationService.summary(SOC, imp.id);
    expect(sum.matched).toBe(1);
    expect(sum.unmatched).toBe(1);
    expect(sum.matchedAmountMinor).toBe(60000);
    expect(sum.unmatchedAmountMinor).toBe(11111);
  });

  it("does not match across tenants", async () => {
    await insertPayment(SOC_B, 88888);
    const imp = await ReconciliationService.importStatement(SOC, {
      filename: "x.csv",
      lines: [{ amountMinor: 88888, description: "Other tenant payment" }],
    });
    const result = await ReconciliationService.autoMatch(SOC, imp.id);
    expect(result.matched).toBe(0);
    expect(result.unmatched).toBe(1);
  });
});
