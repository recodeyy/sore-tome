# Cross-Role Screen And Route Map

This pass only changes the shared AI chat frontend. It does not edit app routing or shells because those files are reserved for another agent.

## Intended Route

- `/copilot`
- `/copilot/conversations`
- `/copilot/conversations/:id`

## Existing Integration Dependency

The shared route/shell integration should be done in the reserved app/navigation files by the integration owner. The screen is now prepared to receive role context through the existing `userRole` constructor and auth provider state.
