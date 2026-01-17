# UX Task Card: i18n, Copy, and Localization

## Covers

- 3, 12, 16, 17, 18
- 42, 44, 45

## Problem (plain language)

文案与本地化不统一会直接破坏信任：
- 一部分文字硬编码，i18n 不完整。
- 快捷键提示只写 mac（⌘↵），Windows 用户困惑。
- 时间显示格式对中国用户不友好（ISO / 浏览器默认格式混用）。
- 专业术语缺少解释与帮助入口。

## Acceptance

- [ ] 用户可见文案全部进入 i18n（含 tabs、标题、按钮、提示）
- [ ] 快捷键提示按平台显示（mac=⌘，win/linux=Ctrl）
- [ ] 时间统一成中文可读格式（并明确时区策略）
- [ ] “任务验证码”有解释与示例；关键术语有简短解释或 tooltip
- [ ] Dark mode 默认跟随系统（prefers-color-scheme），并允许手动切换覆盖
- [ ] textarea 有字数提示（并明确限制/建议）

