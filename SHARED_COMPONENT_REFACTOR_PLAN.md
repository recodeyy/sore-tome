# Shared Component Refactor Plan

## Completed In This Pass

- Introduced typed Copilot models instead of keeping all state as dynamic maps.
- Moved conversation state out of the screen and into Riverpod.
- Kept existing SERO visual components and action cards.
- Added role-aware quick actions without duplicating screens by role.

## Next Frontend Steps

- Replace remaining action-card `Map<String, dynamic>` contracts with typed AI action proposal/result models.
- Add backend-backed conversation repository once endpoints are available.
- Add signed-upload provider and attachment lifecycle states.
- Persist language preference after settings/storage contract is finalized.
- Add widget tests around role quick actions, language selection, streaming state, and structured errors.
