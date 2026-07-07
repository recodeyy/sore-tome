"use client";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { AlertTriangle, ArrowRight } from "lucide-react";
import Link from "next/link";
import { useApi, num } from "@/lib/hooks";
import { useI18n } from "@/lib/i18n/provider";
import { StatCard, PageHeader, Card } from "@/components/ui/primitives";
import { LoadingState, ErrorState } from "@/components/ui/states";
import { formatMoneyMinor, formatDateTime } from "@/lib/format";

type Summary = {
  pendingApprovals: number;
  openComplaints: number;
  todaysCollectionMinor: number;
  maintenanceDueMinor: number;
  visitorsToday: number;
  staffOnDuty: number;
};
type Envelope<T> = { success: boolean; data: T };
type Alert = { type: string; severity: string; message: string; count: number };
type Activity = { items: { type: string; id: string; title: string; at: string }[] };
type Dues = { buckets: Record<string, number>; totalOutstandingMinor: number };

const SEVERITY_TONE: Record<string, string> = {
  high: "text-red-600 bg-red-50",
  medium: "text-amber-600 bg-amber-50",
  low: "text-blue-600 bg-blue-50",
};
const BUCKET_COLORS = ["#10b981", "#f59e0b", "#f97316", "#ef4444"];

export default function DashboardPage() {
  const { t } = useI18n();
  const summary = useApi<Envelope<Summary>>(["dash", "summary"], "/admin/dashboard/summary");
  const alerts = useApi<Envelope<Alert[]>>(["dash", "alerts"], "/admin/dashboard/alerts");
  const activity = useApi<Envelope<Activity>>(["dash", "activity"], "/admin/dashboard/activity");
  const dues = useApi<Dues>(["finance", "dues"], "/finance/reports/dues");

  if (summary.isLoading) return <LoadingState label={t("state.loading")} />;
  if (summary.isError)
    return <ErrorState message={t("state.error")} onRetry={() => summary.refetch()} />;

  const s = summary.data!.data;
  const bucketData = dues.data
    ? Object.entries(dues.data.buckets).map(([k, v]) => ({ name: k, value: num(v) / 100 }))
    : [];

  return (
    <div>
      <PageHeader
        title={t("nav.dashboard")}
        subtitle="Live society operations at a glance"
      />

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        <StatCard
          label={t("dash.collectionToday")}
          value={formatMoneyMinor(s.todaysCollectionMinor)}
          tone="green"
        />
        <StatCard
          label={t("dash.outstanding")}
          value={formatMoneyMinor(s.maintenanceDueMinor)}
          tone="amber"
        />
        <StatCard label={t("dash.openComplaints")} value={String(s.openComplaints)} tone="red" />
        <StatCard
          label={t("dash.pendingApprovals")}
          value={String(s.pendingApprovals)}
          tone="blue"
        />
        <StatCard label={t("dash.visitorsToday")} value={String(s.visitorsToday)} tone="slate" />
        <StatCard label={t("dash.staffOnDuty")} value={String(s.staffOnDuty)} tone="green" />
      </div>

      <div className="mt-5 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="p-4 lg:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="font-semibold text-slate-800">Dues Ageing</h2>
            <Link href="/reports" className="flex items-center gap-1 text-xs text-brand-600">
              Reports <ArrowRight className="h-3 w-3" />
            </Link>
          </div>
          {bucketData.length === 0 || dues.data?.totalOutstandingMinor === 0 ? (
            <p className="py-10 text-center text-sm text-slate-400">No outstanding dues</p>
          ) : (
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={bucketData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip formatter={(v: number) => `₹${v.toLocaleString("en-IN")}`} />
                <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                  {bucketData.map((_, i) => (
                    <Cell key={i} fill={BUCKET_COLORS[i % BUCKET_COLORS.length]} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </Card>

        <Card className="p-4">
          <h2 className="mb-3 font-semibold text-slate-800">Alerts</h2>
          <div className="space-y-2">
            {(alerts.data?.data || []).length === 0 && (
              <p className="py-6 text-center text-sm text-slate-400">All clear</p>
            )}
            {(alerts.data?.data || []).map((a, i) => (
              <div
                key={i}
                className={`flex items-start gap-2 rounded-lg px-3 py-2 text-sm ${
                  SEVERITY_TONE[a.severity] || "bg-slate-50 text-slate-600"
                }`}
              >
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                <span>{a.message}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      <Card className="mt-4 p-4">
        <h2 className="mb-3 font-semibold text-slate-800">Recent Activity</h2>
        <ul className="divide-y divide-slate-100">
          {(activity.data?.data.items || []).slice(0, 10).map((it) => (
            <li key={it.id} className="flex items-center justify-between py-2 text-sm">
              <span className="text-slate-700">{it.title}</span>
              <span className="text-xs text-slate-400">{formatDateTime(it.at)}</span>
            </li>
          ))}
          {(activity.data?.data.items || []).length === 0 && (
            <li className="py-6 text-center text-sm text-slate-400">{t("state.empty")}</li>
          )}
        </ul>
      </Card>
    </div>
  );
}
