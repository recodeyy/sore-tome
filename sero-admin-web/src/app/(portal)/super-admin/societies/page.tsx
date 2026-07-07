"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDate } from "@/lib/format";
import { exportCsv } from "@/lib/export";
import { Download } from "lucide-react";

function extractRows(data: any): any[] {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  return data.societies || data.data?.societies || data.items || data.data || [];
}

export default function SocietiesPage() {
  const q = useApi<any>(["sa", "societies"], "/super-admin/societies");
  const rows = extractRows(q.data);

  return (
    <div>
      <PageHeader
        title="Societies"
        subtitle="All onboarded societies — live"
        actions={
          <button
            className="btn-outline"
            disabled={!rows.length}
            onClick={() =>
              exportCsv(
                "societies",
                [
                  { header: "Name", accessor: (r: any) => r.society_name || r.name || "" },
                  { header: "Status", accessor: (r: any) => r.status || "" },
                  { header: "City", accessor: (r: any) => r.city || "" },
                  { header: "Created", accessor: (r: any) => (r.created_at ? formatDate(r.created_at) : "") },
                ],
                rows
              )
            }
          >
            <Download className="h-4 w-4" /> CSV
          </button>
        }
      />
      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : rows.length === 0 ? (
        <EmptyState title="No societies" />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Society</th>
                <th>Status</th>
                <th>City</th>
                <th>Plan</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r: any, i: number) => (
                <tr key={r.society_id || r.id || i}>
                  <td className="font-medium text-slate-900">{r.society_name || r.name || r.society_id}</td>
                  <td>
                    <StatusChip tone={r.status === "approved" || r.status === "active" ? "green" : r.status === "pending" ? "amber" : "slate"}>
                      {r.status || "—"}
                    </StatusChip>
                  </td>
                  <td>{r.city || "—"}</td>
                  <td>{r.plan || r.plan_name || "—"}</td>
                  <td>{r.created_at ? formatDate(r.created_at) : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
