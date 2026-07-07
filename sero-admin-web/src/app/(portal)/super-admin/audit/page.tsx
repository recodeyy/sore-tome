"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDateTime } from "@/lib/format";
import { exportCsv } from "@/lib/export";
import { Download } from "lucide-react";

function extractRows(data: any): any[] {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  return data.logs || data.data?.logs || data.items || data.data || [];
}

export default function AuditPage() {
  const q = useApi<any>(["sa", "audit"], "/super-admin/audit-logs");
  const rows = extractRows(q.data);

  return (
    <div>
      <PageHeader
        title="Audit Logs"
        subtitle="Platform-level actions, impersonation & security events — live"
        actions={
          <button
            className="btn-outline"
            disabled={!rows.length}
            onClick={() =>
              exportCsv(
                "audit-logs",
                [
                  { header: "Time", accessor: (r: any) => (r.created_at || r.at ? formatDateTime(r.created_at || r.at) : "") },
                  { header: "Actor", accessor: (r: any) => r.actor_id || r.actor || r.user_id || "" },
                  { header: "Action", accessor: (r: any) => r.action || r.event || "" },
                  { header: "Target", accessor: (r: any) => r.target || r.resource || r.society_id || "" },
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
        <EmptyState title="No audit entries" />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Time</th>
                <th>Actor</th>
                <th>Action</th>
                <th>Target</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r: any, i: number) => (
                <tr key={r.id || i}>
                  <td className="text-xs">{r.created_at || r.at ? formatDateTime(r.created_at || r.at) : "—"}</td>
                  <td>{r.actor_id || r.actor || r.user_id || "—"}</td>
                  <td className="font-medium text-slate-800">{r.action || r.event || "—"}</td>
                  <td>{r.target || r.resource || r.society_id || "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
