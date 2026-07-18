"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";
import { formatDateTime, titleCase } from "@/lib/format";

type Parcel = {
  id: string;
  unit_id: string | null;
  recipient_name: string | null;
  courier: string;
  tracking_code: string | null;
  description: string | null;
  status: string; // pending | collected | returned
  created_at: string;
  collected_at: string | null;
};

const STATUS_TONE: Record<string, "green" | "amber" | "slate" | "red"> = {
  pending: "amber",
  collected: "green",
  returned: "slate",
};

export default function ParcelsPage() {
  return (
    <ResourceList<Parcel>
      title="Parcels"
      subtitle="Gate deliveries logged by guards — live"
      path="/parcels"
      queryKey={["parcels"]}
      selectRows={(d) => d.parcels}
      rowKey={(p) => p.id}
      exportName="parcel-register"
      emptyHint="No parcels logged yet. Guards log deliveries from the gate console in the app."
      columns={[
        { header: "Courier", cell: (p) => <span className="font-medium">{p.courier}</span>, csv: (p) => p.courier },
        { header: "Recipient", cell: (p) => p.recipient_name || "—", csv: (p) => p.recipient_name || "" },
        {
          header: "Unit",
          cell: (p) => (p.unit_id ? <span className="font-mono text-xs">{p.unit_id.slice(0, 8)}</span> : "—"),
          csv: (p) => p.unit_id || "",
        },
        { header: "Tracking", cell: (p) => p.tracking_code || "—", csv: (p) => p.tracking_code || "" },
        {
          header: "Status",
          cell: (p) => <StatusChip tone={STATUS_TONE[p.status] || "slate"}>{titleCase(p.status)}</StatusChip>,
          csv: (p) => p.status,
        },
        { header: "Logged", cell: (p) => formatDateTime(p.created_at), csv: (p) => formatDateTime(p.created_at) },
        {
          header: "Collected",
          cell: (p) => (p.collected_at ? formatDateTime(p.collected_at) : "—"),
          csv: (p) => (p.collected_at ? formatDateTime(p.collected_at) : ""),
        },
      ]}
    />
  );
}
