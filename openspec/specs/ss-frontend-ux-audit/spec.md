# Spec: ss-frontend-ux-audit

## Purpose

把 SS 前端 UI/UX 的“问题清单”变成可执行、可验收的规范（spec）与后续工作拆解（task cards），避免后续实现者反复复盘与走偏。

本 spec 不做工程实现；它只回答三件事：
1) 用户现在哪里用着“不像一个正常工具型 App”
2) 我们要把体验修到什么程度才算“好用”
3) 后续实现应该按什么顺序、拆成哪些 Issue 来做

## Scope

覆盖 SS Web 前端（用户端 + 管理端）在以下方面的体验质量：
- 显示层级与布局（宽度/表格/代码区域）
- 导航与步骤引导（tabs/stepper/返回上一步）
- 反馈与等待（loading/上传进度/pending 轮询）
- 错误与可恢复性（可操作错误、重试策略、会话过期、刷新恢复）
- i18n 与本地化（中文文案、快捷键、时间格式）
- 可访问性（键盘/屏幕阅读器/对比度）
- 性能与可信感（大文件策略、隐私说明、token 存储感知）

该 spec 以“问题编号（1-64）”作为统一索引；每个 task card 必须声明它覆盖哪些编号。

## Related specs (normative)

- Frontend Desktop Pro 视觉系统：`openspec/specs/ss-frontend-desktop-pro/spec.md`
- Frontend 架构边界：`openspec/specs/ss-frontend-architecture/spec.md`
- UX 主链路：`openspec/specs/ss-ux-loop-closure/spec.md`
- API surface：`openspec/specs/ss-api-surface/spec.md`
- 安全基线：`openspec/specs/ss-security/spec.md`

## Requirements

### Requirement: Task cards MUST be the single-source execution checklist for the 64-item UX audit list

Task cards MUST be treated as the single source of execution for resolving the UX audit items (1..64).

本 spec 只定义“应该长什么样”；具体“怎么改、改哪些文件、怎么验收”必须下沉到 task cards，且每个 task card 必须明确覆盖哪些问题编号。

#### Scenario: Task card coverage is explicit
- **WHEN** a new task card is added under `openspec/specs/ss-frontend-ux-audit/task_cards/`
- **THEN** it includes a section `Covers` listing the issue numbers it resolves (subset of `1..64`)
- **AND** it includes an acceptance checklist that can be verified without reading implementation code

### Requirement: Main content layout MUST be tool-grade (not blog-grade)

The user-facing main content layout MUST be tool-grade (not blog-grade) for data tables, mappings, and code/drafts.

用户端主内容区当前 680px 的“阅读型宽度”不适配数据工具的核心交互（表格、变量映射、长脚本/草稿）。主内容区必须在宽屏下自动扩展，并在窄屏下保持可用。

#### Scenario: Desktop width expands for tables and code
- **GIVEN** viewport width ≥ 1440px
- **WHEN** rendering Step2 data preview, Step3 mapping tables, or draft/code blocks
- **THEN** main content max-width is at least `880px`
- **AND** layout avoids forcing horizontal scrolling as the primary way to understand the table

#### Scenario: Responsive layout does not break on small screens
- **GIVEN** viewport width ≤ 768px
- **WHEN** rendering the same pages
- **THEN** the UI remains usable (no overlapping header, no hidden primary actions)
- **AND** touch targets remain ≥ 44px height for primary interactions

### Requirement: Navigation and step progress MUST be explicit, reversible, and never silent

Navigation and step progress MUST be explicit, reversible, and never silent.

用户必须清楚自己在哪一步、下一步是什么、是否可回退；任何跳转都不能“静默发生”。

#### Scenario: Tabs provide immediate feedback
- **WHEN** the user switches tabs (分析任务 / 执行查询)
- **THEN** the UI shows an immediate visual response (active state + loading/transition cue)

#### Scenario: Missing context is explained
- **WHEN** the user triggers navigation that requires `jobId` but `jobId` is missing
- **THEN** the UI explains what happened and how to fix it (not a silent redirect)

