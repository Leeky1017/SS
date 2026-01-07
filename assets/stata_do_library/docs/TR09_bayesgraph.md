# TR09_bayesgraph — 贝叶斯诊断图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR09 |
| **Slug** | bayesgraph |
| **名称(中文)** | 贝叶斯诊断图 |
| **Name(EN)** | Bayesian Diagnostics |
| **家族** | bayesian |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Bayesian MCMC diagnostic plots

## 使用场景

- 关键词：bayesian, diagnostics, mcmc, trace

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__MODEL__` | string | 是 | Model to diagnose |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TR09_diag.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TR09_acf.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| fig_TR09_trace.png | graph | Trace plot |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | bayesgraph |

## 示例

```stata
* Template: TR09_bayesgraph
* Script: assets/stata_do_library/do/TR09_bayesgraph.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

