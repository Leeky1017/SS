# [ROUND-03-FE-A] FE-C001: Scaffold frontend/ 工程 + Desktop Pro 样式基线（不引入新视觉体系）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/ss-constitution/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
- Design source of truth:
  - `index.html`
  - `assets/desktop_pro_theme.css`
  - `assets/desktop_pro_layout.css`
  - `assets/desktop_pro_components.css`
  - `assets/desktop_pro_step3.css`

## Problem

目前 SS 的 Desktop Pro 前端是单文件 `index.html`，难以演进与复用；同时仍需要保持既有 Desktop Pro 视觉体系，避免引入 Tailwind/MUI 等新体系导致风格漂移。

## Goal

在仓库根新增独立 `frontend/` 工程（React + TypeScript + Vite），并建立 Desktop Pro 的样式基线（CSS 变量 + primitives + theme toggle），作为后续步骤功能实现的稳定载体。

## In scope

- 在仓库根创建 `frontend/`（Vite + React + TypeScript）
- Desktop Pro 样式基线：
  - 复用/迁移 `assets/desktop_pro_*.css` 的 CSS 变量语义与 primitives（`panel/section-label/btn/data-table/mono`）
  - light/dark `data-theme` 切换
  - 基础布局（header/tabs/main 宽度、标题/lead 文案风格）
- 不引入新视觉体系（不新增 Tailwind/MUI/Antd/shadcn 等）

## Out of scope

- API 对接（见 FE-C002）
- create/upload/preview/blueprint/confirm/status 业务闭环（见 FE-C003–FE-C006）

## Dependencies & parallelism

- Depends on: none
- Can run in parallel with: FE-C002（API client 设计与类型定义），但 FE-C002 的实际落地依赖 `frontend/` 工程存在

## Acceptance checklist

- [ ] `frontend/` 存在且为 React + TypeScript + Vite 工程
- [ ] 可运行：`cd frontend && npm ci && npm run build`
- [ ] 可手工验收：`cd frontend && npm run dev` 打开后具有 Desktop Pro 基础视觉（CSS 变量 + primitives + theme toggle）
- [ ] 未引入 Tailwind/MUI/Antd/shadcn 等新视觉体系
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

