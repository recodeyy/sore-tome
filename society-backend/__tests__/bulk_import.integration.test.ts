import "dotenv/config";
import { describe, it, expect, afterAll } from "@jest/globals";
import { BulkImportService, parseCsv } from "../src/services/structure/BulkImportService";
import { db, dbManager } from "../src/shared/Database";

const SOC = `test-import-${Date.now()}`;

afterAll(async () => {
  await db.query(`DELETE FROM units WHERE society_id = $1`, [SOC]);
  await db.query(`DELETE FROM members WHERE society_id = $1`, [SOC]);
  await dbManager.close();
});

describe("parseCsv", () => {
  it("parses headers, trims, and handles quoted commas", () => {
    const rows = parseCsv(`number,unit_type\nA-101,"2 BHK, corner"\nA-102,1BHK`);
    expect(rows.length).toBe(2);
    expect(rows[0].number).toBe("A-101");
    expect(rows[0].unit_type).toBe("2 BHK, corner");
  });
});

describe("BulkImportService.importUnits (integration)", () => {
  it("dry-run reports validation without committing", async () => {
    const csv = `number,area_sqft\nU-1,500\nU-1,600\n,700\nU-2,notnum`;
    const report = await BulkImportService.importUnits(SOC, csv, { dryRun: true });
    expect(report.total).toBe(4);
    expect(report.valid).toBe(1); // U-1 once; dupe U-1, blank, bad area rejected
    expect(report.invalid).toBe(3);
    expect(report.committed).toBe(0);
    const { rows } = await db.query(`SELECT COUNT(*) c FROM units WHERE society_id=$1`, [SOC]);
    expect(Number(rows[0].c)).toBe(0);
  });

  it("commits valid rows and then detects existing duplicates", async () => {
    const r1 = await BulkImportService.importUnits(SOC, `number\nU-10\nU-11`, {});
    expect(r1.committed).toBe(2);

    const r2 = await BulkImportService.importUnits(SOC, `number\nU-10\nU-12`, {});
    expect(r2.invalid).toBe(1); // U-10 already exists
    expect(r2.committed).toBe(1); // U-12 inserted
  });
});

describe("BulkImportService.importMembers (integration)", () => {
  it("validates name + email and dedupes phone within file", async () => {
    const csv = `name,phone,email\nAsha,900,a@x.com\n,901,b@x.com\nBen,900,bad-email\nCara,902,c@x.com`;
    const report = await BulkImportService.importMembers(SOC, csv, { dryRun: true });
    expect(report.total).toBe(4);
    // row2 missing name, row3 dupe phone 900 (also bad email but phone check first)
    expect(report.valid).toBe(2); // Asha + Cara
    expect(report.invalid).toBe(2);
  });

  it("commits valid members", async () => {
    const report = await BulkImportService.importMembers(SOC, `name,phone\nDina,950`, {});
    expect(report.committed).toBe(1);
  });
});
