# UX Task Card: Navigation, Stepper, and Back Navigation

## Covers

- 1, 2, 15, 23
- 42, 46
- 54, 55, 63

## Problem (plain language)

用户在“去哪、在哪、能不能回去”上很迷茫：
- Tab 切换没有明确反馈；jobId 缺失会静默跳转。
- Stepper 只是三条色块，没名字、不能点击回到上一步。
- 用户不能正常“返回上一步修改”，只能“重新兑换/重新开始”（很重、容易误点）。
- “任务验证码”概念解释不足，新用户不知道是什么、从哪里来。
- 页面标题不变，开多个标签页难区分。

## Acceptance

- [ ] Tabs 切换有即时反馈（active + loading/transition cue）
- [ ] jobId 缺失时不静默跳转：给出清晰提示 + 主按钮引导
- [ ] Stepper 展示步骤名称，并能跳转回已完成步骤（不丢失本地填写内容）
- [ ] Step2/Step3 提供“返回上一步”入口（不必重新兑换）
- [ ] “重新开始/重新兑换”属于危险操作：有二次确认 + 说明会丢什么
- [ ] Step1 对“任务验证码”提供一句话解释 + 示例（从哪里获取/开发模式说明）
- [ ] 浏览器 tab 标题随步骤变化（包含 step 名称与 jobId 片段/任务码片段）

## Dependencies

- 无强依赖（主要是路由/组件交互与文案完善）。

