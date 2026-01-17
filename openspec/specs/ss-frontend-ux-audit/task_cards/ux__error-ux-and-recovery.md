# UX Task Card: Error UX and Recovery

## Covers

- 4, 34
- 37, 43

## Problem (plain language)

错误现在“不可用”：
- 只给 retry/redeem 两个按钮，很多错误没有对应操作。
- requestId 不能一键复制，长错误会把页面挤乱。
- 重试无退避策略，网络差时用户猛点会更糟。
- 失败信息对普通用户没意义（不知道原因/下一步怎么做）。
- token 过期无提前提醒，用户可能白忙一场。

## Acceptance

- [ ] requestId 可一键复制，并有复制成功反馈
- [ ] 错误详情可折叠，默认不干扰主流程
- [ ] 常见错误提供“像人话”的解释 + 下一步按钮（例如：重新登录/稍后重试/返回上一步）
- [ ] 重试策略加入退避（至少避免“连续狂点立即发请求”）
- [ ] token 过期时：用户看到清晰提示，并尽量保留本地填写内容不丢

## Dependencies

- 若后端能提供结构化 `next_actions`（类似 `PLAN_FREEZE_MISSING_REQUIRED`），前端应优先渲染为可点击行动。