#### Scenario: Stepper is informative and supports back navigation
- **WHEN** the stepper is rendered
- **THEN** it shows step labels and current step
- **AND** the user can go back to completed steps without losing already-entered information

### Requirement: Waiting states MUST be visible, bounded, and user-comprehensible

Waiting states MUST be visible, bounded, and understandable to non-technical users.

“按钮禁用”不等于“用户知道系统在忙”。所有可感知等待都必须给出明确反馈，并且轮询/等待必须有上限与提示。

#### Scenario: Global busy indicator appears for non-trivial waits
- **WHEN** an API call takes longer than 300ms
- **THEN** a global loading indicator is shown
- **AND** it is removed when the operation completes

#### Scenario: Pending polling is bounded
- **WHEN** the backend returns `pending` for draft/preview
- **THEN** the UI shows a user-readable waiting message and estimated next retry timing
- **AND** polling has a maximum duration or max retries after which the user sees a clear fallback action

### Requirement: Error UX MUST be actionable and human-readable

Error UX MUST be actionable and human-readable.

错误面板不能只说“失败了”；必须告诉用户“发生了什么”和“我该怎么做”。同时保留工程排障字段（requestId）并做到可复制。

#### Scenario: Request id is copyable and not overwhelming
- **WHEN** an error is shown
- **THEN** request id is visible and copyable
- **AND** long technical details are collapsible so they do not block the main workflow

#### Scenario: Errors provide next actions
- **WHEN** the frontend receives an error response with known remediation (e.g. re-auth, retry later, fill missing fields)
- **THEN** the UI presents the matching action buttons and short guidance text

### Requirement: Data preview MUST support “read, copy, and verify” workflows

Data preview MUST support “read, copy, and verify” workflows for variable names, filenames, and cell content.

数据预览表格不仅要能看，还要支持用户复制变量名、查看被截断内容、理解当前展示范围（行/列/工作表）。

#### Scenario: Truncation is transparent
- **WHEN** a filename or cell value is truncated (ellipsis)
- **THEN** the full value is available via tooltip/popover
- **AND** the truncation rule is consistent across the app

#### Scenario: Users can copy variable names
- **WHEN** the preview table is rendered
- **THEN** users can select/copy cell text and column names without hacks

### Requirement: i18n and localization MUST be complete and consistent

i18n and localization MUST be complete and consistent across user and admin UIs.

用户端与管理端的文本必须统一进入 i18n；快捷键提示必须按平台显示；时间格式必须面向中文用户可读。

#### Scenario: No hardcoded user-visible strings
- **WHEN** reviewing user-visible UI strings
- **THEN** they are sourced from i18n (not hardcoded literals)

#### Scenario: Shortcut hints match the OS
- **WHEN** the UI shows “提交/继续”快捷键提示
- **THEN** macOS shows `⌘` and Windows/Linux shows `Ctrl`

### Requirement: Accessibility baseline MUST be met for keyboard and screen readers

Accessibility baseline MUST be met for keyboard and screen readers.

至少满足：键盘可操作、焦点可见、modal 可关闭可聚焦、颜色对比度可用、屏幕阅读器有基本语义信息。

#### Scenario: Modal supports Escape and focus trap
- **WHEN** a modal is opened
- **THEN** Escape closes it
- **AND** focus is trapped within the modal until closed

#### Scenario: Color is not the only signal
- **WHEN** the UI indicates success/error/disabled
- **THEN** it is not communicated by color alone (text/icon also conveys meaning)

### Requirement: Local state MUST survive refresh and reduce accidental data loss

Local state MUST survive refresh and reduce accidental data loss.

用户在 Step3 已经做的变量修正/问题选择，不应因为刷新、断网、token 过期、或误点“重新开始”而无声丢失。

#### Scenario: Refresh restores in-progress user input
- **GIVEN** the user has filled variable mappings and answers on Step3
- **WHEN** the page is refreshed
- **THEN** the UI restores those inputs (best-effort) and clearly indicates they are local drafts

#### Scenario: Dangerous reset requires confirmation
- **WHEN** the user triggers a destructive action (e.g. 重新兑换 / 重新开始)
- **THEN** the UI asks for confirmation and explains what will be lost
