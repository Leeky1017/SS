# Spec — SS master brain architecture plan

## Goal

为 SS（LLM 作为“大脑”的 Stata 实证自动化系统）建立一份可执行、可维护的总体规划文档（主脑形态），用于指导后续所有模块的拆解、实现与验收。

## Requirements

- 增加主脑文档入口：`docs/brain/README.md`，并按主题拆分子文档（每个文件 < 300 行）。
- 文档必须覆盖并统一口径：
  - 分层边界（API/Domain/Infra/Worker）与依赖注入方式
  - 数据模型：`job.json` v1（含 `schema_version`）与 artifacts 索引
  - 状态机、幂等与并发策略
  - LLM Brain：Plan schema、prompt/response artifacts、脱敏与可复现
  - Stata Runner：do-file 生成、执行、日志与结果产物
  - Worker/Queue：claim、retry/backoff、run attempt、原子状态更新
  - API roadmap：status、artifacts、run trigger
  - 测试策略与本地验证命令
- 文档包含 GitHub issue roadmap（epics + sub-issues），与 `#9`/`#10`~`#15`/`#16`~`#27` 对齐。

## Scenarios (verifiable)

- `ruff check .` 与 `pytest -q` 在 PR checks 中保持全绿。

