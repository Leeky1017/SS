# Proposal: issue-414-step1-method-guidance

## Why
Step 1 当前仅有自由文本“研究设想与需求”，用户输入往往过于笼统，导致后续分析能力/模板选择不稳定；需要提供引导式方法选择，帮助用户快速写出结构化需求。

## What Changes
- 在 Step 1 增加两阶段分析方法引导 UI：先选“类别”，再选“子方法”。
- 选择子方法后自动填充一份可编辑的结构化需求模板到 textarea。
- 保留现有 quick fill（面板回归 / DID）并融入新引导 UI。
- 类别/方法数据先以 hardcode 方式提供，后续可对齐 CAPABILITY_MANIFEST。

## Impact
- Affected specs: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Affected code: `frontend/src/features/step1/Step1.tsx`, `frontend/src/features/step1/methodData.ts`
- Breaking change: NO
- User benefit: 更快给出清晰需求，减少“写得很泛”带来的偏差，提升用户上手与成功率。
