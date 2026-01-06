# Spec — Legacy analysis inputs policy (stata_service)

## Goal

保留 `stata_service` 的“需求与边界案例”洞见作为参考输入，同时明确：SS 的权威工程约束来自 OpenSpec（尤其是 `ss-constitution`），不得被旧工程实现细节误导。

## Requirements

- Legacy analysis MUST 只用于：
  - 需求语义校对（端点语义、状态机概念、产物类型）
  - 边界条件/错误路径枚举（例如数据损坏、缺失输入、重试策略）
  - 回归测试样例来源（把“旧系统怎么做”转成“新系统应保证的行为”）
- Legacy analysis MUST NOT 用于复制旧架构模式：
  - 动态代理/隐式依赖（`__getattr__`、`_ap()` 等）
  - 全局单例 re-export
  - 超大 routes 文件把业务/IO/调度揉在一起
  - 吞异常继续执行
- Legacy analysis SHOULD 落在 OpenSpec 下，并且明确标注“非权威实现指南，仅用于语义与边界案例参考”。详情见 `openspec/specs/stata-service-legacy-analysis/analysis.md`。

## Scenarios (verifiable)

### Scenario: legacy analysis exists but is not treated as canonical architecture

Given `openspec/specs/stata-service-legacy-analysis/analysis.md` exists  
When implementing SS features  
Then architectural constraints are taken from `openspec/specs/ss-constitution/spec.md`, and legacy is used only as input for semantics and test vectors.

