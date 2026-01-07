# TQ09_melogit — 多层Logit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TQ09 |
| **Slug** | melogit |
| **名称(中文)** | 多层Logit |
| **Name(EN)** | Multilevel Logit |
| **家族** | multilevel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Multilevel logistic regression

## 使用场景

- 关键词：melogit, multilevel, logistic

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Binary dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__GROUPVAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TQ09_melogit.csv | table | Melogit results |
| data_TQ09_melogit.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | melogit command |

## 示例

```stata
* Template: TQ09_melogit
* Script: assets/stata_do_library/do/TQ09_melogit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

