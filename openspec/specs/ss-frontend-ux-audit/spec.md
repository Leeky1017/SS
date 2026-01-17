# Spec: ss-frontend-ux-audit

## Purpose

Define actionable UI/UX requirements for the SS frontend based on a comprehensive audit identifying 64 issues across navigation, display, functionality, accessibility, and edge cases. This spec establishes testable acceptance criteria for each issue category to ensure production-quality user experience.

## Background

The SS frontend (`/frontend/`) is a Vite + React + TypeScript application serving as the primary user interface for the Stata analysis service. An exhaustive audit was conducted reviewing all source files including `App.tsx`, Step components (1-3 + Status), panel components, CSS files, i18n configuration, API client, and admin pages.

The audit identified issues in the following categories:
- High Priority: 5 issues (core interaction blockers)
- Medium Priority: 5 issues (experience degradation)
- Low Priority: 8 issues (polish and optimization)
- Display/Layout: 7 issues (visual rendering problems)
- Functionality: 11 issues (missing or broken features)
- Edge Cases: 5 issues (error handling and recovery)
- Cognitive/UX: 5 issues (user understanding)
- Accessibility: 4 issues (a11y compliance)
- Responsive Design: 2 issues (device compatibility)
- Reversibility: 3 issues (undo and recovery)
- Performance: 3 issues (speed and responsiveness)
- Security/Privacy: 2 issues (trust indicators)
- Miscellaneous: 4 issues (other UX gaps)

Evidence: `/home/leeky/.gemini/antigravity/brain/89b9d570-18c0-441d-9e5e-9eb0a2f96826/frontend_uiux_audit.md`

## Related specs (normative)

- Frontend architecture: `openspec/specs/ss-frontend-architecture/spec.md`
- Frontend Desktop Pro: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Frontend-backend alignment: `openspec/specs/ss-frontend-backend-alignment/spec.md`
- UX loop closure: `openspec/specs/ss-ux-loop-closure/spec.md`

## Requirements

### Requirement: Navigation feedback MUST be visible and immediate

The frontend MUST provide visible feedback when users interact with navigation elements (tabs, buttons, links). Users MUST NOT be left wondering whether their action was registered.

#### Scenario: Tab switching shows loading state
- **WHEN** a user clicks the "分析任务" or "执行查询" tab
- **THEN** the tab immediately shows a visual loading indicator
- **AND** the page transition begins within 100ms

#### Scenario: Empty jobId navigation shows toast
- **WHEN** a user clicks a tab while jobId is null
- **THEN** a toast notification explains the redirect to /new
- **AND** the user is not silently redirected

### Requirement: Stepper MUST be interactive and informative

The stepper component MUST display step names (not just colored bars), indicate current position clearly, and allow navigation to completed steps.

#### Scenario: Stepper shows step labels
- **WHEN** the stepper is rendered
- **THEN** each step shows a label (e.g., "需求定义", "数据上传", "预览确认")
- **AND** the current step is visually distinct

#### Scenario: Stepper allows navigation to completed steps
- **WHEN** a user is on Step 3
- **AND** clicks on Step 2 in the stepper
- **THEN** the user navigates to Step 2 without losing Step 3 data

### Requirement: Keyboard shortcuts MUST be platform-aware

Keyboard shortcut hints MUST display the correct modifier key for the user's operating system (⌘ for macOS, Ctrl for Windows/Linux).

#### Scenario: Shortcut hint matches platform
- **WHEN** a user on Windows views the submit button
- **THEN** the shortcut hint shows "Ctrl + Enter" not "⌘ ↵"

### Requirement: Error panels MUST be actionable

Error panels MUST provide copyable request IDs, collapsible details for long messages, and appropriate action buttons for all error types.

#### Scenario: Request ID is copyable
- **WHEN** an error panel displays a requestId
- **THEN** a "复制" button copies the ID to clipboard
- **AND** visual feedback confirms the copy action

#### Scenario: Long error messages are collapsible
- **WHEN** an error message exceeds 200 characters
- **THEN** only the first 100 characters are shown by default
- **AND** an "展开详情" button reveals the full message

