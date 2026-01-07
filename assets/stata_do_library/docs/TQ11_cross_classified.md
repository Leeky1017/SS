# TQ11_cross_classified — 交叉分类模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ11 |
| **Slug** | cross_classified |
| **名称(中文)** | 交叉分类模型 |
| **Name(EN)** | Cross-Classified |
| **家族** | multilevel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Cross-classified multilevel model

## 使用场景

- 关键词：cross_classified, multilevel, mixed

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__GROUP1__` | string | 是 | First grouping |
| `__GROUP2__` | string | 是 | Second grouping |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TQ11_cross.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TQ11_cross.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mixed command |

## 示例

```stata
* Template: TQ11_cross_classified
* Script: assets/stata_do_library/do/TQ11_cross_classified.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

