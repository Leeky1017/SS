# TG11_rdd_bandwidth — RDD带宽选择

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG11 |
| **Slug** | rdd_bandwidth |
| **名称(中文)** | RDD带宽选择 |
| **Name(EN)** | RDD Bandwidth |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

RDD optimal bandwidth selection

## 使用场景

- 关键词：rdd, bandwidth, mse, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME_VAR__` | string | 是 | Outcome variable |
| `__RUNNING_VAR__` | string | 是 | Running variable |
| `__CUTOFF__` | number | 是 | Cutoff value |
| `__BW_RANGE__` | string | 否 | Bandwidth range |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG11_bandwidth_results.csv | table | Bandwidth results |
| table_TG11_sensitivity.csv | table | Sensitivity results |
| fig_TG11_bandwidth_plot.png | figure | Bandwidth plot |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| rdrobust | ssc | RDD bandwidth |

## 示例

```stata
* Template: TG11_rdd_bandwidth
* Script: tasks/do/TG11_rdd_bandwidth.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