### Requirement: File upload zone MUST have clear affordances

The file upload area MUST display an upload icon, clear instructional text, and strong visual feedback during drag operations.

#### Scenario: Upload zone shows clear instructions
- **WHEN** the upload zone is rendered
- **THEN** it displays an upload icon and text "拖拽或点击上传"
- **AND** the accepted file formats are listed

#### Scenario: Drag activation is visually distinct
- **WHEN** a user drags a file over the upload zone
- **THEN** the zone background changes to a high-contrast color
- **AND** a border highlight appears

### Requirement: Global loading state MUST be visible

The frontend MUST display a global loading indicator (spinner or progress bar) during API operations lasting more than 300ms.

#### Scenario: Long API call shows global spinner
- **WHEN** an API call takes more than 300ms
- **THEN** a global spinner appears in a fixed position
- **AND** the spinner disappears when the call completes

### Requirement: Table hover states MUST be clearly visible

Data table rows MUST have hover states with sufficient contrast (minimum 1.5:1 against default background).

#### Scenario: Table row hover is visible in light mode
- **WHEN** a user hovers over a table row in light mode
- **THEN** the background color contrast ratio is at least 1.5:1

### Requirement: Modal dialogs MUST support keyboard interaction

Modal dialogs MUST support Escape key to close, trap focus within the modal, and include ARIA attributes for screen readers.

#### Scenario: Modal closes on Escape
- **WHEN** a modal is open
- **AND** the user presses Escape
- **THEN** the modal closes
- **AND** focus returns to the triggering element

#### Scenario: Modal traps focus
- **WHEN** a modal is open
- **AND** the user presses Tab repeatedly
- **THEN** focus cycles within the modal elements only

### Requirement: Select controls MUST have consistent styling

Select elements MUST use custom styling consistent with the design system, including custom dropdown arrows.

#### Scenario: Select displays custom arrow
- **WHEN** a select element is rendered
- **THEN** it displays a custom dropdown arrow icon
- **AND** the styling matches other form controls

### Requirement: Disabled buttons MUST be visually distinct

Disabled buttons MUST use grayscale colors or clear visual indicators beyond opacity reduction.

#### Scenario: Disabled button is clearly non-interactive
- **WHEN** a button is disabled
- **THEN** it displays a grayscale background
- **AND** pointer events are blocked

### Requirement: Empty states MUST include guidance

Empty state displays MUST include helpful illustrations and actionable guidance, not just text.

#### Scenario: Empty artifacts list shows guidance
- **WHEN** the artifacts list is empty
- **THEN** the UI shows an illustration and explanatory text
- **AND** a primary action button is displayed if applicable

### Requirement: Timestamps MUST be formatted for Chinese users

All timestamps MUST be displayed in a user-friendly Chinese format (e.g., "今天 21:30" or "2026年1月17日 21:30").

#### Scenario: Created timestamp is localized
- **WHEN** a job's created_at timestamp is displayed
- **THEN** it shows in Chinese date format with relative time when applicable

### Requirement: Animations MUST enhance interaction feedback

The frontend MUST include micro-animations for button clicks, list item additions/removals, and state transitions.

#### Scenario: Button click has micro-animation
- **WHEN** a user clicks a primary button
- **THEN** the button displays a scale or ripple animation

### Requirement: Color contrast MUST meet WCAG AA

All text-background color combinations MUST meet WCAG AA contrast requirements (4.5:1 for normal text).

#### Scenario: Muted text passes contrast check
- **WHEN** text with --text-muted color is rendered on --surface background
- **THEN** the contrast ratio is at least 4.5:1

### Requirement: Step navigation MUST allow backward movement

Users MUST be able to navigate to previous steps without losing their current progress.

#### Scenario: Back button navigates to previous step
- **WHEN** a user is on Step 3
- **AND** clicks a "返回上一步" button
- **THEN** the user navigates to Step 2
- **AND** Step 3 data is preserved in state

### Requirement: All UI text MUST be in i18n configuration

