# SERO Admin Web — Multilingual Plan

## Approach: hybrid i18n + AI translation

- **Deterministic i18n** for navigation, actions, and shell strings (never machine-translate UI
  chrome or, critically, data values).
- **AI translation** (via the assistant) for long-form content such as drafting a notice in Hindi.

## Languages

English (`en`), Hindi (`hi`), Marathi (`mr`), Gujarati (`gu`), Kannada (`kn`) — selectable from the
top-bar language selector. Hinglish is supported in the AI assistant (input + answers).

## Implementation

- `src/lib/i18n/dictionaries.ts` — key → translation maps. `en` and `hi` are fully translated for
  nav/actions/dashboard/AI/voice strings; `mr/gu/kn` cover nav + key actions and **fall back to
  English** gracefully via `translate()` (no missing-key crashes, no empty labels).
- `src/lib/i18n/provider.tsx` — React context exposing `t(key)` and `setLang()`; preference is
  **persisted** to `localStorage` + a cookie and sets `<html lang>`.
- `src/components/shell/LanguageSelector.tsx` — dropdown in the Topbar and in Settings.

## Safety rules (do-not-break)

- **Never translate**: internal IDs, invoice/receipt numbers, unit codes, monetary amounts,
  status enums used as code values. These render from live data verbatim.
- Numbers/dates use `Intl` with `en-IN` locale formatting (grouping/currency) independent of UI
  language, so amounts stay correct and unambiguous.
- Forms and tables are not auto-translated at the DOM level (no Google-Translate widget mangling
  inputs); only labels resolve through `t()`, so form values and validation are untouched.

## Translated notice drafts

The AI assistant can draft notices/reminders in Hindi (or Hinglish). The admin reviews and edits
before publishing — translation never publishes automatically.

## Roadmap (P2/P3)

- Expand `mr/gu/kn` dictionaries to full coverage.
- Optional per-society default language stored in society settings.
- Optional server-side translation endpoint for bulk content localization.
