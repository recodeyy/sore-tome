"use client";
import { Sparkles, ShieldCheck, Globe, Volume2 } from "lucide-react";
import { PageHeader, Card } from "@/components/ui/primitives";

const ADMIN_PROMPTS = [
  "Generate maintenance dues summary for A Wing.",
  "Which flats have unpaid bills?",
  "Draft a dues reminder in Hindi.",
  "Summarize complaints this week.",
  "Create a notice for water shutdown tomorrow.",
  "Find residents who have not acknowledged the notice.",
  "Explain why collection dropped this month.",
  "Prepare an AGM agenda.",
];

export default function AIPage() {
  return (
    <div>
      <PageHeader
        title="AI Assistant"
        subtitle="Society-aware, role-scoped, multilingual — with human confirmation on writes"
      />

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="p-5 lg:col-span-2">
          <div className="mb-3 flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-brand-600" />
            <h2 className="font-semibold text-slate-800">Try asking</h2>
          </div>
          <p className="mb-3 text-sm text-slate-500">
            Open the assistant from the green button at the bottom-right of any page and paste one of
            these. Answers are grounded in this society&apos;s live data and respect your role.
          </p>
          <div className="grid gap-2 sm:grid-cols-2">
            {ADMIN_PROMPTS.map((p) => (
              <div key={p} className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600">
                {p}
              </div>
            ))}
          </div>
        </Card>

        <div className="space-y-4">
          <Card className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <ShieldCheck className="h-5 w-5 text-brand-600" />
              <h3 className="font-semibold text-slate-800">Safe by design</h3>
            </div>
            <ul className="space-y-1.5 text-sm text-slate-600">
              <li>• Keys stay server-side (backend + BFF proxy)</li>
              <li>• Role &amp; tenant scoping enforced by backend</li>
              <li>• High-impact actions require confirmation</li>
              <li>• Prompt-injection guardrails on tool calls</li>
            </ul>
          </Card>
          <Card className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <Volume2 className="h-5 w-5 text-brand-600" />
              <h3 className="font-semibold text-slate-800">Voice (ElevenLabs)</h3>
            </div>
            <p className="text-sm text-slate-600">
              Tap <b>Read aloud</b> under any reply. Audio is streamed via a secure server proxy and
              not stored.
            </p>
          </Card>
          <Card className="p-4">
            <div className="mb-2 flex items-center gap-2">
              <Globe className="h-5 w-5 text-brand-600" />
              <h3 className="font-semibold text-slate-800">Multilingual</h3>
            </div>
            <p className="text-sm text-slate-600">
              Ask in English, Hindi or Hinglish. UI language is switchable from the top bar.
            </p>
          </Card>
        </div>
      </div>
    </div>
  );
}
