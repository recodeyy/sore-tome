"use client";
import { useState } from "react";
import { Banknote, Upload, Wand2 } from "lucide-react";
import { api } from "@/lib/api-client";
import { useApiMutation } from "@/lib/hooks";
import { useToast } from "@/components/ui/toast";
import { PageHeader, Card, StatCard } from "@/components/ui/primitives";

// Bank reconciliation demo flow: create account -> import statement lines (CSV
// paste) -> auto-match against captured payments -> show summary. All live.
export default function ReconciliationPage() {
  const { push } = useToast();
  const [accountName, setAccountName] = useState("Society Current A/C");
  const [accountId, setAccountId] = useState<string | null>(null);
  const [importId, setImportId] = useState<string | null>(null);
  const [csv, setCsv] = useState("2026-07-01, 5310.00, INV-SK-001 UPI, UTR12345\n2026-07-02, 5310.00, INV-SK-002 NEFT, UTR12346");
  const [summary, setSummary] = useState<{ processed: number; matched: number; unmatched: number } | null>(null);

  const createAccount = useApiMutation("post");
  const importStmt = useApiMutation("post");

  function parseCsv() {
    return csv
      .split("\n")
      .map((l) => l.trim())
      .filter(Boolean)
      .map((l) => {
        const [txnDate, amount, description, reference] = l.split(",").map((s) => s.trim());
        return {
          txnDate,
          amountMinor: Math.round(Number(amount) * 100),
          description,
          reference,
        };
      });
  }

  return (
    <div>
      <PageHeader title="Bank Reconciliation" subtitle="Import statements and auto-match to resident bills — live" />

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="p-4">
          <div className="mb-3 flex items-center gap-2">
            <Banknote className="h-5 w-5 text-brand-600" />
            <h2 className="font-semibold text-slate-800">1 · Bank Account</h2>
          </div>
          <div className="flex gap-2">
            <input className="input" value={accountName} onChange={(e) => setAccountName(e.target.value)} />
            <button
              className="btn-primary shrink-0"
              disabled={createAccount.isPending}
              onClick={() =>
                createAccount.mutate(
                  { path: "/finance/reconciliation/accounts", body: { name: accountName } },
                  {
                    onSuccess: (r: any) => {
                      setAccountId(r?.id || r?.data?.id);
                      push("success", "Bank account created");
                    },
                    onError: (e) => push("error", e.message),
                  }
                )
              }
            >
              Create
            </button>
          </div>
          {accountId && <p className="mt-2 text-xs text-brand-600">Account ready: {accountId.slice(0, 8)}…</p>}
        </Card>

        <Card className="p-4">
          <div className="mb-3 flex items-center gap-2">
            <Upload className="h-5 w-5 text-brand-600" />
            <h2 className="font-semibold text-slate-800">2 · Import Statement (CSV)</h2>
          </div>
          <textarea
            className="input h-24 resize-none font-mono text-xs"
            value={csv}
            onChange={(e) => setCsv(e.target.value)}
            placeholder="date, amount, description, reference"
          />
          <button
            className="btn-outline mt-2"
            disabled={importStmt.isPending}
            onClick={() =>
              importStmt.mutate(
                {
                  path: "/finance/reconciliation/imports",
                  body: { bankAccountId: accountId || undefined, filename: "web-upload.csv", lines: parseCsv() },
                },
                {
                  onSuccess: (r: any) => {
                    setImportId(r?.id || r?.data?.id);
                    push("success", "Statement imported");
                  },
                  onError: (e) => push("error", e.message),
                }
              )
            }
          >
            <Upload className="h-4 w-4" /> Import {parseCsv().length} lines
          </button>
          {importId && <p className="mt-2 text-xs text-brand-600">Import ready: {importId.slice(0, 8)}…</p>}
        </Card>
      </div>

      <Card className="mt-4 p-4">
        <div className="mb-3 flex items-center gap-2">
          <Wand2 className="h-5 w-5 text-brand-600" />
          <h2 className="font-semibold text-slate-800">3 · Auto-match & Summary</h2>
        </div>
        <button
          className="btn-primary"
          disabled={!importId}
          onClick={async () => {
            try {
              await api.post(`/finance/reconciliation/imports/${importId}/auto-match`);
              const s = await api.get<any>(`/finance/reconciliation/imports/${importId}/summary`);
              setSummary(s?.data || s);
              push("success", "Auto-match complete");
            } catch (e: any) {
              push("error", e.message);
            }
          }}
        >
          <Wand2 className="h-4 w-4" /> Run Auto-match
        </button>
        {summary && (
          <div className="mt-4 grid grid-cols-3 gap-3">
            <StatCard label="Processed" value={String(summary.processed ?? 0)} tone="blue" />
            <StatCard label="Matched" value={String(summary.matched ?? 0)} tone="green" />
            <StatCard label="Unmatched" value={String(summary.unmatched ?? 0)} tone="amber" />
          </div>
        )}
        {!importId && <p className="mt-2 text-xs text-slate-400">Complete steps 1 and 2 first.</p>}
      </Card>
    </div>
  );
}
