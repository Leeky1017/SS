# UX Task Card: Loading, Waiting, and Perceived Responsiveness

## Covers

- 1, 6, 13
- 26, 30, 36
- 40, 57, 58

## Problem (plain language)

用户经常不知道系统“是不是在工作”：
- busy 只禁用按钮，没有全局加载提示。
- 上传/生成草稿等操作没有进度/等待解释。
- pending 轮询无上限，可能无限等下去。
- API 无超时/取消机制，页面像卡死。
- 自动刷新间隔硬编码，用户不知道也不能改。

## Acceptance

- [ ] 全局 loading 指示器：当请求 >300ms 显示；结束即隐藏
- [ ] 上传过程提供进度（至少“正在上传/已完成”可见；最好带百分比）
- [ ] draft pending 有“最长等待/最大重试”上限；超时后给出可执行选项（重试/回退/重新开始）
- [ ] 前端请求有超时策略（用户可感知：超时提示而不是一直等）
- [ ] 自动刷新显示当前间隔，并允许关闭/调整（或至少解释固定 3 秒）
- [ ] 网络断开时有显式提示（offline banner / toast），恢复后提示可重试

## Dependencies

- 若要做更精确的上传进度：可能需要对接 upload sessions（见 `openspec/specs/ss-inputs-upload-sessions/spec.md`）。

