# TF09_xtlogit — 面板Logit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF09 |
| **Slug** | xtlogit |
| **名称(中文)** | 面板Logit |
| **Name(EN)** | XTLOGIT |
| **家族** | panel_data |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Panel Logit model with fixed effects

## 使用场景

- 关键词：panel, logit, fixed-effects

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIME_VAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF09_xtlogit.csv | table | Panel Logit results |
| data_TF09_xtlogit.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtlogit command |

## 示例

```stata
* Template: TF09_xtlogit
* Script: assets/stata_do_library/do/TF09_xtlogit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

