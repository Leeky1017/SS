# SS Task Cards（Issue 蓝图）— 使用说明

本目录借鉴 legacy `stata_service` 的 `task_cards/` 设计：把每个子 Issue 写成“agent 友好的蓝图”，用于快速对齐范围/依赖/验收与产物。

重要：task card **不替代** GitHub Issue / Rulebook tasks：
- GitHub Issue：并发与交付入口（任务唯一 ID）
- Rulebook task：执行清单（可勾选）
- Run log：`openspec/_ops/task_runs/ISSUE-N.md`（运行证据账本）

## 命名规范（推荐）

文件名与 Issue title 的前缀对齐，便于检索：

- `round-00-arch-a__ARCH-T011.md` ↔ `ARCH-T011`（Issue #16）

## 卡片内容约定（建议）

每张卡至少包含：
- Issue/ Epic/ Roadmap 链接
- 目标（Goal）
- 范围（In / Out）
- 验收标准（Acceptance checklist）
- 预期产物（Deliverables）：spec / tests / artifacts / run log
- 关键风险（Risks）与约束（Constraints）

