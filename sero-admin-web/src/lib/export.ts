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

export type ReceiptData = {
  /** Invoice / receipt number, printed verbatim. */
  number: string;
  memberName: string;
  period?: string | null;
  status: string;
  /** Amounts in minor units (paise). */
  totalMinor: number;
  taxMinor?: number;
  dueDate?: string | null;
  societyName?: string;
  note?: string;
};

/**
 * Generate a single, formatted A4 receipt/invoice PDF for one bill and trigger
 * a download. Amounts and the receipt number are printed verbatim (never
 * localized), matching the "don't mistranslate IDs/amounts" rule.
 */
export function exportReceipt(data: ReceiptData) {
  const money = (minor: number) =>
    `INR ${(minor / 100).toLocaleString("en-IN", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  const paid = data.status?.toLowerCase() === "paid";
  const subtotalMinor = data.totalMinor - (data.taxMinor || 0);

  const doc = new jsPDF({ orientation: "portrait", unit: "mm", format: "a4" });
  const pageW = doc.internal.pageSize.getWidth();
  const M = 16;

  // Header band
  doc.setFillColor(5, 150, 105);
  doc.rect(0, 0, pageW, 30, "F");
  doc.setTextColor(255);
  doc.setFontSize(18);
  doc.setFont("helvetica", "bold");
  doc.text(data.societyName || "SERO Society", M, 15);
  doc.setFontSize(11);
  doc.setFont("helvetica", "normal");
  doc.text(paid ? "PAYMENT RECEIPT" : "INVOICE", M, 23);

  // Meta (right aligned)
  doc.setFontSize(10);
  doc.text(`No: ${data.number}`, pageW - M, 13, { align: "right" });
  doc.text(`Date: ${new Date().toLocaleDateString("en-IN")}`, pageW - M, 19, {
    align: "right",
  });

  // Status pill
  doc.setFillColor(paid ? 220 : 254, paid ? 252 : 243, paid ? 231 : 199);
  doc.setTextColor(paid ? 6 : 146, paid ? 95 : 64, paid ? 70 : 14);
  doc.roundedRect(pageW - M - 34, 24, 34, 6, 1, 1, "F");
  doc.setFontSize(8);
  doc.setFont("helvetica", "bold");
  doc.text(data.status.toUpperCase(), pageW - M - 17, 28, { align: "center" });

  // Bill-to block
  doc.setTextColor(30);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(9);
  doc.text("BILLED TO", M, 44);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(11);
  doc.text(data.memberName || "—", M, 51);
  if (data.period) {
    doc.setFontSize(9);
    doc.setTextColor(110);
    doc.text(`Billing period: ${data.period}`, M, 57);
  }
  if (data.dueDate) {
    doc.setFontSize(9);
    doc.setTextColor(110);
    doc.text(`Due date: ${data.dueDate}`, pageW - M, 51, { align: "right" });
  }

  // Amount table
  const rows: (string | number)[][] = [["Maintenance charges", money(subtotalMinor)]];
  if (data.taxMinor) rows.push(["GST / Tax", money(data.taxMinor)]);
  autoTable(doc, {
    startY: 66,
    head: [["Description", "Amount"]],
    body: rows,
    foot: [["Total", money(data.totalMinor)]],
    theme: "grid",
    styles: { fontSize: 10, cellPadding: 3 },
    headStyles: { fillColor: [5, 150, 105], halign: "left" },
    footStyles: { fillColor: [240, 253, 244], textColor: [6, 95, 70], fontStyle: "bold" },
    columnStyles: { 1: { halign: "right" } },
    margin: { left: M, right: M },
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const endY = (doc as any).lastAutoTable?.finalY || 90;
  doc.setFontSize(9);
  doc.setTextColor(paid ? 6 : 146, paid ? 120 : 64, paid ? 80 : 14);
  doc.setFont("helvetica", "bold");
  doc.text(
    paid ? "Payment received. Thank you!" : "Please pay by the due date to avoid late fees.",
    M,
    endY + 12
  );
  if (data.note) {
    doc.setFont("helvetica", "normal");
    doc.setTextColor(110);
    doc.text(data.note, M, endY + 19);
  }

  // Footer
  doc.setFontSize(7);
  doc.setTextColor(150);
  doc.text(
    `Generated ${new Date().toLocaleString("en-IN")} · SERO Control · Computer-generated document`,
    M,
    doc.internal.pageSize.getHeight() - 8
  );

  doc.save(`receipt-${data.number}.pdf`);
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
