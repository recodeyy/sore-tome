"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import * as Icons from "lucide-react";
import clsx from "clsx";
import { filterNavByRole, navForPortal } from "@/lib/nav";
import { useI18n } from "@/lib/i18n/provider";
import type { SessionUser } from "@/lib/session";

function Icon({ name, className }: { name: string; className?: string }) {
  const C = (Icons as any)[name] || Icons.Circle;
  return <C className={className} />;
}

export function Sidebar({ user }: { user: SessionUser }) {
  const pathname = usePathname();
  const { t } = useI18n();
  const groups = filterNavByRole(navForPortal(user.portal), user.role);

  return (
    <aside className="hidden w-64 shrink-0 flex-col border-r border-slate-200 bg-white lg:flex">
      <div className="flex h-16 items-center gap-2 border-b border-slate-200 px-5">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-600 text-white">
          <Icons.Building2 className="h-5 w-5" />
        </div>
        <div>
          <p className="text-sm font-bold leading-tight text-slate-900">SERO Control</p>
          <p className="text-[11px] capitalize leading-tight text-slate-400">
            {user.portal.replace("-", " ")}
          </p>
        </div>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-4">
        {groups.map((g) => (
          <div key={g.key} className="mb-5">
            <p className="mb-1.5 px-2 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
              {g.label}
            </p>
            <ul className="space-y-0.5">
              {g.items.map((it) => {
                const active =
                  pathname === it.href || pathname.startsWith(it.href + "/");
                return (
                  <li key={it.key}>
                    <Link
                      href={it.href}
                      className={clsx(
                        "flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm font-medium transition",
                        active
                          ? "bg-brand-50 text-brand-700"
                          : "text-slate-600 hover:bg-slate-100"
                      )}
                    >
                      <Icon name={it.icon} className="h-[18px] w-[18px]" />
                      {t(it.label)}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      <div className="border-t border-slate-200 p-3 text-[11px] text-slate-400">
        Society: <span className="font-medium text-slate-600">{user.society_id || "platform"}</span>
      </div>
    </aside>
  );
}
