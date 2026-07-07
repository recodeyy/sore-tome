"use client";
import { useState } from "react";
import { Plus } from "lucide-react";
import { useApi, useApiMutation } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, Card, Modal } from "@/components/ui/primitives";
import { LoadingState, EmptyState } from "@/components/ui/states";
import { formatDate } from "@/lib/format";

function extractRows(data: any): any[] {
  if (!data) return [];
  if (Array.isArray(data)) return data;
  return data.announcements || data.data?.announcements || data.items || data.data || [];
}

export default function AnnouncementsPage() {
  const { push } = useToast();
  const q = useApi<any>(["sa", "announcements"], "/super-admin/announcements");
  const create = useApiMutation("post", [["sa", "announcements"]]);
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const rows = extractRows(q.data);

  return (
    <div>
      <PageHeader
        title="Global Announcements"
        subtitle="Broadcast to all societies — live"
        actions={
          <button className="btn-primary" onClick={() => setOpen(true)}>
            <Plus className="h-4 w-4" /> New Announcement
          </button>
        }
      />
      {q.isLoading ? (
        <LoadingState />
      ) : rows.length === 0 ? (
        <EmptyState title="No announcements" hint="Broadcast platform-wide updates." />
      ) : (
        <div className="space-y-3">
          {rows.map((a: any, i: number) => (
            <Card key={a.id || i} className="p-4">
              <div className="flex items-start justify-between">
                <h3 className="font-semibold text-slate-900">{a.title}</h3>
                <span className="text-xs text-slate-400">{a.created_at ? formatDate(a.created_at) : ""}</span>
              </div>
              <p className="mt-1 text-sm text-slate-500">{a.body || a.message}</p>
            </Card>
          ))}
        </div>
      )}

      {open && (
        <Modal
          open
          onClose={() => setOpen(false)}
          title="New Global Announcement"
          footer={
            <>
              <button className="btn-outline" onClick={() => setOpen(false)}>Cancel</button>
              <button
                className="btn-primary"
                disabled={create.isPending || !title || !body}
                onClick={() =>
                  create.mutate(
                    { path: "/super-admin/announcements", body: { title, body } },
                    {
                      onSuccess: () => {
                        push("success", "Announcement published");
                        setOpen(false);
                        setTitle("");
                        setBody("");
                      },
                      onError: (e) => push("error", e.message),
                    }
                  )
                }
              >
                Publish
              </button>
            </>
          }
        >
          <div className="space-y-3">
            <input className="input" placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} />
            <textarea className="input h-28 resize-none" placeholder="Message" value={body} onChange={(e) => setBody(e.target.value)} />
          </div>
        </Modal>
      )}
    </div>
  );
}
