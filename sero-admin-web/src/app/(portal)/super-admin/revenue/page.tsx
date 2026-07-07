"use client";
import { useApi, num } from "@/lib/hooks";
import { PageHeader, Card, StatCard } from "@/components/ui/primitives";
import { LoadingState, ErrorState } from "@/components/ui/states";
import { formatMoneyMinor } from "@/lib/format";

export default function RevenuePage() {
  const q = useApi<any>(["sa", "revenue"], "/super-admin/revenue");
  if (q.isLoading) return <LoadingState />;
  if (q.isError) return <ErrorState onRetry={() => q.refetch()} />;
  const r = q.data?.data || q.data || {};

  const moneyKeys = Object.keys(r).filter((k) => /minor/i.test(k));
  const otherKeys = Object.keys(r).filter((k) => !/minor/i.test(k) && typeof r[k] !== "object");

  return (
    <div>
      <PageHeader title="Revenue" subtitle="Platform MRR, ARR and billing adoption — live" />
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {moneyKeys.map((k, i) => (
          <StatCard
            key={k}
            label={k.replace(/_/g, " ").replace(/minor/i, "").trim()}
            value={formatMoneyMinor(num(r[k]))}
            tone={(["green", "blue", "amber", "slate"] as const)[i % 4]}
          />
        ))}
      </div>
      {otherKeys.length > 0 && (
        <Card className="mt-4 p-4">
          <h2 className="mb-3 font-semibold text-slate-800">Adoption & Metrics</h2>
          <dl className="grid gap-2 sm:grid-cols-2">
            {otherKeys.map((k) => (
              <div key={k} className="flex justify-between border-b border-slate-100 py-1.5 text-sm">
                <dt className="capitalize text-slate-500">{k.replace(/_/g, " ")}</dt>
                <dd className="font-medium text-slate-800">{String(r[k])}</dd>
              </div>
            ))}
          </dl>
        </Card>
      )}
    </div>
  );
}
