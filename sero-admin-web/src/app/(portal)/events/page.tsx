"use client";
import { ResourceList } from "@/components/data/ResourceList";
import { StatusChip } from "@/components/ui/primitives";
import { formatDateTime } from "@/lib/format";

type Event = {
  id: string;
  title: string;
  location: string | null;
  starts_at: string;
  ends_at: string | null;
  capacity: number | null;
  status: string;
};

export default function EventsPage() {
  return (
    <ResourceList<Event>
      title="Events"
      subtitle="Community events & RSVP — live"
      path="/events-v2"
      queryKey={["events"]}
      selectRows={(d) => d.events}
      rowKey={(e) => e.id}
      exportName="events"
      emptyHint="No events yet."
      columns={[
        { header: "Title", cell: (e) => <span className="font-medium text-slate-900">{e.title}</span>, csv: (e) => e.title },
        { header: "Location", cell: (e) => e.location || "—", csv: (e) => e.location || "" },
        { header: "Starts", cell: (e) => formatDateTime(e.starts_at), csv: (e) => formatDateTime(e.starts_at) },
        { header: "Capacity", cell: (e) => e.capacity ?? "—", csv: (e) => e.capacity ?? "" },
        { header: "Status", cell: (e) => <StatusChip tone={e.status === "published" ? "green" : "slate"}>{e.status}</StatusChip>, csv: (e) => e.status },
      ]}
    />
  );
}
