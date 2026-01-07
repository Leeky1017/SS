# [ROUND-01-UX-A] UX-B001: 数据上传 + 数据预览（CSV/Excel/DTA）

## Metadata

- Issue: #126 https://github.com/Leeky1017/SS/issues/126
- Audit: #124 https://github.com/Leeky1017/SS/issues/124
- Priority: P0 (Blocker)
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-testing-strategy/README.md`（场景 A）

## Goal

让真实用户能够把数据作为 Job 输入提交给 SS，并在提交分析需求前看到可解释的数据预览（列识别 + 样例行），为后续变量映射与分析计划奠定基础。

## In scope

- 新增 v1 输入端点：上传数据文件到指定 job（最小支持 CSV；扩展支持 Excel/DTA）
- 新增 v1 预览端点：返回列名/类型（尽力）、行数（尽力）、前 N 行预览
- 输入落盘到 job workspace（建议：`inputs/`）并写入 inputs manifest（job-relative）
- 更新 `job.json`：
  - `inputs.manifest_rel_path`
  - `inputs.fingerprint`
- 错误处理：空文件、格式不支持、解析失败必须返回结构化错误

## Dependencies & parallelism

- Depends on: `ss-job-contract`（inputs/manifest 的 job-relative 约束）
- Depends on: tenancy/path safety（tenant/job/path 不可越界）
- Parallelizable with: `UX-B002` / `UX-B003`

## Acceptance checklist

- [ ] 支持上传 CSV/Excel/DTA 至指定 job（multi-tenant 安全路径）
- [ ] 支持数据预览：列名/类型（尽力）/行数（尽力）/前 N 行
- [ ] inputs manifest + fingerprint 写入并可追溯（job-relative）
- [ ] 错误输入返回结构化错误（含 error_code + message）
- [ ] 测试覆盖：happy path + 空文件/格式错误/解析失败
