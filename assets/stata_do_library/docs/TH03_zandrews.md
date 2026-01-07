# TH03_zandrews — 结构断点检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH03 |
| **Slug** | zandrews |
| **名称(中文)** | 结构断点检验 |
| **Name(EN)** | Zivot-Andrews Test |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Zivot-Andrews structural break unit root test

## 使用场景

- 关键词：structural_break, unit_root, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |
| `__TIME_VAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH03_za.csv | table | ZA results |
| data_TH03_za.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| zandrews | ssc | ZA test |

## 示例

```stata
* Template: TH03_zandrews
* Script: assets/stata_do_library/do/TH03_zandrews.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