All user-visible text MUST be defined in the i18n configuration file, not hardcoded in components.

#### Scenario: Brand name is in i18n
- **WHEN** the header brand is rendered
- **THEN** the text comes from zhCN.brand.name

### Requirement: Dark mode MUST support system preference

Dark mode MUST automatically follow the user's system preference in addition to manual toggle.

#### Scenario: Theme follows system by default
- **WHEN** a new user visits the site
- **AND** their system is in dark mode
- **THEN** the site renders in dark mode by default

### Requirement: Input fields MUST show character counts

Text inputs with length limits MUST display current/maximum character counts.

#### Scenario: Requirement textarea shows character count
- **WHEN** the requirement textarea is rendered
- **THEN** it displays a character count (e.g., "0/2000")
- **AND** the count updates as the user types

### Requirement: Main content area MUST be wider

The main content area MUST have a max-width of at least 880px (currently 680px) to accommodate data tables and code blocks.

#### Scenario: Main content is 880px on desktop
- **WHEN** the main content area is rendered on a 1920px wide screen
- **THEN** the content area max-width is at least 880px

### Requirement: Table heights MUST be consistent and adequate

Data tables MUST have consistent max-height values (minimum 400px) and clearly indicate when content is scrollable.

#### Scenario: Data preview table has adequate height
- **WHEN** the data preview table is rendered
- **THEN** the max-height is at least 400px
- **AND** a scroll indicator appears when content overflows

### Requirement: Truncated content MUST show full text on hover

Any truncated text (file names, cell content) MUST display the full text in a tooltip on hover.

#### Scenario: Long filename shows tooltip
- **WHEN** a filename is truncated with ellipsis
- **AND** user hovers over the filename
- **THEN** a tooltip displays the full filename

### Requirement: Cell truncation MUST allow expansion

Table cells with truncated content MUST allow users to view the full content via click or hover.

#### Scenario: Truncated cell expands on click
- **WHEN** a table cell is truncated (>120 chars)
- **AND** the user clicks the cell
- **THEN** a popover or modal displays the full content

### Requirement: Stepper MUST align with page content

The stepper component MUST be visually aligned with the page title and lead text to form a cohesive header block.

#### Scenario: Stepper aligns with title
- **WHEN** the step header is rendered
- **THEN** the stepper width matches the content width
- **AND** vertical spacing creates visual grouping

### Requirement: Analysis guide cards MUST have uniform height

Analysis method guide cards MUST have equal heights regardless of content length.

#### Scenario: Guide cards have equal height
- **WHEN** the analysis guide panel renders multiple cards
- **THEN** all cards in the same row have equal height

### Requirement: Info panels MUST use readable layouts

Panels displaying multiple info items MUST use structured layouts (multi-line or table) instead of inline separators on narrow screens.

#### Scenario: Preview info is readable on mobile
- **WHEN** the preview panel info row is rendered on a <600px screen
- **THEN** info items display in a vertical list, not horizontal

### Requirement: File upload MUST show progress

File uploads MUST display a progress indicator showing percentage or bytes transferred.

#### Scenario: Upload shows progress bar
- **WHEN** a file upload is in progress
- **THEN** a progress bar shows upload percentage
- **AND** the percentage updates in real-time

> **Note:** This requirement needs backend support for chunked uploads or progress feedback.

### Requirement: File validation MUST check content type

File uploads MUST validate file content type, not just extension, and show immediate feedback for invalid files.

#### Scenario: Invalid file shows immediate error
- **WHEN** a user selects a .txt file renamed to .csv
- **THEN** the UI shows an immediate validation error
- **AND** the file is not uploaded

### Requirement: Batch download MUST be available

When multiple artifacts exist, users MUST be able to download all files at once via a "下载全部" button.

#### Scenario: Download all artifacts as zip
- **WHEN** the artifacts list has 3+ items
- **AND** the user clicks "下载全部"
- **THEN** a zip file containing all artifacts is downloaded

> **Note:** This requirement needs a backend endpoint for zip packaging.

### Requirement: Admin job list MUST support pagination

