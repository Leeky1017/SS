# UX Task Card: Layout & Table Readability

## Covers

- 7, 9, 10
- 19, 20, 21, 22, 23, 24, 25
- 51, 52

## Problem (plain language)

现在页面像“窄博客”，不是“数据工具”：
- 主内容区太窄（680px），表格/代码都挤在一起。
- 多处表格高度上限不一致，用户需要在很多小框里反复滚动。
- 悬停/禁用状态太弱，用户看不出来当前能不能点。
- 手机/平板基本不可用（无响应式、触摸目标小）。

## Desired UX (design intent)

- 用户端主内容区在桌面端自动扩展到工具型宽度（880-960+），与 Admin 的 1100px 思路一致。
- 表格/代码区域提供更好的可读性：更明显的 hover、可见的滚动边界、统一的高度策略。
- 响应式：至少保证“不会崩”，并满足触摸目标大小下限。

## Acceptance

- [ ] 用户端主内容区在宽屏下 ≥ 880px（或按断点响应式扩展）
- [ ] Step2 预览表、Step3 变量映射表、warnings 表、下载列表的 max-height 策略统一且合理（并解释为什么）
- [ ] 表格行 hover 在浅色/深色模式下均明显可见（不是“几乎看不出来”）
- [ ] 禁用按钮样式一眼可见为不可点击（不只靠 0.6 opacity）
- [ ] 文件名截断时支持悬停查看完整文件名（tooltip/title）
- [ ] 预览信息行在窄屏不“挤成一坨”（分行/分组展示）
- [ ] 在 ≤ 768px 宽度下：Header 不挤压变形、主按钮不被遮挡、触摸目标 ≥ 44px

## Dependencies

- 无强依赖（纯前端 CSS/组件结构调整即可完成）。

## Notes for implementers

- 关键位置：`frontend/src/styles/layout.css`（`main { max-width: 680px; }`）
- 表格组件：`frontend/src/styles/components.css`（`.data-table-wrap`/hover/scroll）
- 典型页面：`frontend/src/features/step2/*`、`frontend/src/features/step3/*`、`frontend/src/features/status/*`

