# Task Card: BE-016 OutputPackagingService（ZIP打包）

- Priority: P2
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

全自动交付需要“一键下载可复现材料包”。当前系统缺少面向用户的一键打包能力（ZIP），用户需要逐个下载表格/日志/do 文件。

## 技术分析

- 影响：交付体验差，用户无法方便地保存与分享完整复现材料；也不利于审计与问题复现。
- 代码定位锚点：
  - `src/domain/models.py`（artifacts index 是打包的可信输入）
  - `src/domain/job_workspace_store.py`（安全读取 job workspace）
  - `src/api/artifacts.py`（下载端点的参考；需保持路径安全）

## 解决方案

1. 新增 `OutputPackagingService`（建议新文件 `src/domain/output_packaging_service.py`）：
   - 输入：job_id + artifacts index（可配置包含范围）
   - 输出：ZIP 文件 artifact（rel_path 安全）
2. ZIP 内容建议（v1）：
   - plan.json、composition_summary.json
   - step evidence（runs/）
   - aggregation report + summary tables（若有）
   - paper paragraphs（若有）
3. 安全要求：
   - 禁止 traversal/symlink escape
   - 仅允许打包 job workspace 内已索引的 artifacts
4. API 暴露：
   - 提供一个下载端点或复用 artifacts 下载机制（必须返回结构化错误）

## 验收标准

- [ ] ZIP 产物可生成并可下载（单元/集成测试验证文件存在与非空）
- [ ] ZIP 内容来自 artifacts index（不可打包未索引文件）
- [ ] 不安全路径请求被拒绝并返回结构化错误

## Dependencies

- BE-007
- BE-015

