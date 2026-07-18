"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";

type Amenity = {
  id: string;
  name: string;
  capacity: number;
  is_active: boolean;
  created_at: string;
};

export default function AmenitiesPage() {
  return (
    <ResourceList<Amenity>
      title="Amenities"
      subtitle="Bookable facilities & capacity — live"
      path="/amenities"
      queryKey={["amenities"]}
      selectRows={(d) => d.amenities}
      rowKey={(a) => a.id}
      exportName="amenities"
      emptyHint="No amenities configured yet."
      columns={[
        { header: "Name", cell: (a) => <span className="font-medium">{a.name}</span>, csv: (a) => a.name },
        { header: "Capacity", cell: (a) => a.capacity, csv: (a) => String(a.capacity) },
        {
          header: "Status",
          cell: (a) => <StatusChip tone={a.is_active ? "green" : "slate"}>{a.is_active ? "Active" : "Inactive"}</StatusChip>,
          csv: (a) => (a.is_active ? "active" : "inactive"),
        },
      ]}
    />
  );
}
