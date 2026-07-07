# MOBILE_REVAMP — UI/UX Audit

> 2026-07-07.

## 1. Design-system state vs §4 spec

Good news: `sero/lib/app/theme.dart` already defines the exact spec palette — `kPrimaryGreen #064E3B`, `kAccentGreen #10B981`, `kSlateBg #F8FAFC`, `kSlateBorder #E2E8F0` — plus a second "fresh mint" family (`#16A34A`, `#F2FBF5`, `#E4F6EC`…).

**Problem: two competing green families coexist** (Emerald spec set vs Fresh/Mint set) → screens differ in tone. Decision for Phase 4: keep spec set as canonical tokens; map mint tints to `#ECFDF5` light-green from spec; deprecate ad-hoc constants.

## 2. Issues inventory

| Area | Finding | Phase-4 action |
|---|---|---|
| Color drift | Mixed `kFreshGreen` vs `kAccentGreen` usage; some screens hardcode colors | Central `SeroColors` tokens; lint ban on raw `Color(0xFF…)` in screens |
| Deprecated APIs | ~20 `withOpacity` deprecations; `activeColor`; `onReorder` | Mechanical sweep with `.withValues()` |
| Status chips | Inconsistent complaint/visitor/payment status styling | Shared `StatusChip` widget (info/success/warn/error semantic colors from §4) |
| Empty states | Newer screens have them; older admin screens show bare lists | Shared `EmptyState(action:)` widget, enforced per §14 |
| Loading | Mix of spinners; no skeletons | `SkeletonCard`/`SkeletonList` shared widgets |
| Error surfaces | Error boundary fixed globally, but per-screen retry affordance uneven | Shared `ErrorRetryView(requestId:)` |
| Resident nav | No prominent center Pay button; Visitors buried | Restructure bottom nav per §6 |
| Staff UI | Single guard screen, utilitarian | Full gate console design (large tap targets, provider quick-select grid) |
| Typography | Mostly consistent Material 3; occasional manual sizes | Type scale tokens |
| Density | Some admin screens dense (enterprise clutter per spec) | Card-per-action layout for mobile admin, push heavy mgmt to website |

## 3. What is already decent

- Splash/brand, drawer, dashboard cards on resident home (premium UI overhaul commits).
- Material 3 usage; rounded cards widely used.
- AI assistant chat UI complete.

## 4. Phase-4 execution order (screen-by-screen)

1. Tokens + shared widgets (StatusChip, EmptyState, ErrorRetryView, Skeletons, SeroCard).
2. Resident shell + 5 tabs restructure (center Pay).
3. Resident home, payments, visitors (new flows), community.
4. Staff gate console (new).
5. Admin mobile top screens (dashboard, members, billing, ops).
6. Super-admin summary screens.
7. Deprecation sweep + `flutter analyze` back to 0 warnings.
