# Spec: ss-ux-remediation

## Purpose

Define a single authoritative OpenSpec home for SS UX remediation across **frontend**, **backend API contract**, and **E2E validation**, with a task-card backlog that is independently executable and acceptance-testable.

本规范面向“可维护性优先”的 SS 项目：把 UX 审计与功能阻断问题沉淀为可执行、可验收的任务卡，避免形成第二套文档体系。

## 概述

本规范定义了 SS 系统前端和后端的全面用户体验改进计划。问题来源包括：
1. 2026-01-17 的前端 UI/UX 深度审计（64 个问题）
2. 相关对话中识别的功能阻断问题（如 Plan freeze 缺少必填变量等）

## 范围

### 前端（64 个任务卡）
- 交互反馈与导航
- 显示与布局
- 功能性改进
- 状态管理
- 异常处理与容错
- 用户认知（文案/术语/帮助）
- 可访问性（键盘/读屏/对比度等）
- 响应式设计与性能
- 安全与隐私

### 后端（9 个任务卡）
- API 增强（分块上传、打包下载、分页）
- 草稿/预览轮询机制（max_retry / 超时）
- 辅助文件处理（sheet 选择、列候选合并）
- 列名规范化映射（original → normalized）
- 变量选择支持（ID/Time 等 required variables）
- 错误信息结构化（Plan freeze 可操作错误详情）

### 端到端测试（1 个任务卡）
- 面板回归完整工作流验证（含错误可操作性场景）

## 优先级定义

- **P0-BLOCKER**: 当前系统功能无法使用，必须立即修复
- **P1-HIGH**: 严重影响用户体验，本迭代必须完成
- **P2-MEDIUM**: 改善体验但非阻断性
- **P3-LOW**: 打磨优化，可延后

## 验收标准

本 spec 下所有任务卡在实现时必须满足：
1. 代码实现符合对应 design 文档与任务卡解决方案
2. 通过相关单元测试
3. 通过 E2E 测试（如适用）
4. 代码审查通过
5. 部署到 staging 验证

## Related specs (normative)

- Constitutional constraints: `openspec/specs/ss-constitution/spec.md`
- Frontend architecture: `openspec/specs/ss-frontend-architecture/spec.md`
- Frontend design system: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- API surface + error rules: `openspec/specs/ss-api-surface/spec.md`
- UX loop definition: `openspec/specs/ss-ux-loop-closure/spec.md`
- Testing strategy: `openspec/specs/ss-testing-strategy/README.md`

## Requirements

### Requirement: Legacy UX audit spec MUST be removed

To prevent documentation drift, the legacy UX audit spec folder MUST NOT remain in the repository tree.

#### Scenario: No legacy ux-audit spec exists
- **WHEN** running `find openspec/specs -name "*ux-audit*"`
- **THEN** it returns no results

### Requirement: This spec MUST define the remediation backlog via task cards

The remediation backlog MUST be represented by task cards under:
- `openspec/specs/ss-ux-remediation/task_cards/`

#### Scenario: Task cards exist for the defined scope
- **WHEN** browsing `openspec/specs/ss-ux-remediation/task_cards/`
- **THEN** FE-001..FE-064, BE-001..BE-009, and E2E-001 task cards exist

### Requirement: Every task card MUST be independently executable

Each task card MUST include:
- 问题描述
- 技术分析
- 解决方案
- 验收标准
- 优先级（P0/P1/P2/P3）

#### Scenario: A task card is executable without reading code
- **WHEN** a reader opens any task card in `openspec/specs/ss-ux-remediation/task_cards/`
- **THEN** they can understand what to change and how to verify success using only the task card + referenced design docs

