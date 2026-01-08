# Proposal: issue-202-stata-proxy-extension

## Why

SS 新版后端在 Execution Engine 层（`src/domain/composition_exec/` 等）已经成熟，但代理服务层（API + domain 业务交互）相对旧版 `stata_service` 存在明显缺口：
- 用户侧无法提交/落盘变量纠偏（Variable Corrections），导致后续生成与展示不一致
- 草案预览缺少结构化字段（仅 `draft_text`），无法支撑前端交互与后续冻结契约
- 冻结契约缺少列名交叉验证，存在“幻觉变量名进入执行阶段”的风险

本 Issue 的目标是以 spec-first 方式补齐这部分代理层能力的 **权威规格**，并拆解后续可执行的实现任务卡。

## What Changes

- 新增 OpenSpec：`openspec/specs/backend-stata-proxy-extension/spec.md`
  - Variable Corrections：token-boundary 替换规则与覆盖范围
  - Structured Draft Preview：`/draft/preview` 的结构化 response 字段
  - Contract Freeze：冻结前列名交叉验证与幂等/冲突语义
- 新增 Rulebook task：本目录 `proposal.md` / `tasks.md`
- 新增 Run log：`openspec/_ops/task_runs/ISSUE-202.md`

## Impact

- Affected specs (normative dependencies):
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`
- Breaking change: NO（目标为 v1 内的 additive 扩展；保持现有字段可用）
- User benefit:
  - 用户可提交变量纠偏并保证后续 Do-file/计划/展示一致
  - 草案预览可直接驱动 UI（变量映射 + 列候选 + 类型信息）
  - 冻结阶段阻断不存在的列名，降低执行失败与错误结论风险
