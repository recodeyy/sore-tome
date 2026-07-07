"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";
import { titleCase } from "@/lib/format";

type Asset = {
  id: string;
  name: string;
  category?: string | null;
  type?: string | null;
  location?: string | null;
  status?: string | null;
};

export default function AssetsPage() {
  return (
    <ResourceList<Asset>
      title="Assets & Maintenance"
      subtitle="Lifts, pumps, generators, CCTV and service schedules — live"
      path="/assets"
      queryKey={["assets"]}
      selectRows={(d) => d.assets || d.items || d}
      rowKey={(a) => a.id}
      exportName="asset-register"
      emptyHint="No assets registered yet."
      columns={[
        { header: "Asset", cell: (a) => <span className="font-medium text-slate-900">{a.name}</span>, csv: (a) => a.name },
        { header: "Category", cell: (a) => titleCase(a.category || a.type || ""), csv: (a) => a.category || a.type || "" },
        { header: "Location", cell: (a) => a.location || "—", csv: (a) => a.location || "" },
        {
          header: "Status",
          cell: (a) => <StatusChip tone={a.status === "operational" || a.status === "active" ? "green" : "amber"}>{a.status || "—"}</StatusChip>,
          csv: (a) => a.status || "",
        },
      ]}
    />
  );
}
