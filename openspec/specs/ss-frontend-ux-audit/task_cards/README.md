# Task Cards: ss-frontend-ux-audit

This directory contains task cards for the 64 UI/UX issues identified in the frontend audit.

## Priority Levels

- **P0 (Blocking)**: Issues preventing core user journey completion
- **P1 (High)**: Issues significantly degrading user experience
- **P2 (Normal)**: Issues affecting quality and polish
- **P3 (Low)**: Issues for refinement and optimization

## Issue Categories

### P0: Core Interaction (5 issues)
- UX-001: Navigation feedback missing
- UX-002: Stepper non-interactive and unlabeled
- UX-003: Keyboard shortcuts macOS-only
- UX-004: Error panel not actionable
- UX-005: Upload zone unclear affordances

### P1: Experience Degradation (12 issues)
- UX-006: No global loading indicator
- UX-007: Table hover contrast too low
- UX-008: Modal lacks keyboard support
- UX-009: Select controls browser-dependent
- UX-010: Disabled buttons not visually distinct
- UX-037: Session expiry no warning
- UX-038: Form state lost on reload
- UX-039: Back button loses state
- UX-040: Network disconnection no detection
- UX-041: Multi-tab no conflict detection
- UX-056: Large files no warning
- UX-058: API no timeout

### P2: Quality Issues (30 issues)
- UX-011: Empty states lack guidance
- UX-012: Timestamps not localized
- UX-013: Animations too sparse
- UX-014: Color contrast unverified
- UX-015: No back navigation
- UX-016: i18n incomplete
- UX-017: Dark mode no system sync
- UX-018: No character counts
- UX-019: Content area too narrow (680px)
- UX-020: Table heights inconsistent
- UX-021: Truncated filenames no tooltip
- UX-022: Cell truncation no expansion
- UX-023: Stepper misaligned with content
- UX-024: Guide cards uneven heights
- UX-025: Info panels too dense
- UX-026: Upload no progress
- UX-027: File validation extension-only
- UX-028: No batch download
- UX-029: Admin jobs no pagination
- UX-030: Draft polling no timeout
- UX-031: Confirmed state hides user inputs
- UX-032: Reset leaves orphaned data
- UX-033: Admin login no remember-me
- UX-034: Retry no backoff
- UX-035: Sheet selection not persisted
- UX-036: Auto-refresh interval hidden
- UX-042: Error messages not actionable
- UX-043: No help entry point
- UX-044: No step dependency explanation
- UX-046: Step dependencies unclear

### P2: Accessibility (4 issues)
- UX-047: Keyboard navigation incomplete
- UX-048: Screen reader support missing
- UX-049: Color-blind indicators missing
- UX-050: Text sizing uses px

### P2: Responsive (2 issues)
- UX-051: No responsive breakpoints
- UX-052: Touch targets too small

### P2: Reversibility (3 issues)
- UX-053: No undo for corrections
- UX-054: Dangerous actions no confirmation
- UX-055: Post-confirmation no amendment

### P3: Polish (17 issues)
- UX-057: No skeleton screens
- UX-059: No privacy notice
- UX-060: Token storage not secure
- UX-061: Table content not copyable
- UX-062: No job sharing
- UX-063: Page titles static
- UX-064: No version info

## Backend Dependencies

The following issues require backend API changes:
- UX-026 (upload progress): chunked upload support
- UX-028 (batch download): zip endpoint
- UX-029 (pagination): API pagination params
- UX-037 (session expiry): token expiry metadata
- UX-060 (secure storage): cookie-based auth
- UX-062 (sharing): read-only share tokens

## Implementation Order

1. **Phase 1 (P0)**: Fix all 5 blocking issues first
2. **Phase 2 (P1)**: Address 12 high-priority degradation issues
3. **Phase 3 (P2-FE)**: Fix frontend-only P2 issues (no backend deps)
4. **Phase 4 (P2-BE)**: Coordinate with backend for dependent features
5. **Phase 5 (P3)**: Polish and optimization
