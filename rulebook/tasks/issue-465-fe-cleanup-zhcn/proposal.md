# Proposal: issue-465-fe-cleanup-zhcn

## Why
Repo 根目录的遗留 Desktop Pro 前端（`index.html` + `assets/desktop_pro_*`）已不再使用（后端实际服务 `/frontend/dist`），但会误导后续开发与 AI agent 的代码导航与改动判断。

## What Changes
- 删除根目录遗留前端入口与静态资源目录：`/index.html`、`/assets/`。
- 为 React 前端引入可维护的中文术语表 `frontend/src/i18n/zh-CN.ts`，并将 Step 3 相关 UI 文本改为“中文优先 + 英文释义（括号）”。
- 将 UI 展示中的“蓝图/Blueprint”统一更名为“执行草案”（仅显示层；URL/API 路径保持不变）。

## Impact
- Affected specs: none (UI-only change; OpenSpec source-of-truth unchanged)
- Affected code: `index.html`, `assets/`, `frontend/src/features/step3/*.tsx`, `frontend/src/components/*.tsx`, `frontend/src/pages/*.tsx`
- Breaking change: NO (no API/path changes)
- User benefit: 中文用户阅读与操作负担显著降低，同时保留专业术语英文原文以确保语义准确。
