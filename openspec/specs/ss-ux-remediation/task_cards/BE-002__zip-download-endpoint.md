# Task Card: BE-002 Zip download endpoint

- Priority: P2-MEDIUM
- Area: Backend / Artifacts
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

无打包下载端点，用户无法一键下载多个产物。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `src/api/jobs.py`
- `src/domain/artifacts_service.py`

## 解决方案

1. 新增 artifacts 打包下载端点（zip）
2. 确保路径安全（防 traversal/symlink escape）

## 验收标准

- [ ] 提供 zip 下载端点并返回可下载文件
- [ ] 非法路径请求被拒绝且返回结构化错误

## Dependencies

- 无
