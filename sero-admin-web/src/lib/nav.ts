// Role-based navigation model. The sidebar renders only permitted modules, but
// the backend is the real authority — every endpoint re-checks role/tenant.
export type NavItem = {
  key: string;
  label: string; // i18n key OR fallback label
  href: string;
  icon: string; // lucide-react icon name
  roles?: string[]; // if set, only these normalized roles see it
};

export type NavGroup = {
  key: string;
  label: string;
  items: NavItem[];
};

export function normalizeRole(role: string | null | undefined): string {
  return (role || "").trim().toLowerCase().replace(/[-\s]+/g, "_");
}

export const FINANCE_ROLES = ["main_admin", "admin", "treasurer"];
export const COMMS_ROLES = ["main_admin", "admin", "secretary", "committee_member"];
export const SECURITY_ROLES = [
  "main_admin",
  "admin",
  "security_manager",
  "facility_manager",
];

// ─── Society Admin portal ──────────────────────────────────────────────────────
export const ADMIN_NAV: NavGroup[] = [
  {
    key: "overview",
    label: "Overview",
    items: [
      { key: "dashboard", label: "nav.dashboard", href: "/dashboard", icon: "LayoutDashboard" },
      { key: "members", label: "nav.members", href: "/members", icon: "Users" },
      { key: "approvals", label: "nav.approvals", href: "/approvals", icon: "UserCheck" },
    ],
  },
  {
    key: "finance",
    label: "Finance",
    items: [
      { key: "billing", label: "nav.billing", href: "/billing", icon: "FileText", roles: FINANCE_ROLES },
      { key: "payments", label: "nav.payments", href: "/payments", icon: "CreditCard", roles: FINANCE_ROLES },
      { key: "reconciliation", label: "nav.reconciliation", href: "/reconciliation", icon: "Banknote", roles: FINANCE_ROLES },
      { key: "expenses", label: "nav.expenses", href: "/expenses", icon: "Receipt", roles: FINANCE_ROLES },
      { key: "reports", label: "nav.reports", href: "/reports", icon: "BarChart3", roles: FINANCE_ROLES },
    ],
  },
  {
    key: "community",
    label: "Community & Governance",
    items: [
      { key: "notices", label: "nav.notices", href: "/notices", icon: "Megaphone", roles: COMMS_ROLES },
      { key: "polls", label: "nav.polls", href: "/polls", icon: "Vote", roles: COMMS_ROLES },
      { key: "events", label: "nav.events", href: "/events", icon: "Calendar", roles: COMMS_ROLES },
      { key: "complaints", label: "nav.complaints", href: "/complaints", icon: "MessageSquareWarning" },
    ],
  },
  {
    key: "operations",
    label: "Operations",
    items: [
      { key: "staff", label: "nav.staff", href: "/staff", icon: "UserCog", roles: SECURITY_ROLES },
      { key: "visitors", label: "nav.visitors", href: "/visitors", icon: "DoorOpen", roles: SECURITY_ROLES },
      { key: "parking", label: "nav.parking", href: "/parking", icon: "SquareParking", roles: SECURITY_ROLES },
      { key: "assets", label: "nav.assets", href: "/assets", icon: "Wrench", roles: SECURITY_ROLES },
    ],
  },
  {
    key: "system",
    label: "System",
    items: [
      { key: "ai", label: "nav.ai", href: "/ai", icon: "Sparkles" },
      { key: "settings", label: "nav.settings", href: "/settings", icon: "Settings" },
    ],
  },
];

// ─── Super Admin portal ─────────────────────────────────────────────────────────
export const SUPER_ADMIN_NAV: NavGroup[] = [
  {
    key: "platform",
    label: "Platform",
    items: [
      { key: "sa-dashboard", label: "nav.platformDashboard", href: "/super-admin/dashboard", icon: "LayoutDashboard" },
      { key: "sa-societies", label: "nav.societies", href: "/super-admin/societies", icon: "Building2" },
      { key: "sa-applications", label: "nav.approvals", href: "/super-admin/applications", icon: "ClipboardCheck" },
      { key: "sa-revenue", label: "nav.revenue", href: "/super-admin/revenue", icon: "TrendingUp" },
      { key: "sa-support", label: "nav.support", href: "/super-admin/support", icon: "LifeBuoy" },
      { key: "sa-announcements", label: "nav.announcements", href: "/super-admin/announcements", icon: "Megaphone" },
      { key: "sa-health", label: "nav.systemHealth", href: "/super-admin/health", icon: "Activity" },
      { key: "sa-audit", label: "nav.auditLogs", href: "/super-admin/audit", icon: "ScrollText" },
    ],
  },
];

export function navForPortal(portal: string): NavGroup[] {
  return portal === "super-admin" ? SUPER_ADMIN_NAV : ADMIN_NAV;
}

export function filterNavByRole(groups: NavGroup[], role: string): NavGroup[] {
  const r = normalizeRole(role);
  // Super admin sees everything in its portal.
  const isSuper = r === "super_admin" || r === "superadmin";
  return groups
    .map((g) => ({
      ...g,
      items: g.items.filter((it) => {
        if (isSuper) return true;
        if (!it.roles) return true;
        return it.roles.map(normalizeRole).includes(r);
      }),
    }))
    .filter((g) => g.items.length > 0);
}
