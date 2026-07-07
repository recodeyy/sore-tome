"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";
import { titleCase } from "@/lib/format";

type Slot = {
  id: string;
  code: string;
  type: string;
  location: string | null;
  is_ev: boolean;
  is_reserved: boolean;
  status: string;
};

export default function ParkingPage() {
  return (
    <ResourceList<Slot>
      title="Parking"
      subtitle="Slot inventory & allocation — live"
      path="/parking/slots"
      queryKey={["parking", "slots"]}
      selectRows={(d) => d.slots}
      rowKey={(s) => s.id}
      exportName="parking-allocation"
      emptyHint="No parking slots defined yet."
      columns={[
        { header: "Code", cell: (s) => <span className="font-mono text-sm font-medium">{s.code}</span>, csv: (s) => s.code },
        { header: "Type", cell: (s) => titleCase(s.type), csv: (s) => s.type },
        { header: "Location", cell: (s) => s.location || "—", csv: (s) => s.location || "" },
        { header: "EV", cell: (s) => (s.is_ev ? "⚡ Yes" : "No"), csv: (s) => (s.is_ev ? "Yes" : "No") },
        { header: "Reserved", cell: (s) => (s.is_reserved ? "Yes" : "No"), csv: (s) => (s.is_reserved ? "Yes" : "No") },
        {
          header: "Status",
          cell: (s) => <StatusChip tone={s.status === "available" ? "green" : s.status === "occupied" ? "amber" : "slate"}>{s.status}</StatusChip>,
          csv: (s) => s.status,
        },
      ]}
    />
  );
}
