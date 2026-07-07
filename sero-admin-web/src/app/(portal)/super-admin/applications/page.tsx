"use client";
import { useApi, useApiMutation } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDate } from "@/lib/format";
import { Check, X } from "lucide-react";

function extractRows(data: any): any[] {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  return data.applications || data.data?.applications || data.items || data.data || [];
}

export default function ApplicationsPage() {
  const { push } = useToast();
  const q = useApi<any>(["sa", "applications"], "/super-admin/applications");
  const review = useApiMutation("post", [["sa", "applications"], ["sa", "dashboard"]]);
  const rows = extractRows(q.data);

  function act(id: string, action: "approve" | "reject") {
    review.mutate(
      { path: `/super-admin/applications/${id}/review`, body: { action, reason: action === "reject" ? "Rejected from web console" : undefined } },
      {
        onSuccess: () => push("success", `Application ${action}d`),
        onError: (e) => push("error", e.message),
      }
    );
  }

  return (
    <div>
      <PageHeader title="Society Approvals" subtitle="KYC & onboarding applications — live" />
      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : rows.length === 0 ? (
        <EmptyState title="No pending applications" hint="New society applications appear here." />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Society</th>
                <th>Applicant</th>
                <th>Status</th>
                <th>Submitted</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r: any, i: number) => {
                const id = r.id || r.application_id || r.society_id;
                return (
                  <tr key={id || i}>
                    <td className="font-medium text-slate-900">{r.society_name || r.name || id}</td>
                    <td>{r.applicant_name || r.contact_name || r.admin_name || "—"}</td>
                    <td>
                      <StatusChip tone={r.status === "pending" ? "amber" : r.status === "approved" ? "green" : "slate"}>
                        {r.status || "pending"}
                      </StatusChip>
                    </td>
                    <td>{r.created_at ? formatDate(r.created_at) : "—"}</td>
                    <td className="text-right">
                      <div className="flex justify-end gap-1">
                        <button className="btn-ghost h-8 px-2 text-xs text-brand-700" onClick={() => act(id, "approve")}>
                          <Check className="h-3.5 w-3.5" /> Approve
                        </button>
                        <button className="btn-ghost h-8 px-2 text-xs text-red-600" onClick={() => act(id, "reject")}>
                          <X className="h-3.5 w-3.5" /> Reject
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
