import { db } from "../../shared/Database";
import { withTx } from "../finance/ledger";

/**
 * CSV/XLSX bulk import (capability 15) for units and members.
 *
 * The caller parses the spreadsheet client-side OR passes raw CSV text; this
 * service parses simple CSV (no embedded newlines), validates every row, detects
 * duplicates (both within the file and against existing tenant data), and either
 * returns a dry-run report or commits all valid rows in a single transaction
 * (all-or-nothing, so a partial import never corrupts the tenant). Tenant-scoped
 * by society_id throughout.
 */

type Row = Record<string, string>;
type RowError = { row: number; field?: string; message: string };

/** Minimal RFC-ish CSV parser: comma-separated, optional double-quoted fields. */
export function parseCsv(text: string): Row[] {
  const lines = String(text || "")
    .split(/\r?\n/)
    .filter((l) => l.trim().length > 0);
  if (lines.length === 0) return [];
  const splitLine = (line: string): string[] => {
    const out: string[] = [];
    let cur = "";
    let inQ = false;
    for (let i = 0; i < line.length; i++) {
      const c = line[i];
      if (inQ) {
        if (c === '"' && line[i + 1] === '"') { cur += '"'; i++; }
        else if (c === '"') inQ = false;
        else cur += c;
      } else if (c === '"') inQ = true;
      else if (c === ",") { out.push(cur); cur = ""; }
      else cur += c;
    }
    out.push(cur);
    return out.map((s) => s.trim());
  };
  const header = splitLine(lines[0]).map((h) => h.toLowerCase());
  return lines.slice(1).map((line) => {
    const cells = splitLine(line);
    const row: Row = {};
    header.forEach((h, idx) => (row[h] = cells[idx] ?? ""));
    return row;
  });
}

async function existingUnitNumbers(societyId: string): Promise<Set<string>> {
  const { rows } = await db.query(`SELECT number FROM units WHERE society_id = $1`, [societyId]);
  return new Set(rows.map((r: any) => String(r.number)));
}

export const BulkImportService = {
  /**
   * Validate + (optionally) commit a units import.
   * Required column: `number`. Optional: `unit_type`, `area_sqft`, `block_id`.
   */
  async importUnits(
    societyId: string,
    csvOrRows: string | Row[],
    opts: { dryRun?: boolean } = {}
  ) {
    const rows = typeof csvOrRows === "string" ? parseCsv(csvOrRows) : csvOrRows;
    const errors: RowError[] = [];
    const valid: Row[] = [];
    const seen = new Set<string>();
    const existing = await existingUnitNumbers(societyId);

    rows.forEach((r, i) => {
      const rowNo = i + 2; // header is line 1
      const number = (r.number || "").trim();
      if (!number) {
        errors.push({ row: rowNo, field: "number", message: "number is required" });
        return;
      }
      if (seen.has(number)) {
        errors.push({ row: rowNo, field: "number", message: `duplicate within file: ${number}` });
        return;
      }
      if (existing.has(number)) {
        errors.push({ row: rowNo, field: "number", message: `unit already exists: ${number}` });
        return;
      }
      if (r.area_sqft && isNaN(Number(r.area_sqft))) {
        errors.push({ row: rowNo, field: "area_sqft", message: "area_sqft must be numeric" });
        return;
      }
      seen.add(number);
      valid.push(r);
    });

    const report = {
      total: rows.length,
      valid: valid.length,
      invalid: errors.length,
      errors,
      committed: 0,
      dryRun: !!opts.dryRun,
    };

    if (opts.dryRun || valid.length === 0) return report;

    await withTx(async (client) => {
      for (const r of valid) {
        await client.query(
          `INSERT INTO units (society_id, number, unit_type, area_sqft, block_id, ownership_status)
           VALUES ($1,$2,$3,$4,$5,'vacant')`,
          [societyId, r.number.trim(), r.unit_type || null,
           r.area_sqft ? Number(r.area_sqft) : null, r.block_id || null]
        );
      }
    });
    report.committed = valid.length;
    return report;
  },

  /**
   * Validate + (optionally) commit a members import.
   * Required column: `name`. Optional: `phone`, `email`. Duplicate detection is
   * by phone within the file (empty phones are allowed and not deduped).
   */
  async importMembers(
    societyId: string,
    csvOrRows: string | Row[],
    opts: { dryRun?: boolean } = {}
  ) {
    const rows = typeof csvOrRows === "string" ? parseCsv(csvOrRows) : csvOrRows;
    const errors: RowError[] = [];
    const valid: Row[] = [];
    const seenPhones = new Set<string>();

    rows.forEach((r, i) => {
      const rowNo = i + 2;
      const name = (r.name || "").trim();
      if (!name) {
        errors.push({ row: rowNo, field: "name", message: "name is required" });
        return;
      }
      const phone = (r.phone || "").trim();
      if (phone && seenPhones.has(phone)) {
        errors.push({ row: rowNo, field: "phone", message: `duplicate phone within file: ${phone}` });
        return;
      }
      if (r.email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(r.email.trim())) {
        errors.push({ row: rowNo, field: "email", message: "invalid email" });
        return;
      }
      if (phone) seenPhones.add(phone);
      valid.push(r);
    });

    const report = {
      total: rows.length,
      valid: valid.length,
      invalid: errors.length,
      errors,
      committed: 0,
      dryRun: !!opts.dryRun,
    };

    if (opts.dryRun || valid.length === 0) return report;

    await withTx(async (client) => {
      for (const r of valid) {
        await client.query(
          `INSERT INTO members (society_id, name, phone, email, status)
           VALUES ($1,$2,$3,$4,'pending')`,
          [societyId, r.name.trim(), (r.phone || "").trim() || null, (r.email || "").trim() || null]
        );
      }
    });
    report.committed = valid.length;
    return report;
  },
};
