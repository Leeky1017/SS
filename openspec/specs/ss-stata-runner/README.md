# SS Stata Runner — Index

## 宪法级原则

- Stata 执行 MUST 收敛为单一端口（`StataRunner`）。
- 执行 MUST 隔离在 job 的 run attempt 目录内，禁止跨目录写入。
- 失败 MUST 结构化（error_code）并落盘证据（stderr/log/meta）。

## Do-file 生成（建议）

- Do-file MUST 由 plan 生成并保持稳定（同 plan -> 同输出）。
- Do-file 引用输入 MUST 使用 job 目录内相对路径。

## Do 模板库（推荐）

- SS SHOULD 复用/沉淀一个可版本化的 do 模板库，用于提升可复现性与可维护性。
- 模板库是数据资产（capability library），不是任务系统；详见：`openspec/specs/ss-do-template-library/README.md`。
- Runner 执行模板时 MUST 归档：模板原文、meta、参数替换表、stdout/stderr、log 与声明的 outputs。

