"use client";
import { useApi, num } from "@/lib/hooks";
import { PageHeader, Card, StatCard, StatusChip } from "@/components/ui/primitives";
import { LoadingState } from "@/components/ui/states";
import { formatMoneyMinor, formatDate } from "@/lib/format";
import { exportCsv } from "@/lib/export";
import { Download, ShieldCheck } from "lucide-react";

type Summary = { invoicedMinor: number; collectedMinor: number; outstandingMinor: number };
type Receipt = {
  id: string;
  number?: string;
  amount_minor?: string | number;
  created_at?: string;
  invoice_id?: string;
  method?: string;
};

export default function PaymentsPage() {
  const summaryQ = useApi<Summary>(["finance", "summary"], "/finance/reports/summary");
  const receiptsQ = useApi<{ receipts: Receipt[] }>(["finance", "receipts"], "/finance/receipts");

  const receipts = receiptsQ.data?.receipts || [];
  const collectionRate =
    summaryQ.data && num(summaryQ.data.invoicedMinor) > 0
      ? Math.round((num(summaryQ.data.collectedMinor) / num(summaryQ.data.invoicedMinor)) * 100)
      : 0;

  return (
    <div>
      <PageHeader
        title="Payments"
        subtitle="Collection summary, receipts & Razorpay reconciliation — live"
        actions={
          <button
            className="btn-outline"
            disabled={!receipts.length}
            onClick={() =>
              exportCsv(
                "payment-collection",
                [
                  { header: "Receipt", accessor: (r: Receipt) => r.number || r.id },
                  { header: "Invoice", accessor: (r: Receipt) => r.invoice_id || "" },
                  { header: "Amount (INR)", accessor: (r: Receipt) => (num(r.amount_minor) / 100).toFixed(2) },
                  { header: "Method", accessor: (r: Receipt) => r.method || "" },
                  { header: "Date", accessor: (r: Receipt) => (r.created_at ? formatDate(r.created_at) : "") },
                ],
                receipts
              )
            }
          >
            <Download className="h-4 w-4" /> Collection CSV
          </button>
        }
      />

      {summaryQ.isLoading ? (
        <LoadingState />
      ) : (
        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          <StatCard label="Invoiced" value={formatMoneyMinor(summaryQ.data?.invoicedMinor)} tone="blue" />
          <StatCard label="Collected" value={formatMoneyMinor(summaryQ.data?.collectedMinor)} tone="green" />
          <StatCard label="Outstanding" value={formatMoneyMinor(summaryQ.data?.outstandingMinor)} tone="red" />
          <StatCard label="Collection Rate" value={`${collectionRate}%`} tone="amber" />
        </div>
      )}

      <Card className="mt-4 flex items-start gap-3 border-brand-200 bg-brand-50/40 p-4">
        <ShieldCheck className="mt-0.5 h-5 w-5 text-brand-600" />
        <p className="text-sm text-slate-600">
          Online payments are collected via <b>Razorpay Test Mode</b> and confirmed only by verified
          webhook status. The website never marks a payment successful without backend confirmation.
          Offline/manual entries are recorded from Billing with an audit trail.
        </p>
      </Card>

      <Card className="mt-4 p-4">
        <h2 className="mb-3 font-semibold text-slate-800">Receipts</h2>
        {receipts.length === 0 ? (
          <p className="py-8 text-center text-sm text-slate-400">
            No receipts yet. Receipts are generated automatically when a payment is confirmed.
          </p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Receipt</th>
                  <th>Invoice</th>
                  <th className="text-right">Amount</th>
                  <th>Method</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                {receipts.map((r) => (
                  <tr key={r.id}>
                    <td className="font-medium">{r.number || r.id.slice(0, 8)}</td>
                    <td>{r.invoice_id ? r.invoice_id.slice(0, 8) : "—"}</td>
                    <td className="text-right font-medium">{formatMoneyMinor(num(r.amount_minor))}</td>
                    <td>
                      <StatusChip tone="slate">{r.method || "manual"}</StatusChip>
                    </td>
                    <td>{r.created_at ? formatDate(r.created_at) : "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
