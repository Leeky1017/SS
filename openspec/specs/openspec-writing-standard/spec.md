# Spec — OpenSpec writing standard (SS)

## Goal

让 OpenSpec 成为 SS 的“开发圣旨”：任何实现都必须从 spec 出发（spec-first），并且 spec 必须足够具体到可验证、可复现、可追溯。

## Scope

本规范约束以下文件：
- Specs：`openspec/specs/**/spec.md`
- Templates：`openspec/specs/_templates/*.md`
- Task runs：`openspec/_ops/task_runs/ISSUE-N.md`（由 `$openspec-rulebook-github-delivery` 约束）

## Definitions

- **Spec**：本次需求增量的权威说明（What/Why/Constraints/Acceptance），不是实现细节。
- **Scenario**：可验证的行为样例（Given/When/Then），必须能用命令/测试/文件证据验证。
- **MUST/SHOULD/MAY**：规范级别的强制词（参考 RFC 2119 语义）。

## Requirements

### R1 — Spec is the source of truth

- Spec MUST 作为权威口径：代码、注释、README、口头约定都不得与 spec 冲突。
- 若实现过程中发现 spec 不完整/不正确，MUST 先更新 spec，再更新实现。
- 每个 Issue/PR MUST 有对应的 spec（除非是纯运维/无代码的微小变更，并在 spec 中明确豁免理由）。

### R2 — Minimal structure (mandatory headings)

每个 `spec.md` MUST 包含以下标题（可按需要加更多章节，但不得缺失）：

- `# Spec — <title>`
- `## Goal`（或 `## Goals`）
- `## Requirements`
- `## Scenarios (verifiable)`（或 `## Scenarios`）

### R3 — Requirements MUST be testable

- Requirements MUST 用 **可判定** 的语言表达（避免“更好/更稳定/更优雅”等不可验收表述）。
- 每条关键约束 SHOULD 使用 MUST/SHOULD/MAY 表达强度，并给出边界条件。
- 若某条需求暂时无法自动化验证，MUST 提供人工验收步骤与证据路径（artifacts / logs / run output）。

### R4 — Scenarios MUST be verifiable and evidence-driven

- 每个 Scenario MUST 对应至少一种验证方式：
  - 命令（例如 `ruff check .` / `pytest -q`）
  - 测试用例名（例如 `test_xxx_returns_yyy()`）
  - 文件证据（例如 `openspec/_ops/task_runs/ISSUE-N.md`、产物路径）
- Scenario SHOULD 采用 Given/When/Then 写法，并覆盖至少：
  - 1 个 happy path
  - 1 个错误路径（如非法输入/非法状态迁移）

### R5 — No placeholders

Spec MUST 不包含占位符与敷衍内容：
- MUST NOT 出现：`(fill)`、`<fill>`、`TODO`、`TBD`
- 若未来工作明确但不在本次交付范围，MUST 放在 `## Non-goals` 或 `## Future work` 并说明原因。

### R6 — Size limits (maintainability hard gate)

- `spec.md` SHOULD 保持 `< 300` 行；超过必须拆分为多个 spec（多个 Issue）或将细节移到同目录补充文档，并在 spec 中链接。

## Scenarios (verifiable)

### Scenario: a spec is accepted by CI guard

Given a PR modifies `openspec/specs/**/spec.md`  
When `ci` runs spec guard  
Then the guard passes only if mandatory headings exist and no placeholders exist.

### Scenario: agent uses spec-first

Given an Issue has a spec under `openspec/specs/**/spec.md`  
When implementation changes scope  
Then the spec is updated first, and the run log `openspec/_ops/task_runs/ISSUE-N.md` records the verification commands and key output.

