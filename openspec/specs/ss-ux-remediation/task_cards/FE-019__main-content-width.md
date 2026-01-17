# Task Card: FE-019 Main content width

- Priority: P1-HIGH
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

当前主内容区限制为 680px，对于数据表格和代码预览来说太窄，需要大量横向滚动。

## 技术分析

- 现状：`frontend/src/styles/layout.css` 中 `main` 使用 `max-width: 680px;`（见 `main { ... }` 块），而管理端 `.admin-main` 已经使用 `max-width: 1100px;`，两者对“工具型页面”的定位不一致。
- 影响面：Step2 预览表、Step3 映射表/草稿预览、Status 下载列表等工具型内容在宽屏被“强行压缩”，用户必须依赖横向滚动才能理解表格。

## 解决方案

1. 将 `main` 在宽屏断点下扩展到工具型宽度（建议 960px），并保持小屏下可用。
2. 建议采用响应式断点（避免所有屏幕都变宽）：
   ```css
   main {
     max-width: 680px;
   }
   @media (min-width: 1200px) {
     main {
       max-width: 960px;
     }
   }
   ```

## 验收标准

- [ ] 在 ≥1200px 屏幕，主内容区最大宽度为 960px（或等价的工具型宽度策略）
- [ ] Step2/Step3/Status 中表格横向滚动明显减少（仍允许极端宽表滚动）
- [ ] ≤768px 宽度下布局不崩坏（主按钮不被遮挡、内容可滚动）

## Dependencies

- 无