The admin job list MUST support pagination with configurable page sizes and MUST NOT load all jobs at once.

#### Scenario: Job list loads first page
- **WHEN** the admin opens the jobs page
- **THEN** only the first 20 jobs are loaded
- **AND** pagination controls are visible

> **Note:** This requirement needs backend API changes for pagination parameters.

### Requirement: Draft polling MUST have timeout

Draft preview polling MUST have a maximum retry count or timeout, after which a clear error is shown.

#### Scenario: Polling times out after max retries
- **WHEN** draft preview returns pending 10 consecutive times
- **THEN** polling stops
- **AND** an error message explains the timeout

### Requirement: Confirmed state MUST preserve user inputs

After confirmation, the UI MUST display user's submitted variable corrections and answers in read-only mode.

#### Scenario: Locked view shows submitted corrections
- **WHEN** a job is in confirmed/locked state
- **THEN** the variable corrections table is visible and read-only
- **AND** the answers to stage1 questions are visible

### Requirement: Reset MUST clean up all job data

The resetToStep1 function MUST clean up all localStorage data for the affected jobId, not just auth token and app state.

#### Scenario: Reset clears all snapshots
- **WHEN** the user clicks "重新兑换"
- **THEN** all localStorage keys containing the jobId are removed
- **AND** no orphaned data remains

### Requirement: Admin login MUST support remember-me

The admin login MUST offer a "记住我" checkbox that extends token validity.

#### Scenario: Remember-me extends session
- **WHEN** the admin logs in with "记住我" checked
- **THEN** the session lasts longer than the default duration

### Requirement: API retries MUST use exponential backoff

API retry logic MUST implement exponential backoff to avoid overwhelming the server during outages.

#### Scenario: Retry waits before second attempt
- **WHEN** an API call fails
- **AND** the user clicks "重试"
- **THEN** the retry waits at least 1 second before executing
- **AND** subsequent retries wait progressively longer

### Requirement: Sheet selection MUST be persisted

User's Excel sheet selection MUST be persisted in localStorage and restored on page reload.

#### Scenario: Sheet selection survives reload
- **WHEN** the user selects Sheet "Data2"
- **AND** refreshes the page
- **THEN** "Data2" is still selected

### Requirement: Auto-refresh interval MUST be configurable and visible

The auto-refresh feature MUST display the current interval and allow users to adjust it.

#### Scenario: Auto-refresh shows interval
- **WHEN** auto-refresh is enabled
- **THEN** the UI shows "每3秒刷新" or similar text
- **AND** a dropdown allows changing the interval

### Requirement: Session expiry MUST be handled gracefully

The frontend MUST detect session expiry proactively and warn users before making API calls.

#### Scenario: Token expiry shows warning
- **WHEN** the auth token will expire in <5 minutes
- **THEN** a warning banner appears
- **AND** the user can re-authenticate without losing data

### Requirement: Form state MUST survive page reload

User inputs in Step 1-3 (requirement text, variable corrections, answers) MUST be persisted to localStorage on every change.

#### Scenario: Requirement text survives reload
- **WHEN** the user types in the requirement textarea
- **AND** refreshes the page
- **THEN** the text is restored from localStorage

### Requirement: Browser back button MUST maintain state

Browser history navigation MUST restore component state, not just route.

#### Scenario: Back button restores Step 3 form
- **WHEN** the user navigates from Step 3 to Step 2 via back button
- **AND** clicks forward to return to Step 3
- **THEN** the variable corrections are restored

### Requirement: Network disconnection MUST be detected

The frontend MUST detect network disconnection and display an offline banner.

#### Scenario: Offline mode shows banner
- **WHEN** the network is disconnected (navigator.onLine is false)
- **THEN** a banner displays "网络已断开，部分功能不可用"

### Requirement: Multi-tab conflicts MUST be handled

The frontend MUST detect localStorage changes from other tabs and warn about potential conflicts.

#### Scenario: Concurrent edit warning
- **WHEN** another tab modifies the same job's state
- **THEN** the current tab shows a warning toast
- **AND** prompts user to refresh

