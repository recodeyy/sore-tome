"use client";
import { useRouter } from "next/navigation";
import { LogOut, Search } from "lucide-react";
import { LanguageSelector } from "./LanguageSelector";
import { useI18n } from "@/lib/i18n/provider";
import type { SessionUser } from "@/lib/session";

export function Topbar({ user }: { user: SessionUser }) {
  const router = useRouter();
  const { t } = useI18n();

  async function logout() {
    await fetch("/api/session/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  const initials = (user.name || "U")
    .split(" ")
    .map((s) => s[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center justify-between gap-3 border-b border-slate-200 bg-white/90 px-4 backdrop-blur lg:px-6">
      <div className="relative hidden max-w-md flex-1 md:block">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
        <input className="input pl-9" placeholder={t("action.search")} />
      </div>
      <div className="flex items-center gap-2">
        <LanguageSelector />
        <div className="flex items-center gap-2 rounded-lg px-2 py-1">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700">
            {initials}
          </div>
          <div className="hidden text-right sm:block">
            <p className="text-sm font-medium leading-tight text-slate-800">{user.name}</p>
            <p className="text-[11px] capitalize leading-tight text-slate-400">
              {user.role?.replace(/_/g, " ")}
            </p>
          </div>
        </div>
        <button className="btn-ghost h-9" onClick={logout} title={t("action.logout")}>
          <LogOut className="h-4 w-4" />
        </button>
      </div>
    </header>
  );
}
