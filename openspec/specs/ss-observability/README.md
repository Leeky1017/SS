# SS Observability — Index

本目录定义 SS 的可观测性基线（结构化日志 + 必带字段）。

## 事件码（建议）

- 事件码格式：`SS_<AREA>_<ACTION>`（示例：`SS_JOB_CREATE`、`SS_RUN_START`、`SS_RUN_FAIL`）
- 每条日志至少带：
  - `job_id`
  - `run_id`（执行期）
  - `step`（按需）

## 配置来源（硬约束）

- log_level MUST 来自 `src/config.py`
- 其他模块 MUST NOT 直接读环境变量拼装日志行为

## Task cards

- `openspec/specs/ss-observability/task_cards/round-00-arch-a__ARCH-T061.md`（Issue #26）

