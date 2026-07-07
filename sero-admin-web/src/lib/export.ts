"use client";
// Client-side export helpers that operate on LIVE data already fetched from the
// backend. No mock rows. Values (amounts, receipt numbers, IDs) are written
// verbatim — never localized or reformatted in a lossy way.
import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";

export type Column<T> = {
  header: string;
  accessor: (row: T) => string | number | null | undefined;
};

function csvCell(v: unknown): string {
  const s = v === null || v === undefined ? "" : String(v);
  if (/[",\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

export function exportCsv<T>(
  filename: string,
  columns: Column<T>[],
  rows: T[]
) {
  const header = columns.map((c) => csvCell(c.header)).join(",");
  const body = rows
    .map((r) => columns.map((c) => csvCell(c.accessor(r))).join(","))
    .join("\n");
  const csv = `${header}\n${body}`;
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  downloadBlob(blob, filename.endsWith(".csv") ? filename : `${filename}.csv`);
}

export function exportPdf<T>(
  filename: string,
  title: string,
  columns: Column<T>[],
  rows: T[],
  subtitle?: string
) {
  const doc = new jsPDF({ orientation: "landscape" });
  doc.setFontSize(16);
  doc.setTextColor(6, 95, 70);
  doc.text(title, 14, 16);
  if (subtitle) {
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(subtitle, 14, 23);
  }
  doc.setFontSize(8);
  doc.setTextColor(120);
  doc.text(
    `Generated ${new Date().toLocaleString("en-IN")} · SERO Control`,
    14,
    doc.internal.pageSize.getHeight() - 8
  );
  autoTable(doc, {
    startY: subtitle ? 28 : 22,
    head: [columns.map((c) => c.header)],
    body: rows.map((r) => columns.map((c) => c.accessor(r) ?? "")),
    styles: { fontSize: 8, cellPadding: 2 },
    headStyles: { fillColor: [5, 150, 105] },
    alternateRowStyles: { fillColor: [240, 253, 244] },
  });
  doc.save(filename.endsWith(".pdf") ? filename : `${filename}.pdf`);
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
