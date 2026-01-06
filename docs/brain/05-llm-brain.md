# 05 — LLM Brain（Plan / Prompts / Trace / Safety）

SS 把 LLM 当作“大脑”，但必须满足三条：

1) **可替换**：LLM provider 只是 infra 适配器；domain 不绑定某个厂商 SDK
2) **可追溯**：每次调用都有 artifacts（prompt/response/settings/timing）
3) **可控**：LLM 输出必须落在 schema 里；执行与落盘必须隔离与脱敏

## 1) LLMPlan（结构化计划）建议

LLMPlan 的目标：把“要做什么”表达成可验证的 step 列表，不允许把自由文本当作执行脚本。

建议 step shape（示例）：

```json
{
  "plan_version": 1,
  "steps": [
    {
      "step_id": "s1",
      "type": "stata.do.generate",
      "inputs": { "dataset_ref": "inputs/manifest.json" },
      "params": { "tasks": ["describe", "summarize"] },
      "produces": ["stata.do"]
    },
    {
      "step_id": "s2",
      "type": "stata.run",
      "inputs": { "do_ref": "stata.do" },
      "params": { "timeout_sec": 600 },
      "produces": ["stata.log", "exports/*"]
    }
  ]
}
```

约束：
- step `type` 必须是枚举（避免“任意字符串执行”）。
- `produces` 要与 artifacts kinds 对齐，便于验收与调试。

## 2) Prompt 组织（可复用、可审计）

推荐采用“输入信封”（envelope）策略：prompt 由稳定的模板 + job 上下文组成：

- System instructions：固定、安全边界与输出 schema
- User context：requirement + inputs summary（脱敏）+ 当前状态
- Output schema：明确 JSON schema + 示例

禁止：
- 将原始数据内容大量喂给 LLM（默认只提供摘要与 fingerprint）
- 在 prompt 中包含密钥/token/隐私标识符

## 3) LLM artifacts（必须落盘）

每次 LLM 调用最少落盘：
- `prompt.txt` 或 `prompt.json`
- `response.txt` 或 `response.json`
- `meta.json`：model/settings、版本（代码 hash 可选）、耗时、错误信息（如失败）、redaction 策略版本

并把 artifacts 写入 job.json 的 `artifacts_index`，用于 API 下载与审计。

## 4) 脱敏与安全（最低基线）

脱敏目标：日志与 artifacts 默认可共享给开发/调试，但不应暴露敏感信息。

最低规则（建议）：
- 替换/删除：绝对路径、用户名、token、邮箱、手机号等
- 只保留：输入文件名/相对路径、hash、行列数、变量名摘要

Prompt 注入防护（最小策略）：
- 计划输出必须严格 JSON schema（解析失败视为错误）
- 任何“执行命令/联网/读系统文件”类指令必须拒绝或忽略
- do-file 生成只能引用 job 目录内输入（由 DoFileGenerator 二次校验）

## 5) Stub vs Real Provider（演进策略）

MVP 建议：
- 先保持 `StubLLMClient` 可跑通闭环（不依赖网络）
- 再加真实 provider（`infra/llm/*`），但必须：
  - 显式注入（deps/worker）
  - 有重试与超时
  - 落盘 artifacts 与脱敏

