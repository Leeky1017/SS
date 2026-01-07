# TQ12_growth_curve — 增长曲线模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ12 |
| **Slug** | growth_curve |
| **名称(中文)** | 增长曲线模型 |
| **Name(EN)** | Growth Curve |
| **家族** | multilevel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Multilevel growth curve modeling

## 使用场景

- 关键词：growth_curve, longitudinal, multilevel

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__GROUPVAR__` | string | 是 | Subject ID |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ12_growth.dta | data | Output data |
| fig_TQ12_growth.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TQ12_growth.csv | table | Growth curve results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mixed command |

## 示例

```stata
* Template: TQ12_growth_curve
* Script: assets/stata_do_library/do/TQ12_growth_curve.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