### Requirement: Error messages MUST explain root cause

Error messages MUST include possible causes and suggested actions, not just generic failure text.

#### Scenario: Upload error explains cause
- **WHEN** a file upload fails due to size limit
- **THEN** the error shows "文件过大（最大10MB），请压缩后重试"

### Requirement: Help entry point MUST be accessible

Every page MUST include a help entry point (icon or link) that opens documentation or support contact.

#### Scenario: Help button is visible
- **WHEN** any page is rendered
- **THEN** a help icon is visible in the header
- **AND** clicking it opens help documentation

### Requirement: Step dependencies MUST be explained

When a step is blocked waiting for async processing, the UI MUST explain what is happening and why.

#### Scenario: Pending state explains processing
- **WHEN** draft preview shows "预处理中"
- **THEN** the UI explains "系统正在分析您的数据和需求，预计需要30秒"

### Requirement: Keyboard navigation MUST be complete

All interactive elements MUST be reachable via Tab key in a logical order, with visible focus indicators.

#### Scenario: Tab order is logical
- **WHEN** the user presses Tab repeatedly on Step 1
- **THEN** focus moves: taskCode → requirement → submit button

### Requirement: Screen reader support MUST be implemented

Dynamic content updates MUST use aria-live regions, and all interactive elements MUST have accessible names.

#### Scenario: Error announcement
- **WHEN** an error panel appears
- **THEN** the error is announced to screen readers via aria-live="polite"

### Requirement: Color-blind safe indicators MUST be used

Status indicators MUST use icons or text labels in addition to color.

#### Scenario: Success status has icon
- **WHEN** a job status shows "succeeded"
- **THEN** a checkmark icon accompanies the green text

### Requirement: Text sizing MUST use relative units

Font sizes MUST use rem or em units to respect user browser font size preferences.

#### Scenario: Body text scales with browser setting
- **WHEN** the user sets browser font size to "Large"
- **THEN** body text appears proportionally larger

### Requirement: Responsive breakpoints MUST be defined

The frontend MUST define at least 3 breakpoints (mobile <768px, tablet 768-1024px, desktop >1024px) with appropriate layouts.

#### Scenario: Header adapts to mobile
- **WHEN** the viewport is <768px
- **THEN** the header collapses to a mobile-friendly layout

### Requirement: Touch targets MUST be adequately sized

All interactive elements MUST have minimum touch target size of 44x44px on touch devices.

#### Scenario: Mobile button is touch-friendly
- **WHEN** a button is rendered on a touch device
- **THEN** its touch target is at least 44x44px

### Requirement: Undo mechanism MUST be available for corrections

Variable correction changes MUST support undo for the last action, not just "clear all".

#### Scenario: Undo last correction
- **WHEN** the user changes a variable mapping
- **AND** clicks "撤销"
- **THEN** the previous mapping is restored

### Requirement: Dangerous actions MUST require confirmation

Actions that discard progress (like "重新兑换") MUST display a confirmation dialog before executing.

#### Scenario: Redeem requires confirmation
- **WHEN** the user clicks "重新兑换"
- **THEN** a confirmation dialog appears with "确定要放弃当前任务吗？"
- **AND** the action only proceeds on confirmation

### Requirement: Post-confirmation corrections MUST be possible

Users MUST be able to request corrections after confirmation through a support channel or amendment feature.

#### Scenario: Correction request is available
- **WHEN** a job is in confirmed state
- **THEN** a "请求修正" button is visible
- **AND** clicking it opens a contact form or amendment workflow

### Requirement: Large file handling MUST include warnings

File uploads exceeding recommended size MUST show warnings and processing time estimates.

#### Scenario: Large file shows warning
- **WHEN** the user selects a file >20MB
- **THEN** a warning shows "大文件可能需要较长处理时间（预计2-5分钟）"

### Requirement: Skeleton screens MUST precede content

Pages MUST display skeleton placeholders while loading content, not blank screens.

