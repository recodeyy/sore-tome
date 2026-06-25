# LIVE_DATA_COMPONENT_INVENTORY

Shared widgets rendering operational values on admin screens (data passed in by parent screen — must originate from live provider). Widgets themselves carry no mock data; they are dumb presenters.

| Component | Used by | Live data prop source |
|---|---|---|
| MainSummaryCard | parking/assets/finance/staff dashboards | provider summary value + subStats |
| StatCard | most dashboards (KPI tiles) | provider counts |
| DonutChart / MiniChart | parking, finance, assets, complaints | provider numeric series (empty list → empty chart, no static series) |
| SectionHeader | all | static label (allowed) |
| StatusBadge | parking, complaints, staff | provider status string |
| ProgressBar / setup steps | society_setup_home | setup-progress endpoint |

No decorative operational chart remains: charts now receive provider-derived values; when empty they render zero/empty, never hard-coded series. Static content limited to labels, icons, enum dropdowns, empty-state copy (spec 1.3).
