"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader, Card, StatCard, StatusChip } from "@/components/ui/primitives";
import { LoadingState, ErrorState } from "@/components/ui/states";

type Metric = { key: string; label: string; value: string; trend: string };
type Health = { label: string; status: string };
type Dashboard = {
  metrics: Metric[];
  platformHealth: Health[];
  onboardingFunnel: { label: string; count: number; completionRate: number }[];
  activityTrend: { label: string; value: number }[];
};

const TONES = ["green", "amber", "red", "blue", "slate"] as const;

export default function SuperDashboard() {
  const q = useApi<{ success: boolean; data: Dashboard }>(["sa", "dashboard"], "/super-admin/dashboard");

  if (q.isLoading) return <LoadingState />;
  if (q.isError) return <ErrorState onRetry={() => q.refetch()} />;
  const d = q.data!.data;

  return (
    <div>
      <PageHeader title="Platform Dashboard" subtitle="SERO platform health & growth — live" />

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        {d.metrics.map((m, i) => (
          <StatCard key={m.key} label={m.label} value={m.value} hint={m.trend} tone={TONES[i % TONES.length]} />
        ))}
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        <Card className="p-4">
          <h2 className="mb-3 font-semibold text-slate-800">Platform Health</h2>
          <div className="space-y-2">
            {d.platformHealth.map((h) => (
              <div key={h.label} className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2 text-sm">
                <span className="text-slate-600">{h.label}</span>
                <StatusChip tone={h.status === "ok" || h.status === "healthy" ? "green" : h.status === "unknown" ? "slate" : "red"}>
                  {h.status}
                </StatusChip>
              </div>
            ))}
          </div>
        </Card>

        <Card className="p-4">
          <h2 className="mb-3 font-semibold text-slate-800">Onboarding Funnel</h2>
          <div className="space-y-3">
            {d.onboardingFunnel.map((f) => (
              <div key={f.label}>
                <div className="mb-1 flex justify-between text-sm">
                  <span className="text-slate-600">{f.label}</span>
                  <span className="font-medium text-slate-800">{f.count}</span>
                </div>
                <div className="h-2 w-full rounded-full bg-slate-100">
                  <div className="h-2 rounded-full bg-brand-500" style={{ width: `${f.completionRate}%` }} />
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
