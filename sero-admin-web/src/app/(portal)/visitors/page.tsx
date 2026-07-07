"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader, Card, StatCard, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDateTime, titleCase } from "@/lib/format";
import { exportCsv } from "@/lib/export";
import { Download } from "lucide-react";

type Visitor = {
  id: string;
  name: string;
  phone: string;
  purpose: string;
  status: string;
  checked_in_at: string | null;
  checked_out_at: string | null;
};

const STATUS_TONE: Record<string, "green" | "amber" | "blue" | "slate" | "red"> = {
  expected: "amber",
  inside: "green",
  checked_in: "green",
  approved: "blue",
  denied: "red",
  checked_out: "slate",
  completed: "slate",
};

export default function VisitorsPage() {
  const q = useApi<{ visitors: Visitor[] }>(["visitors"], "/guard/visitors");
  const visitors = q.data?.visitors || [];

  const inside = visitors.filter((v) => ["inside", "checked_in"].includes(v.status)).length;
  const expected = visitors.filter((v) => v.status === "expected").length;

  return (
    <div>
      <PageHeader
        title="Visitors & Security"
        subtitle="Live gate activity — updates as guards act in the app"
        actions={
          <button
            className="btn-outline"
            disabled={!visitors.length}
            onClick={() =>
              exportCsv(
                "visitor-register",
                [
                  { header: "Name", accessor: (v: Visitor) => v.name },
                  { header: "Phone", accessor: (v: Visitor) => v.phone },
                  { header: "Purpose", accessor: (v: Visitor) => v.purpose },
                  { header: "Status", accessor: (v: Visitor) => v.status },
                  { header: "Checked In", accessor: (v: Visitor) => (v.checked_in_at ? formatDateTime(v.checked_in_at) : "") },
                  { header: "Checked Out", accessor: (v: Visitor) => (v.checked_out_at ? formatDateTime(v.checked_out_at) : "") },
                ],
                visitors
              )
            }
          >
            <Download className="h-4 w-4" /> Visitor Register
          </button>
        }
      />

      <div className="mb-4 grid grid-cols-3 gap-3">
        <StatCard label="Inside Now" value={String(inside)} tone="green" />
        <StatCard label="Expected" value={String(expected)} tone="amber" />
        <StatCard label="Total Today" value={String(visitors.length)} tone="blue" />
      </div>

      <Card className="p-0">
        {q.isLoading ? (
          <LoadingState />
        ) : q.isError ? (
          <ErrorState onRetry={() => q.refetch()} />
        ) : visitors.length === 0 ? (
          <EmptyState title="No gate activity" hint="Visitor entries logged by guards appear here live." />
        ) : (
          <div className="table-wrap border-0">
            <table className="table">
              <thead>
                <tr>
                  <th>Visitor</th>
                  <th>Phone</th>
                  <th>Purpose</th>
                  <th>Status</th>
                  <th>Checked In</th>
                  <th>Checked Out</th>
                </tr>
              </thead>
              <tbody>
                {visitors.map((v) => (
                  <tr key={v.id}>
                    <td className="font-medium text-slate-900">{v.name}</td>
                    <td>{v.phone || "—"}</td>
                    <td>{titleCase(v.purpose)}</td>
                    <td><StatusChip tone={STATUS_TONE[v.status] || "slate"}>{v.status}</StatusChip></td>
                    <td className="text-xs">{v.checked_in_at ? formatDateTime(v.checked_in_at) : "—"}</td>
                    <td className="text-xs">{v.checked_out_at ? formatDateTime(v.checked_out_at) : "—"}</td>
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
