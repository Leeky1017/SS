# Proposal: issue-131-ux-spec-centralize

## Why
生产就绪 UX 闭环审计的 blockers 任务卡目前散落在多个 spec 目录，容易形成重复与漂移；需要用一个专门的 OpenSpec 集中承载问题定义与 task cards，保证权威与可维护性。

## What Changes
- 新增一个专门的 OpenSpec（`openspec/specs/ss-ux-loop-closure/`）用于描述生产就绪 UX 闭环缺口与修复任务。
- 将 UX-B001/B002/B003 task cards 移入该 spec 并补充细化（引用 #126/#127/#128）。
- 删除旧位置的散落 task cards，并更新审计报告与 run log 的引用路径。

## Impact
- Affected specs: `openspec/specs/ss-ux-loop-closure/`（新增）与旧 task card 位置（删除）
- Affected code: none
- Breaking change: NO
- User benefit: 统一权威入口，降低任务漂移风险；为闭环修复提供可执行、可追溯的规格与任务清单。
