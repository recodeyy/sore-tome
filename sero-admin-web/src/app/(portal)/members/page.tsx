"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";
import { titleCase } from "@/lib/format";

type Member = {
  id: string;
  name: string;
  phone: string;
  email: string | null;
  status: string;
  role: string;
  unit_id: string | null;
};

export default function MembersPage() {
  return (
    <ResourceList<Member>
      title="Members & Tenants"
      subtitle="Society residents, owners and committee — live from backend"
      path="/members-v2"
      queryKey={["members"]}
      selectRows={(d) => d.members}
      rowKey={(m) => m.id}
      exportName="members"
      emptyHint="No members yet. Import residents via CSV or invite them."
      columns={[
        { header: "Name", cell: (m) => <span className="font-medium text-slate-900">{m.name}</span>, csv: (m) => m.name },
        { header: "Phone", cell: (m) => m.phone || "—", csv: (m) => m.phone },
        { header: "Email", cell: (m) => m.email || "—", csv: (m) => m.email || "" },
        { header: "Role", cell: (m) => titleCase(m.role), csv: (m) => m.role },
        {
          header: "Status",
          cell: (m) => (
            <StatusChip tone={m.status === "approved" ? "green" : m.status === "pending" ? "amber" : "slate"}>
              {m.status}
            </StatusChip>
          ),
          csv: (m) => m.status,
        },
        { header: "Unit", cell: (m) => (m.unit_id ? m.unit_id.slice(0, 8) : "—"), csv: (m) => m.unit_id || "" },
      ]}
    />
  );
}
