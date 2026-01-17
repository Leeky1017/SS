# UX Task Card: Accessibility Baseline (A11y)

## Covers

- 8, 14
- 47, 48, 49, 50

## Problem (plain language)

不做可访问性会导致：
- 键盘用户无法用（Tab 顺序、focus 样式、modal 焦点）
- 屏幕阅读器读不出来（缺 aria、缺语义）
- 色盲用户分不清（只靠颜色）
- 对比度不够（尤其 muted 文本、hover 高亮）

## Acceptance

- [ ] 所有主要流程可仅用键盘完成（Tab/Enter/Esc）
- [ ] modal：Esc 可关、focus trap、aria-labelledby/aria-describedby 完整
- [ ] 可见 focus 样式（不是“按 Tab 看不到焦点在哪”）
- [ ] 状态提示不只靠颜色（成功/错误/禁用都有文字/图标辅助）
- [ ] 关键颜色组合达到 WCAG AA 对比度（至少覆盖 text-muted、hover、error）
- [ ] 字体支持用户缩放（不阻断浏览器缩放/系统字体设置）

