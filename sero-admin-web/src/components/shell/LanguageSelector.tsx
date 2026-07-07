"use client";
import { useState } from "react";
import { Globe, Check } from "lucide-react";
import { LANGS } from "@/lib/i18n/dictionaries";
import { useI18n } from "@/lib/i18n/provider";

export function LanguageSelector() {
  const { lang, setLang } = useI18n();
  const [open, setOpen] = useState(false);
  const current = LANGS.find((l) => l.code === lang);

  return (
    <div className="relative">
      <button
        className="btn-ghost h-9"
        onClick={() => setOpen((o) => !o)}
        aria-label="Change language"
      >
        <Globe className="h-4 w-4" />
        <span className="hidden text-sm sm:inline">{current?.native}</span>
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute right-0 z-20 mt-1 w-44 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-lg">
            {LANGS.map((l) => (
              <button
                key={l.code}
                onClick={() => {
                  setLang(l.code);
                  setOpen(false);
                }}
                className="flex w-full items-center justify-between px-3 py-2 text-sm text-slate-700 hover:bg-slate-50"
              >
                <span>
                  {l.native}{" "}
                  <span className="text-xs text-slate-400">({l.label})</span>
                </span>
                {lang === l.code && <Check className="h-4 w-4 text-brand-600" />}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
