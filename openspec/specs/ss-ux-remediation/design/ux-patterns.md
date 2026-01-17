# Design: UX patterns (ss-ux-remediation)

This document defines consistent UX patterns for SS so task cards can reference shared behavior instead of re-inventing it per page.

## Loading & waiting

- **Immediate feedback**: Any user action should show an immediate visual response (pressed/active/loading) within 100ms.
- **Global busy indicator**: Show when a request exceeds ~300ms.
- **Progress where possible**: uploads show progress; long-running operations show a bounded polling UI.
- **Bounded polling**: polling must have max retries/timeout and a clear “what next” CTA.

## Errors (actionable)

- Errors are shown as: `错误代号 EXXXX：<friendly text>` with a short hint.
- Always show `request_id` and make it copyable.
- Provide actions: retry / re-auth / go back to start / download logs (as applicable).
- Technical details are collapsible; do not block the main flow.

## Confirmations & undo/recovery

- Destructive actions (reset/redeem-again/clear) require confirmation and explain what will be lost.
- After confirm, the UI enters a locked read-only state and surfaces how to view history.
- Prefer recovery over undo when undo is unsafe (e.g., job execution already queued).

## Truncation, tooltips, and copy

- Any ellipsis truncation must provide the full value via tooltip/popover.
- Tables must allow selection/copy of cell content and column names.

## Keyboard & accessibility baseline

- Modal: Escape closes; focus is trapped; tab order is logical.
- Focus is visible in both light/dark themes.
- Avoid color-only signals; include text/icon.

## i18n and localization

- All user-visible strings go through i18n.
- Shortcut hints are platform-aware (mac=⌘, win/linux=Ctrl).
- Time is localized for Chinese users with explicit timezone strategy.

