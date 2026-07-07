"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";
import { titleCase, formatMoneyMinor } from "@/lib/format";
import { num } from "@/lib/hooks";

type Staff = {
  id: string;
  name: string;
  role: string;
  department: string | null;
  phone: string;
  status: string;
  monthly_wage_minor: string | number;
  assigned_areas: string[] | null;
};

export default function StaffPage() {
  return (
    <ResourceList<Staff>
      title="Staff & Vendors"
      subtitle="Roster, roles and payroll base — live"
      path="/staff-v2"
      queryKey={["staff"]}
      selectRows={(d) => d.staff}
      rowKey={(s) => s.id}
      exportName="staff-register"
      emptyHint="No staff added yet."
      columns={[
        { header: "Name", cell: (s) => <span className="font-medium text-slate-900">{s.name}</span>, csv: (s) => s.name },
        { header: "Role", cell: (s) => titleCase(s.role), csv: (s) => s.role },
        { header: "Department", cell: (s) => titleCase(s.department || ""), csv: (s) => s.department || "" },
        { header: "Phone", cell: (s) => s.phone || "—", csv: (s) => s.phone },
        { header: "Areas", cell: (s) => (s.assigned_areas || []).join(", ") || "—", csv: (s) => (s.assigned_areas || []).join("; ") },
        { header: "Wage", align: "right", cell: (s) => formatMoneyMinor(num(s.monthly_wage_minor)), csv: (s) => (num(s.monthly_wage_minor) / 100).toFixed(2) },
        { header: "Status", cell: (s) => <StatusChip tone={s.status === "active" ? "green" : "slate"}>{s.status}</StatusChip>, csv: (s) => s.status },
      ]}
    />
  );
}
