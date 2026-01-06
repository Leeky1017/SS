# SS LLM Brain — Index

## 宪法级原则

- LLM provider MUST 可替换（infra 适配器），domain 不绑定 SDK。
- 每次 LLM 调用 MUST 落盘 artifacts（prompt/response/meta），并进入 `artifacts_index`。
- LLM 输出 MUST 受 schema 约束（尤其是计划：`LLMPlan`），解析失败视为错误路径。

## LLMPlan（结构化计划）建议

目标：把“要做什么”表达成可验证的 step 列表，不允许自由文本当执行脚本。

建议：
- `plan_version` + `steps[]`
- step `type` 必须是枚举
- step `produces` 与 artifacts kinds 对齐

## 脱敏与安全（最低基线）

- logs/artifacts MUST NOT 泄露 token/密钥/隐私标识符。
- prompt 默认只提供 inputs 摘要 + fingerprint，不直接喂原始数据内容。
- 对“要求执行系统命令/联网/读系统文件”的指令 MUST 拒绝/忽略。

