# Cross-Role Capability Matrix

| Role | Copilot quick-action scope added | Notes |
| --- | --- | --- |
| Resident owner/tenant | Bill explanation, rule lookup, facilities, complaint help | Finance values must come from backend aggregates. |
| Main/admin | Society summary, draft notice, SLA risks, financials | No client Firestore financial reads remain in AI chat. |
| Secretary/committee | Notice, agenda, minutes, rule lookup | Writes remain proposal/confirmation based. |
| Treasurer | Collections, ageing, expenses, reconciliation | Requires authorized finance APIs. |
| Staff/facility manager | Assigned tasks, complaint work, facilities, assets | Requires backend role-scoped task APIs. |
| Guard/security | Visitor verification, parcels, incidents, SOS | Requires visitor/security permission checks. |
| Super admin | Platform health, onboarding, revenue, audit search | Must require explicit authorized society context for private society data. |

Frontend visibility is not security. Backend authorization remains authoritative.
