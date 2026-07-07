# MOBILE_REVAMP — Cross-Role Gap Report

> 2026-07-07. Gap = spec (§5–§9, §17 journeys) vs verified current behavior.

## Journey-by-journey status (maps to §17 E2E list)

| # | Journey | Backend | Mobile | Push | Gap owner |
|---|---|---|---|---|---|
| 1 | Resident onboarding → admin approval → unlock | ⚠️ members/approval tables exist; no join-request API for "search society → pick flat → request" | ❌ no onboarding screens | ❌ | **Build both** (Phase 2/4) |
| 2 | Bill → pay (Razorpay test) → receipt | ✅ create-order/verify routes; invoices live | ⚠️ payment screens exist; E2E unproven | ❌ payment result push | Phase 5 |
| 3 | Notice publish → resident push → deep link | ✅ notices-v2 live both roles | ✅ list/detail | ❌ (P0 token bug) | Phase 3 |
| 4 | Guard visitor request → resident approve → entry/exit | ✅ `/visitors` state machine + `/guard/visitors` | ⚠️ guard single screen; resident approval card exists; provider quick-select (Swiggy/Zomato/BigBasket/Blinkit/Zepto/courier/cab) missing | ❌ | Phase 2/3/4 |
| 5 | Resident pre-invite → gate expected list → QR entry | ⚠️ pass/QR model unclear in backend | ❌ invite-visitor UI missing QR/OTP pass | ❌ | Phase 2/4 |
| 6 | Domestic help check-in/out → notifications | ⚠️ staff/domestic-help partial in backend | ❌ resident domestic-help mgmt UI missing | ❌ | Phase 2/4 |
| 7 | Complaint → assign → staff update → resident sees | ✅ (minus C-02 uuid 500 on staff assign) | ⚠️ resident+admin OK; staff task screen missing | ❌ | Phase 2 |
| 8 | Parking allocation → resident sees slot | ⚠️ `/parking/my` works; `/parking/allocations` 404 | ✅ resident My Parking (June-30) | ❌ | Phase 2 |
| 9 | Poll create → vote once → results | ✅ polls-v2 live | ⚠️ one legacy vote path | ❌ | Phase 2 |
| 10 | Amenity book → admin sees → double-book blocked | ✅ amenities module (eligibility/pricing/blackouts in src/modules) | ⚠️ booking UI exists; conflict UX unproven | ❌ | Phase 7 verify |
| 11 | SOS → staff ack → status updates | ⚠️ backend security/incidents module exists | ❌ resident SOS button + staff ack UI missing | ❌ | Phase 2/4 |
| 12 | AI answers society question with citation | ✅ `/ai/chat` + tools | ✅ shared ai_chat screens | n/a | verify Phase 7 |

## Shell/tab conformance (§6)

| Role | Spec tabs | Current | Gap |
|---|---|---|---|
| Resident | Home, Community, **Pay (center)**, Visitors, More | Home, Community, Amenities, Payments, Profile | Restructure: center Pay FAB, Visitors tab, move Amenities under Community/More |
| Staff | Home, Gate, Tasks, Security, More | Security, Assistant, Profile | Major build-out |
| Admin | Dashboard, Members, Billing, Operations, More | full drawer/tab set (80 screens) | Mostly present; conform tab naming |
| Super Admin | Platform, Societies, Revenue, Support, More | 19 screens | Verify per-tab wiring |

## Cross-role data visibility

- Admin actions → resident: notices/polls/events/invoices propagate via shared PG tables ✅ (verified same rows from both tokens). Realtime nudge missing without push (Phase 3).
- Staff actions → resident/admin: gate events propagate to `/visitors` ✅; no notification ❌.
- Isolation: RLS + tenant middleware in place; Society-B seed exists for leak tests (extend in Phase 6).
