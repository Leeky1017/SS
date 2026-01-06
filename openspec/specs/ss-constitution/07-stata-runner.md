# 07 — Stata Runner（do-file 生成 / 执行 / 产物归档）

## 宪法级原则

- Stata 执行 MUST 收敛为单一端口（`StataRunner`）。
- 执行 MUST 隔离在 job 的 run attempt 目录内，禁止跨目录写入。
- 失败 MUST 结构化（error_code）并落盘证据（stderr/log/meta）。

## Do-file 生成（建议）

- Do-file MUST 由 plan 生成并保持稳定（同 plan -> 同输出）。
- Do-file 引用输入 MUST 使用 job 目录内相对路径。

