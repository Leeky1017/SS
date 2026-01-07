# TE04_heckman — Heckman选择模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE04 |
| **Slug** | heckman |
| **名称(中文)** | Heckman选择模型 |
| **Name(EN)** | Heckman |
| **家族** | limited_dependent |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Heckman two-stage selection model

## 使用场景

- 关键词：heckman, selection, sample-selection

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__SELECT_VAR__` | string | 是 | Selection variable |
| `__SELECT_VARS__` | string | 是 | Selection equation variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TE04_heck.csv | table | Heckman results |
| data_TE04_heck.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | heckman command |

## 示例

```stata
* Template: TE04_heckman
* Script: assets/stata_do_library/do/TE04_heckman.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

