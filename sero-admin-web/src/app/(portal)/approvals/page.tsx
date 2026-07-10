"use client";
import { UserCheck, Check, X, Phone, Home } from "lucide-react";
import { useApi, useApiMutation } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, Card, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";

// Pending resident/app registrations live in TWO backend stores:
//  1. Firestore `users` (app self-registration)  -> /auth/pending, /auth/approve|reject/:uid
//  2. Postgres `members` join-requests            -> /members-v2/join-requests[/:id/approve|reject]
// This page surfaces both so admins can approve residents from the website.

type PendingUser = {
  id: string;
  name: string;
  phone: string;
  flatNumber?: string;
  blockName?: string;
  role?: string;
  status?: string;
};
type JoinRequest = {
  id: string;
  name: string;
  phone: string;
  unit_number?: string | null;
  requested_unit?: string | null;
  role?: string;
  status?: string;
};

export default function ApprovalsPage() {
  const { push } = useToast();

  const pendingQ = useApi<{ pending: PendingUser[] }>(["auth", "pending"], "/auth/pending");
  const joinQ = useApi<{ requests: JoinRequest[] }>(["members", "join-requests"], "/members-v2/join-requests");

  const approveUser = useApiMutation("post", [["auth", "pending"]]);
  const rejectUser = useApiMutation("post", [["auth", "pending"]]);
  const approveJoin = useApiMutation("post", [["members", "join-requests"], ["members"]]);
  const rejectJoin = useApiMutation("post", [["members", "join-requests"]]);

  const pending = pendingQ.data?.pending || [];
  const joins = joinQ.data?.requests || [];
  const total = pending.length + joins.length;

  return (
    <div>
      <PageHeader
        title="Resident Approvals"
        subtitle="Approve or reject residents who registered via the app or requested to join"
      />

      <div className="mb-4 grid grid-cols-3 gap-3">
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">Pending total</p>
          <p className="mt-1 text-2xl font-semibold">{total}</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">App registrations</p>
          <p className="mt-1 text-2xl font-semibold">{pending.length}</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs uppercase text-slate-500">Join requests</p>
          <p className="mt-1 text-2xl font-semibold">{joins.length}</p>
        </Card>
      </div>

      {/* ── App registrations (Firestore) ─────────────────────────── */}
      <h2 className="mb-2 mt-6 flex items-center gap-2 font-display text-lg font-bold text-navy-800">
        <UserCheck className="h-5 w-5 text-brand-600" /> App Registrations
      </h2>
      {pendingQ.isLoading ? (
        <LoadingState />
      ) : pendingQ.isError ? (
        <ErrorState onRetry={() => pendingQ.refetch()} />
      ) : pending.length === 0 ? (
        <EmptyState title="No pending registrations" hint="New app sign-ups will appear here for approval." />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Phone</th>
                <th>Flat / Block</th>
                <th>Status</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {pending.map((u) => (
                <tr key={u.id}>
                  <td className="font-medium text-slate-900">{u.name}</td>
                  <td className="tabular-nums">{u.phone || "—"}</td>
                  <td>
                    {u.flatNumber || "—"}
                    {u.blockName ? ` · ${u.blockName}` : ""}
                  </td>
                  <td>
                    <StatusChip tone="amber">{u.status || "pending"}</StatusChip>
                  </td>
                  <td className="text-right">
                    <div className="flex justify-end gap-1">
                      <button
                        className="btn-primary h-8 px-3 text-xs"
                        disabled={approveUser.isPending}
                        onClick={() =>
                          approveUser.mutate(
                            { path: `/auth/approve/${u.id}` },
                            {
                              onSuccess: () => push("success", `${u.name} approved`),
                              onError: (e) => push("error", e.message),
                            }
                          )
                        }
                      >
                        <Check className="h-3.5 w-3.5" /> Approve
                      </button>
                      <button
                        className="btn-ghost h-8 px-3 text-xs text-red-600"
                        disabled={rejectUser.isPending}
                        onClick={() =>
                          rejectUser.mutate(
                            { path: `/auth/reject/${u.id}`, body: { reason: "" } },
                            {
                              onSuccess: () => push("success", `${u.name} rejected`),
                              onError: (e) => push("error", e.message),
                            }
                          )
                        }
                      >
                        <X className="h-3.5 w-3.5" /> Reject
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Join requests (Postgres) ──────────────────────────────── */}
      <h2 className="mb-2 mt-8 flex items-center gap-2 font-display text-lg font-bold text-navy-800">
        <Home className="h-5 w-5 text-brand-600" /> Society Join Requests
      </h2>
      {joinQ.isLoading ? (
        <LoadingState />
      ) : joinQ.isError ? (
        <ErrorState onRetry={() => joinQ.refetch()} />
      ) : joins.length === 0 ? (
        <EmptyState title="No join requests" hint="Residents requesting a unit will appear here." />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Phone</th>
                <th>Requested Unit</th>
                <th>Status</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {joins.map((r) => (
                <tr key={r.id}>
                  <td className="font-medium text-slate-900">{r.name}</td>
                  <td className="tabular-nums">
                    <span className="inline-flex items-center gap-1">
                      <Phone className="h-3 w-3 text-slate-400" /> {r.phone || "—"}
                    </span>
                  </td>
                  <td>{r.unit_number || r.requested_unit || "—"}</td>
                  <td>
                    <StatusChip tone="amber">{r.status || "pending"}</StatusChip>
                  </td>
                  <td className="text-right">
                    <div className="flex justify-end gap-1">
                      <button
                        className="btn-primary h-8 px-3 text-xs"
                        disabled={approveJoin.isPending}
                        onClick={() =>
                          approveJoin.mutate(
                            { path: `/members-v2/join-requests/${r.id}/approve` },
                            {
                              onSuccess: () => push("success", `${r.name} approved`),
                              onError: (e) => push("error", e.message),
                            }
                          )
                        }
                      >
                        <Check className="h-3.5 w-3.5" /> Approve
                      </button>
                      <button
                        className="btn-ghost h-8 px-3 text-xs text-red-600"
                        disabled={rejectJoin.isPending}
                        onClick={() =>
                          rejectJoin.mutate(
                            { path: `/members-v2/join-requests/${r.id}/reject`, body: { reason: "" } },
                            {
                              onSuccess: () => push("success", `${r.name} rejected`),
                              onError: (e) => push("error", e.message),
                            }
                          )
                        }
                      >
                        <X className="h-3.5 w-3.5" /> Reject
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
