# SS Security — Index

本目录定义 SS 的安全红线：路径遍历、符号链接逃逸、执行越界、敏感信息泄露等。

## 路径安全（硬约束）

- artifacts 下载 MUST 防 `..` 与绝对路径
- MUST 防符号链接逃逸（只允许 job 目录内真实路径）

## 执行隔离（硬约束）

- runner `cwd` MUST 固定在 `jobs/<shard>/<job_id>/runs/<run_id>/work/`（legacy: `jobs/<job_id>/runs/<run_id>/work/`）
- do-file 生成与执行 MUST 禁止越界写入（`..`、绝对路径等）

## 脱敏（硬约束）

- logs 与 LLM artifacts MUST NOT 泄露 key/token/隐私字段

## Task cards

- `openspec/specs/ss-security/task_cards/round-00-arch-a__ARCH-T062.md`（Issue #27）
