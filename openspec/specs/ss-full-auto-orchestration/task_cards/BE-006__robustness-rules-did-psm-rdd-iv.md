# Task Card: BE-006 稳健性规则库扩展（DID/PSM/RDD/IV）

- Priority: P1
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/robustness-strategy-rules.md`
  - `openspec/specs/ss-do-template-library/spec.md`

## 问题描述

在基础 OLS/FE 规则稳定后，需要扩展到 DID/PSM/RDD/IV，使系统能覆盖更高阶的因果识别场景，并生成论文期望的稳健性组合。

## 技术分析

- 影响：DID/PSM/RDD/IV 是“全自动代劳服务”竞争力的核心；缺失会导致服务停留在低阶回归代跑。
- 代码定位锚点：
  - `src/domain/do_template_repository.py`
  - `src/domain/plan_contract.py`（识别/表达分析设计）
  - `src/domain/models.py`（`PlanStepType.ROBUSTNESS_CHECK`）

## 解决方案

1. 扩展规则集合：
   - DID：平行趋势（事件研究）、安慰剂、PSM-DID、窗口/组别稳健性
   - PSM：匹配方法/卡尺/邻居数切换、平衡性检验
   - RDD：带宽/阶数稳健性、McCrary 密度、伪阈值
   - IV：弱工具检验、过度识别检验、替代工具（若可）
2. 每条规则必须声明前提条件：
   - 例如 DID 需要 time + group + policy 结构；缺少则跳过并记录原因
3. 补齐测试矩阵：
   - DID/PSM/RDD/IV 各至少 1 个 happy path + 1 个 missing-prereq path

## 验收标准

- [ ] DID/PSM/RDD/IV 各能返回至少 1 条推荐稳健性候选（在前提满足时）
- [ ] 缺少关键前提时不会抛异常，输出可审计 skip reason
- [ ] 单元测试覆盖四类设计的分支

## Dependencies

- BE-005

