# Task Card: FE-004 结果打包下载按钮

- Priority: P2
- Area: Frontend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

当后端提供 ZIP 打包能力后（BE-016），前端需要提供“一键下载材料包”的按钮，并在生成/失败时给出明确反馈。

## 技术分析

- 影响：没有按钮，用户仍需手动逐个下载；无法形成“交付物打包”的体验闭环。
- 代码定位锚点：
  - `src/domain/models.py`（ZIP 产物会进入 artifacts index）
  - `src/api/artifacts.py`（下载端点参考）
  - `frontend/src/features/`（结果页/下载区入口）

## 解决方案

1. 增加下载按钮（v1）：
   - 状态：idle / generating / ready / failed
2. 对接后端：
   - 触发打包（若需要）→ 获取 ZIP artifact → 下载
3. 错误处理：
   - 展示结构化错误 message

## 验收标准

- [ ] 用户可一键下载 ZIP（浏览器保存对话框）
- [ ] 打包中/失败有清晰 UI 状态提示
- [ ] 错误信息来自结构化错误响应（不展示堆栈）

## Dependencies

- BE-016

