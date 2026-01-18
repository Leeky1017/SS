# Task Card: BE-013 中介效应模板组（Baron-Kenny/Sobel/Bootstrap）

- Priority: P1
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`

## 问题描述

蓝图要求机制分析覆盖中介效应的主流方法（Baron-Kenny/Sobel/Bootstrap）。当前模板库缺失（或未成组暴露）这些机制检验模板，Planner 即便识别到机制也无法落地执行。

## 技术分析

- 影响：机制分析无法执行会阻断“论文完整闭环”，无法满足高阶实证论文结构。
- 代码定位锚点：
  - `src/domain/do_template_repository.py`（模板注册/读取）
  - `src/domain/do_template_selection_service.py`（模板选择链路）
  - `src/domain/models.py`（`PlanStepType` 与 products 机制）

## 解决方案

1. 在 `assets/stata_do_library/` 新增中介效应模板组：
   - Baron-Kenny 三步回归
   - Sobel 检验
   - Bootstrap 中介效应（如适用）
2. 为每个模板补齐 meta/params/contract（按模板库规范），并进入可选模板索引
3. 增加最小测试/校验（复用现有 do-library schema 校验测试）：
   - 模板 meta schema 合法
   - 模板 family/tags 可被索引与选择

## 验收标准

- [ ] 新增模板可被 `DoTemplateRepository` 索引读取
- [ ] 模板 meta/params/contract 通过现有 do-library 校验测试
- [ ] Planner 可引用这些模板 id（以便后续插入 `mechanism_analysis` steps）

## Dependencies

- BE-012

