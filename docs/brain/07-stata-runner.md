# 07 — Stata Runner（do-file 生成 / 执行 / 产物归档）

目标：把 Stata 执行收敛成一个可替换的端口（StataRunner），并把执行过程变成可追溯 artifacts。

## 1) StataRunner 端口（建议）

`StataRunner.run(...) -> RunResult` 至少返回：
- `exit_code`
- `stdout_rel_path` / `stderr_rel_path`（或直接写入 log artifacts）
- `stata_log_rel_path`
- `duration_ms`

## 2) LocalStataRunner（最小实现）

建议：
- 用 `subprocess.run` 执行
- `cwd` 固定为 `jobs/<job_id>/runs/<run_id>/work/`
- 只允许读写 job 目录内文件（路径必须二次校验）
- 统一超时处理：超时视为失败（结构化错误码），并保留部分输出

## 3) DoFileGenerator（domain 侧）

DoFileGenerator 的职责：
- 输入：冻结 plan + inputs manifest + job context
- 输出：稳定、可复现的 do-file 文本 + 预期 artifacts 列表

原则：
- 同一个 plan 必须生成相同 do-file（排序/格式稳定）
- do-file 只能引用 job 目录内输入（相对路径）
- 任何可能执行系统命令的 Stata 语句必须严格控制（白名单）

## 4) 产物归档（artifacts kinds）

最小产物建议：
- `stata.do`：生成的 do-file
- `stata.log`：Stata 执行 log
- `run.stdout`/`run.stderr`：runner 层输出
- `stata.export.*`：导出的表/图（csv/png/pdf 等）

归档要求：
- 每个 artifacts 进入 job.json `artifacts_index`
- `meta` 记录 hash/size/created_at，便于审计与缓存

## 5) 失败语义（结构化）

建议错误码示例：
- `STATA_NOT_FOUND`：本机没有 Stata 可执行文件
- `STATA_TIMEOUT`：执行超时
- `STATA_EXIT_NONZERO`：非 0 退出码
- `DOFILE_GENERATION_FAILED`：计划不合法/输入缺失导致无法生成

每个错误必须：
- 写入日志事件码（带 job_id/run_id）
- 落盘 artifacts（stderr/log/meta）

