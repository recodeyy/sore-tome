"use client";
import { useState } from "react";
import { UserPlus, Download } from "lucide-react";
import { useApi, useApiMutation } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, Card, StatusChip, Modal } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDateTime, titleCase } from "@/lib/format";
import { exportCsv } from "@/lib/export";

type Complaint = {
  id: string;
  ref: string;
  title: string;
  priority: string;
  status: string;
  assigned_to: string | null;
  sla_minutes: number | null;
  due_at: string | null;
  created_at: string;
};
type Staff = { id: string; name: string; role: string };

const PRIORITY_TONE: Record<string, "red" | "amber" | "slate"> = {
  high: "red",
  urgent: "red",
  medium: "amber",
  low: "slate",
};
const STATUS_TONE: Record<string, "green" | "amber" | "blue" | "slate"> = {
  open: "amber",
  in_progress: "blue",
  resolved: "green",
  closed: "slate",
};

export default function ComplaintsPage() {
  const { push } = useToast();
  const q = useApi<{ complaints: Complaint[] }>(["complaints"], "/complaints");
  const staffQ = useApi<{ staff: Staff[] }>(["staff"], "/staff-v2");
  const assign = useApiMutation("post", [["complaints"]]);
  const setStatus = useApiMutation("patch", [["complaints"]]);
  const [assignFor, setAssignFor] = useState<Complaint | null>(null);

  const complaints = q.data?.complaints || [];
  const staff = staffQ.data?.staff || [];

  return (
    <div>
      <PageHeader
        title="Complaints"
        subtitle="Helpdesk tickets, assignment, SLA & escalation — live"
        actions={
          <button
            className="btn-outline"
            disabled={!complaints.length}
            onClick={() =>
              exportCsv(
                "complaint-sla-report",
                [
                  { header: "Ref", accessor: (c: Complaint) => c.ref },
                  { header: "Title", accessor: (c: Complaint) => c.title },
                  { header: "Priority", accessor: (c: Complaint) => c.priority },
                  { header: "Status", accessor: (c: Complaint) => c.status },
                  { header: "SLA (min)", accessor: (c: Complaint) => c.sla_minutes ?? "" },
                  { header: "Due", accessor: (c: Complaint) => (c.due_at ? formatDateTime(c.due_at) : "") },
                ],
                complaints
              )
            }
          >
            <Download className="h-4 w-4" /> SLA Report
          </button>
        }
      />

      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : complaints.length === 0 ? (
        <EmptyState title="No complaints" hint="Resident-raised tickets appear here in real time." />
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Ref</th>
                <th>Title</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Assignee</th>
                <th>Due</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {complaints.map((c) => (
                <tr key={c.id}>
                  <td className="font-mono text-xs">{c.ref}</td>
                  <td className="font-medium text-slate-900">{c.title}</td>
                  <td>
                    <StatusChip tone={PRIORITY_TONE[c.priority] || "slate"}>{c.priority}</StatusChip>
                  </td>
                  <td>
                    <select
                      className="input h-8 w-32 py-0 text-xs"
                      value={c.status}
                      onChange={(e) =>
                        setStatus.mutate(
                          { path: `/complaints/${c.id}/status`, body: { status: e.target.value } },
                          {
                            onSuccess: () => push("success", `${c.ref} → ${e.target.value}`),
                            onError: (err) => push("error", err.message),
                          }
                        )
                      }
                    >
                      {["open", "in_progress", "resolved", "closed"].map((s) => (
                        <option key={s} value={s}>{titleCase(s)}</option>
                      ))}
                    </select>
                  </td>
                  <td>{c.assigned_to ? c.assigned_to.slice(0, 8) : <span className="text-slate-400">Unassigned</span>}</td>
                  <td className="text-xs">{c.due_at ? formatDateTime(c.due_at) : "—"}</td>
                  <td className="text-right">
                    <button className="btn-ghost h-8 px-2 text-xs" onClick={() => setAssignFor(c)}>
                      <UserPlus className="h-3.5 w-3.5" /> Assign
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {assignFor && (
        <AssignModal
          complaint={assignFor}
          staff={staff}
          submitting={assign.isPending}
          onClose={() => setAssignFor(null)}
          onSubmit={(assigneeId) =>
            assign.mutate(
              {
                path: `/complaints/${assignFor.id}/assign`,
                body: { assigneeId, assigneeType: "staff", reason: "Assigned from web console" },
              },
              {
                onSuccess: () => {
                  push("success", "Complaint assigned — staff app notified");
                  setAssignFor(null);
                },
                onError: (e) => push("error", e.message),
              }
            )
          }
        />
      )}
    </div>
  );
}

function AssignModal({
  complaint,
  staff,
  onClose,
  onSubmit,
  submitting,
}: {
  complaint: Complaint;
  staff: Staff[];
  onClose: () => void;
  onSubmit: (assigneeId: string) => void;
  submitting: boolean;
}) {
  const [assignee, setAssignee] = useState(staff[0]?.id || "");
  return (
    <Modal
      open
      onClose={onClose}
      title={`Assign — ${complaint.ref}`}
      footer={
        <>
          <button className="btn-outline" onClick={onClose}>Cancel</button>
          <button className="btn-primary" disabled={submitting || !assignee} onClick={() => onSubmit(assignee)}>
            Assign
          </button>
        </>
      }
    >
      <label className="text-sm">
        <span className="mb-1 block text-slate-600">Assign to staff</span>
        <select className="input" value={assignee} onChange={(e) => setAssignee(e.target.value)}>
          {staff.length === 0 && <option value="">No staff available</option>}
          {staff.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name} ({titleCase(s.role)})
            </option>
          ))}
        </select>
      </label>
      <p className="mt-3 text-xs text-slate-400">
        The assigned staff member receives this as a task in the mobile staff app.
      </p>
    </Modal>
  );
}
