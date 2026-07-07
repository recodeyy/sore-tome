"use client";
import { useApi } from "@/lib/hooks";
import { PageHeader, Card } from "@/components/ui/primitives";
import { LoadingState } from "@/components/ui/states";
import { LanguageSelector } from "@/components/shell/LanguageSelector";

export default function SettingsPage() {
  const profileQ = useApi<any>(["society", "profile"], "/society/profile");
  const progressQ = useApi<any>(["society", "progress"], "/society/setup-progress");

  const profile = profileQ.data?.data || profileQ.data || {};
  const progress = progressQ.data?.data || progressQ.data || {};

  return (
    <div>
      <PageHeader title="Settings" subtitle="Society profile, setup progress and preferences" />

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="p-5">
          <h2 className="mb-3 font-semibold text-slate-800">Society Profile</h2>
          {profileQ.isLoading ? (
            <LoadingState />
          ) : (
            <dl className="space-y-2 text-sm">
              {Object.entries(profile)
                .filter(([, v]) => typeof v !== "object")
                .slice(0, 12)
                .map(([k, v]) => (
                  <div key={k} className="flex justify-between gap-4 border-b border-slate-100 py-1.5">
                    <dt className="capitalize text-slate-500">{k.replace(/_/g, " ")}</dt>
                    <dd className="text-right font-medium text-slate-800">{String(v ?? "—")}</dd>
                  </div>
                ))}
              {Object.keys(profile).length === 0 && (
                <p className="text-slate-400">No profile data.</p>
              )}
            </dl>
          )}
        </Card>

        <div className="space-y-4">
          <Card className="p-5">
            <h2 className="mb-3 font-semibold text-slate-800">Language</h2>
            <p className="mb-3 text-sm text-slate-500">
              Choose the portal language. Your preference is saved to this browser.
            </p>
            <LanguageSelector />
          </Card>

          <Card className="p-5">
            <h2 className="mb-3 font-semibold text-slate-800">Setup Progress</h2>
            {progressQ.isLoading ? (
              <p className="text-sm text-slate-400">Loading…</p>
            ) : (
              <div className="space-y-2 text-sm">
                {Object.entries(progress)
                  .filter(([, v]) => typeof v === "boolean" || typeof v === "number")
                  .map(([k, v]) => (
                    <div key={k} className="flex items-center justify-between">
                      <span className="capitalize text-slate-600">{k.replace(/_/g, " ")}</span>
                      <span className={v ? "text-brand-600" : "text-slate-400"}>
                        {typeof v === "boolean" ? (v ? "Done" : "Pending") : String(v)}
                      </span>
                    </div>
                  ))}
                {Object.keys(progress).length === 0 && <p className="text-slate-400">No data.</p>}
              </div>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}
