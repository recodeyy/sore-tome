"use client";
import { Download } from "lucide-react";
import { useApi, num } from "@/lib/hooks";
import { PageHeader, Card, StatCard, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState } from "@/components/ui/states";
import { formatMoneyMinor } from "@/lib/format";
import { exportCsv, exportPdf } from "@/lib/export";

type Summary = {
  invoicedMinor: number;
  collectedMinor: number;
  expensesMinor: number;
  outstandingMinor: number;
};
type DuesItem = {
  invoiceId: string;
  number: string;
  memberId: string;
  totalMinor: number;
  outstandingMinor: number;
  ageDays: number;
  bucket: string;
};
type Dues = { items: DuesItem[]; buckets: Record<string, number>; totalOutstandingMinor: number };

export default function ReportsPage() {
  const summaryQ = useApi<Summary>(["finance", "summary"], "/finance/reports/summary");
  const duesQ = useApi<Dues>(["finance", "dues"], "/finance/reports/dues");
  const tbQ = useApi<any>(["finance", "tb"], "/finance/reports/trial-balance");

  if (summaryQ.isLoading) return <LoadingState />;
  if (summaryQ.isError) return <ErrorState onRetry={() => summaryQ.refetch()} />;

  const s = summaryQ.data!;
  const dues = duesQ.data;
  const defaulters = (dues?.items || []).filter((i) => num(i.outstandingMinor) > 0);

  function exportDefaulters(kind: "csv" | "pdf") {
    const cols = [
      { header: "Invoice", accessor: (r: DuesItem) => r.number },
      { header: "Member", accessor: (r: DuesItem) => r.memberId },
      { header: "Outstanding (INR)", accessor: (r: DuesItem) => (num(r.outstandingMinor) / 100).toFixed(2) },
      { header: "Age (days)", accessor: (r: DuesItem) => r.ageDays },
      { header: "Bucket", accessor: (r: DuesItem) => r.bucket },
    ];
    if (kind === "csv") exportCsv("defaulter-report", cols, defaulters);
    else exportPdf("defaulter-report", "Defaulter Report", cols, defaulters, "Outstanding dues · live");
  }

  return (
    <div>
      <PageHeader title="Reports" subtitle="Collection, dues ageing, defaulters & trial balance — live" />

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <StatCard label="Invoiced" value={formatMoneyMinor(s.invoicedMinor)} tone="blue" />
        <StatCard label="Collected" value={formatMoneyMinor(s.collectedMinor)} tone="green" />
        <StatCard label="Expenses" value={formatMoneyMinor(s.expensesMinor)} tone="amber" />
        <StatCard label="Outstanding" value={formatMoneyMinor(s.outstandingMinor)} tone="red" />
      </div>

      <Card className="mt-5 p-4">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-semibold text-slate-800">Dues Ageing Buckets</h2>
        </div>
        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
          {dues &&
            Object.entries(dues.buckets).map(([k, v]) => (
              <div key={k} className="rounded-lg border border-slate-200 p-3">
                <p className="text-xs text-slate-500">{k} days</p>
                <p className="mt-1 text-lg font-semibold">{formatMoneyMinor(num(v))}</p>
              </div>
            ))}
        </div>
      </Card>

      <Card className="mt-4 p-4">
        <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
          <h2 className="font-semibold text-slate-800">
            Defaulter Report{" "}
            <span className="ml-1 text-sm font-normal text-slate-400">
              ({defaulters.length})
            </span>
          </h2>
          <div className="flex gap-2">
            <button className="btn-outline" disabled={!defaulters.length} onClick={() => exportDefaulters("csv")}>
              <Download className="h-4 w-4" /> CSV
            </button>
            <button className="btn-outline" disabled={!defaulters.length} onClick={() => exportDefaulters("pdf")}>
              <Download className="h-4 w-4" /> PDF
            </button>
          </div>
        </div>
        {defaulters.length === 0 ? (
          <p className="py-8 text-center text-sm text-slate-400">No outstanding dues 🎉</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Invoice</th>
                  <th>Member</th>
                  <th className="text-right">Outstanding</th>
                  <th className="text-right">Age</th>
                  <th>Bucket</th>
                </tr>
              </thead>
              <tbody>
                {defaulters.map((d) => (
                  <tr key={d.invoiceId}>
                    <td className="font-medium">{d.number}</td>
                    <td>{d.memberId.slice(0, 8)}</td>
                    <td className="text-right font-medium text-red-600">
                      {formatMoneyMinor(num(d.outstandingMinor))}
                    </td>
                    <td className="text-right">{d.ageDays}d</td>
                    <td>
                      <StatusChip tone={d.bucket === "0-30" ? "green" : d.bucket === "90+" ? "red" : "amber"}>
                        {d.bucket}
                      </StatusChip>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Card className="mt-4 p-4">
        <h2 className="mb-2 font-semibold text-slate-800">Trial Balance</h2>
        {tbQ.isLoading ? (
          <p className="text-sm text-slate-400">Loading…</p>
        ) : tbQ.isError || !tbQ.data?.accounts ? (
          <p className="text-sm text-slate-400">Trial balance unavailable.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Account</th>
                  <th>Type</th>
                  <th className="text-right">Debit</th>
                  <th className="text-right">Credit</th>
                </tr>
              </thead>
              <tbody>
                {tbQ.data.accounts.map((a: any) => (
                  <tr key={a.code}>
                    <td className="font-mono text-xs">{a.code}</td>
                    <td>{a.name}</td>
                    <td className="capitalize">{a.type}</td>
                    <td className="text-right">{formatMoneyMinor(num(a.debitMinor))}</td>
                    <td className="text-right">{formatMoneyMinor(num(a.creditMinor))}</td>
                  </tr>
                ))}
                <tr className="font-semibold">
                  <td colSpan={3}>
                    Total {tbQ.data.balanced ? "· Balanced ✓" : "· Unbalanced"}
                  </td>
                  <td className="text-right">{formatMoneyMinor(num(tbQ.data.totalDebitMinor))}</td>
                  <td className="text-right">{formatMoneyMinor(num(tbQ.data.totalCreditMinor))}</td>
                </tr>
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
