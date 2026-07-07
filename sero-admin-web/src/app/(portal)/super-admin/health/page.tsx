"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader, Card, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState } from "@/components/ui/states";

export default function HealthPage() {
  const q = useApi<any>(["sa", "health"], "/super-admin/system-health");
  if (q.isLoading) return <LoadingState />;
  if (q.isError) return <ErrorState onRetry={() => q.refetch()} />;
  const h = q.data?.data || q.data || {};

  const entries = Object.entries(h).filter(([, v]) => typeof v !== "object");

  function tone(v: any): "green" | "red" | "amber" | "slate" {
    const s = String(v).toLowerCase();
    if (["ok", "healthy", "up", "operational"].includes(s)) return "green";
    if (["down", "error", "critical"].includes(s)) return "red";
    if (["degraded", "warning"].includes(s)) return "amber";
    return "slate";
  }

  return (
    <div>
      <PageHeader title="System Health" subtitle="API, database, queue and AI providers — live" />
      <Card className="p-4">
        <div className="grid gap-2 sm:grid-cols-2">
          {entries.map(([k, v]) => (
            <div key={k} className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2 text-sm">
              <span className="capitalize text-slate-600">{k.replace(/_/g, " ")}</span>
              <StatusChip tone={tone(v)}>{String(v)}</StatusChip>
            </div>
          ))}
          {entries.length === 0 && <p className="text-sm text-slate-400">No health data.</p>}
        </div>
      </Card>
    </div>
  );
}
