"use client";
import { useState } from "react";
import { Plus, Play, Square, BarChart2 } from "lucide-react";
import { useApi, useApiMutation } from "@/lib/hooks";
import { api } from "@/lib/api-client";
import { useToast } from "@/components/ui/toast";
import { PageHeader, StatusChip, Modal } from "@/components/ui/primitives";
import { LoadingState, ErrorState, EmptyState } from "@/components/ui/states";
import { formatDateTime } from "@/lib/format";

type Poll = {
  id: string;
  title: string;
  description: string | null;
  status: string;
  vote_scope: string;
  starts_at: string | null;
  ends_at: string | null;
};

export default function PollsPage() {
  const { push } = useToast();
  const q = useApi<{ polls: Poll[] }>(["polls"], "/polls-v2");
  const create = useApiMutation("post", [["polls"]]);
  const openPoll = useApiMutation("post", [["polls"]]);
  const closePoll = useApiMutation("post", [["polls"]]);
  const [showCreate, setShowCreate] = useState(false);
  const [results, setResults] = useState<{ poll: Poll; data: any } | null>(null);
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");
  const [options, setOptions] = useState("Yes\nNo");

  const polls = q.data?.polls || [];

  async function viewResults(p: Poll) {
    try {
      const r = await api.get<any>(`/polls-v2/${p.id}/results`);
      setResults({ poll: p, data: r?.data || r });
    } catch (e: any) {
      push("error", e.message);
    }
  }

  return (
    <div>
      <PageHeader
        title="Polls & AGM"
        subtitle="Create polls, track turnout, publish results — synced to residents"
        actions={
          <button className="btn-primary" onClick={() => setShowCreate(true)}>
            <Plus className="h-4 w-4" /> New Poll
          </button>
        }
      />

      {q.isLoading ? (
        <LoadingState />
      ) : q.isError ? (
        <ErrorState onRetry={() => q.refetch()} />
      ) : polls.length === 0 ? (
        <EmptyState title="No polls" hint="Create a poll — residents can vote from the app." />
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {polls.map((p) => (
            <div key={p.id} className="card p-4">
              <div className="flex items-start justify-between gap-2">
                <h3 className="font-semibold text-slate-900">{p.title}</h3>
                <StatusChip tone={p.status === "open" ? "green" : p.status === "closed" ? "slate" : "amber"}>
                  {p.status}
                </StatusChip>
              </div>
              {p.description && <p className="mt-1 text-sm text-slate-500">{p.description}</p>}
              <p className="mt-2 text-xs text-slate-400">
                {p.vote_scope} vote · {p.ends_at ? `ends ${formatDateTime(p.ends_at)}` : "no end"}
              </p>
              <div className="mt-3 flex gap-1">
                {p.status === "draft" && (
                  <button
                    className="btn-ghost h-8 px-2 text-xs"
                    onClick={() =>
                      openPoll.mutate(
                        { path: `/polls-v2/${p.id}/open` },
                        { onSuccess: () => push("success", "Poll opened"), onError: (e) => push("error", e.message) }
                      )
                    }
                  >
                    <Play className="h-3.5 w-3.5" /> Open
                  </button>
                )}
                {p.status === "open" && (
                  <button
                    className="btn-ghost h-8 px-2 text-xs"
                    onClick={() =>
                      closePoll.mutate(
                        { path: `/polls-v2/${p.id}/close` },
                        { onSuccess: () => push("success", "Poll closed"), onError: (e) => push("error", e.message) }
                      )
                    }
                  >
                    <Square className="h-3.5 w-3.5" /> Close
                  </button>
                )}
                <button className="btn-ghost h-8 px-2 text-xs" onClick={() => viewResults(p)}>
                  <BarChart2 className="h-3.5 w-3.5" /> Results
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showCreate && (
        <Modal
          open
          onClose={() => setShowCreate(false)}
          title="Create Poll"
          footer={
            <>
              <button className="btn-outline" onClick={() => setShowCreate(false)}>Cancel</button>
              <button
                className="btn-primary"
                disabled={create.isPending || !title}
                onClick={() => {
                  const opts = options
                    .split("\n")
                    .map((s) => s.trim())
                    .filter(Boolean)
                    .map((label, i) => ({ label, position: i }));
                  if (opts.length < 2) {
                    push("error", "Add at least 2 options");
                    return;
                  }
                  create.mutate(
                    {
                      path: "/polls-v2",
                      body: {
                        title,
                        description: desc || undefined,
                        voteScope: "user",
                        options: opts,
                        endsAt: new Date(Date.now() + 7 * 864e5).toISOString(),
                      },
                    },
                    {
                      onSuccess: () => {
                        push("success", "Poll created");
                        setShowCreate(false);
                        setTitle("");
                        setDesc("");
                      },
                      onError: (e) => push("error", e.message),
                    }
                  );
                }}
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
              <span className="mb-1 block text-slate-600">Description</span>
              <input className="input" value={desc} onChange={(e) => setDesc(e.target.value)} />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block text-slate-600">Options (one per line)</span>
              <textarea className="input h-24 resize-none" value={options} onChange={(e) => setOptions(e.target.value)} />
            </label>
          </div>
        </Modal>
      )}

      {results && (
        <Modal open onClose={() => setResults(null)} title={`Results — ${results.poll.title}`}>
          <PollResults data={results.data} />
        </Modal>
      )}
    </div>
  );
}

function PollResults({ data }: { data: any }) {
  const options: any[] = data?.options || data?.results || [];
  const total = options.reduce((a, o) => a + (o.votes || o.count || 0), 0);
  if (!options.length) {
    return <p className="text-sm text-slate-500">No votes yet or results are hidden until close.</p>;
  }
  return (
    <div className="space-y-3">
      {options.map((o, i) => {
        const votes = o.votes || o.count || 0;
        const pct = total ? Math.round((votes / total) * 100) : 0;
        return (
          <div key={i}>
            <div className="mb-1 flex justify-between text-sm">
              <span className="text-slate-700">{o.label}</span>
              <span className="text-slate-500">{votes} ({pct}%)</span>
            </div>
            <div className="h-2 w-full rounded-full bg-slate-100">
              <div className="h-2 rounded-full bg-brand-500" style={{ width: `${pct}%` }} />
            </div>
          </div>
        );
      })}
      <p className="pt-1 text-xs text-slate-400">Total votes: {total}</p>
    </div>
  );
}
