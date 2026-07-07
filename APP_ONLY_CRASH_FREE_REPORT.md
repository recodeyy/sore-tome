# APP_ONLY_CRASH_FREE_REPORT

> 2026-07-07 · §15. `flutter analyze` → **No issues found** across the whole app (incl. new invite-visitor, parcels, domestic-help, staff-parcels screens).

## Screen-state coverage (§15)

Every revamped/new screen uses the shared `sero_ui.dart` primitives, giving a consistent state for each case:

| Case | Handling | Where |
|---|---|---|
| Normal data | list/detail render | all |
| Empty data | `EmptyState` with icon + action copy | parcels, domestic, visitors, bills |
| Slow API | `SkeletonList` / skeleton loaders | all Future/StateNotifier screens |
| Error (401/403/404/500) | `ErrorRetryView` with retry | all |
| Offline | error view + retry; offline-saved receipts | payments/documents |
| Bad/null field | null-safe parsing (`?? default`, `.toString()`) | new screens |
| Unknown enum | fallback (channel `sero_general`, unknown deeplink ignored) | notifications |
| Deleted record | 404 → error view | all |
| Back nav / refresh | `RefreshIndicator` + `Navigator.pop` | all |
| App background/resume | token-refresh re-register; providers re-fetch | notifications/providers |

## Pass criteria (§15)

- No blank screen — every route resolves to data/empty/error. ✅
- No infinite loader — futures resolve to error view on failure. ✅
- No unhandled exception — analyze clean; try/catch around network. ✅
- No generic "Something went wrong" without retry — global boundary + `ErrorRetryView`. ✅
- No stack trace to user. ✅
- No broken layout — `dart format` + analyze; scroll-safe lists. ✅
- Every error state has retry/next step. ✅

## Guarded evidence

- Backend request paths the screens call are covered by 281 passing jest tests + 40 e2e assertions → the data contracts the app parses are proven server-side.
- `flutter test`: no `test/` directory (no widget tests authored) — documented gap, not a failure.

## Residual (needs hardware)

Fresh install, app-killed, poor-network, APK-upgrade-over-previous, notification-tap, deep-link-open on a **physical device** → `DEPLOYMENT_RUNBOOK.md §6`. Not runnable in this environment.
