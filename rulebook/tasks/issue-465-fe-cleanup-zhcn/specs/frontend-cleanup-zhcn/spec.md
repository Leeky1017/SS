# Spec delta: frontend-cleanup-zhcn (ISSUE-465)

## Scope
- Remove unused legacy Desktop Pro frontend artifacts from repo root.
- Localize SS React Step 3 UI to Chinese-first while retaining English term hints for precision.

## Requirements

### R1: Repo root legacy Desktop Pro artifacts MUST be removed

#### Scenario: Repo root does not contain legacy Desktop Pro entrypoint/assets
- **GIVEN** the SS repository root
- **WHEN** checking tracked files
- **THEN** `index.html` is not present
- **AND THEN** the `assets/` directory containing `desktop_pro_*` files is not present
- **AND THEN** no code references the removed files

### R2: Step 3 UI labels MUST use zh-CN terminology table (Chinese-first + English hints)
- Step 3 UI text MUST be sourced from `frontend/src/i18n/zh-CN.ts` (no ad-hoc hardcoded terms).

#### Scenario: Step 3 display labels use Chinese-first headings and role hints
- **GIVEN** the Step 3 UI is rendered
- **WHEN** viewing panels/tables/labels
- **THEN** headings/tables use Chinese-first labels (e.g., “变量概览”)
- **AND THEN** role labels use “中文 + (English)” (e.g., “因变量 (Outcome)”)
- **AND THEN** buttons and help text are Chinese-first

### R3: “蓝图/Blueprint” MUST be displayed as “执行草案” (display-only)

#### Scenario: UI uses “执行草案” while routes/APIs remain unchanged
- **GIVEN** UI labels related to blueprint/draft
- **WHEN** rendering those labels
- **THEN** the UI uses “执行草案”
- **AND THEN** URL paths and API payload keys remain unchanged (`blueprint` / `draft`)
