# Task Card: FE-003 论文段落预览与复制

- Priority: P1
- Area: Frontend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/paper-writing-prompts.md`
  - `openspec/specs/ss-full-auto-orchestration/spec.md`

## 问题描述

论文段落生成后，用户需要在前端直接预览、复制粘贴，并明确哪些内容是占位符（缺数字/待补）。当前缺少该能力。

## 技术分析

- 影响：没有预览与复制，论文写作产物无法形成用户可用闭环；同时占位符不可见会导致用户误用不完整内容。
- 代码定位锚点：
  - `src/domain/stata_report_service.py`（现有“文字产物落盘 + artifacts index”的参考）
  - `src/domain/models.py`（artifacts index 约束）
  - `frontend/src/features/`（论文段落展示入口）

## 解决方案

1. 对接后端写作产物（BE-010/BE-009）：
   - 拉取 `paper_paragraphs_v1.json` 或 markdown
2. UI 设计（v1）：
   - tabs：方法 / 结果 / 稳健性 / 机制 / 异质性
   - 一键复制按钮（复制纯文本）
   - 占位符高亮（例如“（待补）”）
3. 可用性：
   - 显示 citations（至少提供“来源表格/产物”的链接或提示）

## 验收标准

- [ ] 用户可预览并复制每个 section 的段落文本
- [ ] 占位符被显著标记，避免误用
- [ ] citations/来源信息可被用户查看（至少显示 rel_path 或可点击下载）

## Dependencies

- BE-010

