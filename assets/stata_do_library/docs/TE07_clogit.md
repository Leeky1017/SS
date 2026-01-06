# TE07_clogit — 条件Logit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE07 |
| **Slug** | clogit |
| **名称(中文)** | 条件Logit |
| **Name(EN)** | Clogit |
| **家族** | limited_dependent |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Conditional logit for matched/grouped data

## 使用场景

- 关键词：clogit, conditional, matched

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__GROUP_VAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TE07_clogit.csv | table | Clogit results |
| data_TE07_clogit.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | clogit command |

## 示例

```stata
* Template: TE07_clogit
* Script: tasks/do/TE07_clogit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

