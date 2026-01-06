# TM06_meta_analysis — Meta分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM06 |
| **Slug** | meta_analysis |
| **名称(中文)** | Meta分析 |
| **Name(EN)** | Meta Analysis |
| **家族** | medical |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Fixed and random effects meta-analysis

## 使用场景

- 关键词：meta, forest_plot, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__EFFECT__` | string | 是 | Effect size |
| `__SE__` | string | 是 | Standard error |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM06_meta.csv | table | Meta results |
| fig_TM06_forest.png | graph | Forest plot |
| data_TM06_meta.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| metan | ssc | Meta-analysis |

## 示例

```stata
* Template: TM06_meta_analysis
* Script: tasks/do/TM06_meta_analysis.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