#### Scenario: Step 3 shows skeleton on load
- **WHEN** Step 3 is loading draft data
- **THEN** skeleton placeholders show the expected layout
- **AND** skeletons are replaced by content when loaded

### Requirement: API requests MUST have timeouts

All API requests MUST have a 30-second timeout, after which a clear timeout error is shown.

#### Scenario: Slow request shows timeout
- **WHEN** an API call exceeds 30 seconds
- **THEN** the request is aborted
- **AND** an error shows "请求超时，请稍后重试"

### Requirement: Data privacy notice MUST be visible

The upload page MUST display a brief data privacy notice explaining how uploaded data is handled.

#### Scenario: Privacy notice on upload page
- **WHEN** the upload panel is rendered
- **THEN** a privacy notice is visible (e.g., "您的数据仅用于本次分析，处理完成后将被安全删除")

### Requirement: Auth tokens MUST use secure storage

Auth tokens SHOULD use HttpOnly cookies instead of localStorage where possible, or implement additional XSS protections.

#### Scenario: Token storage is XSS-resistant
- **WHEN** auth token is stored
- **THEN** it is stored with appropriate security measures
- **AND** cannot be accessed by injected scripts

> **Note:** This may require backend changes for cookie-based auth.

### Requirement: Table content MUST be copyable

Users MUST be able to select and copy table cell contents.

#### Scenario: Cell content is selectable
- **WHEN** user attempts to select text in a table cell
- **THEN** the text is selectable
- **AND** can be copied to clipboard

### Requirement: Job sharing MUST be possible

Users MUST be able to generate a shareable link to view job status (read-only).

#### Scenario: Share button generates link
- **WHEN** the user clicks "分享" on the status page
- **THEN** a shareable URL is copied to clipboard
- **AND** recipients can view status without auth

> **Note:** This requires backend support for read-only share tokens.

### Requirement: Page titles MUST reflect current step

The browser tab title MUST update to reflect the current step or page.

#### Scenario: Step 2 has unique title
- **WHEN** the user navigates to Step 2
- **THEN** the browser tab title is "数据上传 — Stata Service"

### Requirement: Version info MUST be accessible

The footer or settings MUST display the current frontend version and link to changelog.

#### Scenario: Version is visible in footer
- **WHEN** the user scrolls to the footer
- **THEN** the version number (e.g., "v1.2.3") is visible
- **AND** clicking it opens the changelog

## Backend requirements for frontend features

The following requirements need backend API changes:

### Requirement: Backend MUST support upload progress

Backend MUST support chunked uploads or provide progress feedback via streaming or status endpoint.

#### Scenario: Upload endpoint supports chunks
- **WHEN** a file is uploaded in chunks
- **THEN** the backend acknowledges each chunk with progress
- **AND** supports resume on failure

### Requirement: Backend MUST support artifact zip download

Backend MUST provide an endpoint to download all job artifacts as a single zip file.

#### Scenario: Zip endpoint returns all artifacts
- **WHEN** GET /jobs/{job_id}/artifacts.zip is called
- **THEN** a zip containing all artifacts is returned

### Requirement: Backend MUST support pagination

Job listing endpoints MUST support ?page=N&limit=M parameters for pagination.

#### Scenario: Jobs endpoint returns paginated results
- **WHEN** GET /admin/jobs?page=1&limit=20 is called
- **THEN** only 20 jobs are returned with total count and pagination metadata

### Requirement: Backend MUST provide expiry metadata for tokens

Token responses MUST include expiry time so frontend can implement proactive expiry warnings.

#### Scenario: Token response includes expiry
- **WHEN** a token is issued
- **THEN** the response includes expires_at timestamp

## Blockers summary

The 64 issues are organized into task cards under:
- `openspec/specs/ss-frontend-ux-audit/task_cards/`

Priority breakdown:
- P0 (Blocking): 5 issues (navigation, stepper, shortcuts, errors, upload zone)
- P1 (High): 12 issues (loading state, modal, disabled states, session, network, etc.)
- P2 (Normal): 30 issues (display, functionality, accessibility)
- P3 (Low): 17 issues (polish, animations, version info)
