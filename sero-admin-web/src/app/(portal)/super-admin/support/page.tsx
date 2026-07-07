"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDate, titleCase } from "@/lib/format";

function extractRows(data: any): any[] {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  return data.tickets || data.data?.tickets || data.items || data.data || [];
}

export default function SupportPage() {
  const q = useApi<any>(["sa", "support"], "/super-admin/support/tickets");
  const rows = extractRows(q.data);

  return (
    <div>
      <PageHeader title="Support Tickets" subtitle="Platform support & SLA — live" />
      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : rows.length === 0 ? (
        <EmptyState title="No support tickets" />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Ref</th>
                <th>Subject</th>
                <th>Society</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r: any, i: number) => (
                <tr key={r.id || r.ticket_id || i}>
                  <td className="font-mono text-xs">{r.ref || r.id?.slice(0, 8) || "—"}</td>
                  <td className="font-medium text-slate-900">{r.subject || r.title || "—"}</td>
                  <td>{r.society_name || r.society_id || "—"}</td>
                  <td><StatusChip tone={r.priority === "high" ? "red" : r.priority === "medium" ? "amber" : "slate"}>{r.priority || "—"}</StatusChip></td>
                  <td><StatusChip tone={r.status === "resolved" ? "green" : r.status === "open" ? "amber" : "blue"}>{titleCase(r.status || "")}</StatusChip></td>
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
