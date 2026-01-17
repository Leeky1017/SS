# UX Task Card: Privacy Notice and Token Trust Signals

## Covers

- 59, 60, 64

## Problem (plain language)

用户上传的是研究数据，默认会担心“数据去哪了”：
- UI 没有隐私说明入口。
- token 存 localStorage 的风险没有任何防护/解释。
- 用户不知道自己在用什么版本，无法判断更新内容。

## Acceptance

- [ ] 前端提供隐私/数据处理说明入口（简短、可读、可追溯）
- [ ] 明确说明：数据仅用于本次分析/保存策略/删除策略（以实际实现为准）
- [ ] 前端提供版本号/更新入口（至少能看到当前版本标识）
- [ ] token 存储策略在实现阶段评审（优先 HttpOnly cookie；若继续 localStorage，必须配套 XSS 风险控制与说明）

