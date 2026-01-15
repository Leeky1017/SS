# Proposal: issue-483-p1-e2e-tests

## Why
SS 即将上线，需要一套“按系统层面覆盖”的端到端测试来尽可能暴露边界漏洞（而不仅是证明 happy-path 能工作），并为上线前后的回归提供稳定护栏。

## What Changes
- 新增 `tests/e2e/` 端到端测试套件：按系统层面（API 入口 / 输入处理 / LLM / 确认与修正 / 执行 / 状态管理）组织。
- 使用 `pytest + httpx`（ASGITransport）调用 API；通过 FastAPI dependency overrides 注入 fake/mock（LLM、Stata runner、队列/存储）保证可重复性。
- 产出覆盖报告与发现问题清单，并将关键运行证据写入 `openspec/_ops/task_runs/ISSUE-483.md`。

## Impact
- Affected specs: `rulebook/tasks/issue-483-p1-e2e-tests/specs/e2e-tests/spec.md`
- Affected code: `tests/e2e/**`（新增）
- Breaking change: NO
- User benefit: 上线前边界风险更早暴露；上线后回归更可靠（异常路径也有明确预期）。
