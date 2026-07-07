"use client";
import { useState } from "react";
import { Plus, Send, Download } from "lucide-react";
import { useApi, useApiMutation } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, StatusChip, Modal } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDateTime } from "@/lib/format";
import { exportCsv } from "@/lib/export";

type Notice = {
  id: string;
  title: string;
  body: string;
  type: string;
  priority: string;
  status: string;
  ack_required: boolean;
  published_at: string | null;
  created_at: string;
};

export default function NoticesPage() {
  const { push } = useToast();
  const q = useApi<{ notices: Notice[] }>(["notices"], "/notices-v2");
  const create = useApiMutation("post", [["notices"]]);
  const publish = useApiMutation("post", [["notices"]]);
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [type, setType] = useState("general");

  const notices = q.data?.notices || [];

  return (
    <div>
      <PageHeader
        title="Notices"
        subtitle="Publish to residents in real time · read/ack tracking"
        actions={
          <>
            <button
              className="btn-outline"
              disabled={!notices.length}
              onClick={() =>
                exportCsv(
                  "notices",
                  [
                    { header: "Title", accessor: (n: Notice) => n.title },
                    { header: "Type", accessor: (n: Notice) => n.type },
                    { header: "Status", accessor: (n: Notice) => n.status },
                    { header: "Published", accessor: (n: Notice) => (n.published_at ? formatDateTime(n.published_at) : "") },
                  ],
                  notices
                )
              }
            >
              <Download className="h-4 w-4" /> CSV
            </button>
            <button className="btn-primary" onClick={() => setOpen(true)}>
              <Plus className="h-4 w-4" /> New Notice
            </button>
          </>
        }
      />

      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : notices.length === 0 ? (
        <EmptyState title="No notices" hint="Create a notice — residents get it instantly." />
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {notices.map((n) => (
            <div key={n.id} className="card p-4">
              <div className="flex items-start justify-between gap-2">
                <h3 className="font-semibold text-slate-900">{n.title}</h3>
                <StatusChip tone={n.status === "published" ? "green" : "slate"}>{n.status}</StatusChip>
              </div>
              <p className="mt-1 line-clamp-2 text-sm text-slate-500">{n.body}</p>
              <div className="mt-3 flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs text-slate-400">
                  <StatusChip tone="blue">{n.type}</StatusChip>
                  {n.ack_required && <StatusChip tone="amber">ack required</StatusChip>}
                  <span>{n.published_at ? formatDateTime(n.published_at) : "draft"}</span>
                </div>
                {n.status !== "published" && (
                  <button
                    className="btn-ghost h-8 px-2 text-xs"
                    onClick={() =>
                      publish.mutate(
                        { path: `/notices-v2/${n.id}/publish` },
                        {
                          onSuccess: () => push("success", "Published — residents notified"),
                          onError: (e) => push("error", e.message),
                        }
                      )
                    }
                  >
                    <Send className="h-3.5 w-3.5" /> Publish
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {open && (
        <Modal
          open
          onClose={() => setOpen(false)}
          title="Create Notice"
          footer={
            <>
              <button className="btn-outline" onClick={() => setOpen(false)}>Cancel</button>
              <button
                className="btn-primary"
                disabled={create.isPending || !title || !body}
                onClick={() =>
                  create.mutate(
                    { path: "/notices-v2", body: { title, body, type } },
                    {
                      onSuccess: () => {
                        push("success", "Notice created (draft)");
                        setOpen(false);
                        setTitle("");
                        setBody("");
                      },
                      onError: (e) => push("error", e.message),
                    }
                  )
                }
              >
                Create
              </button>
            </>
          }
        >
          <div className="space-y-3">
            <label className="block text-sm">
              <span className="mb-1 block text-slate-600">Title</span>
              <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block text-slate-600">Type</span>
              <select className="input" value={type} onChange={(e) => setType(e.target.value)}>
                {["general", "event", "maintenance", "festival"].map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
            </label>
            <label className="block text-sm">
              <span className="mb-1 block text-slate-600">Body</span>
              <textarea className="input h-28 resize-none" value={body} onChange={(e) => setBody(e.target.value)} />
            </label>
          </div>
        </Modal>
      )}
    </div>
  );
}
