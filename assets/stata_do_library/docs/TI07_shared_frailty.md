# TI07_shared_frailty — 共享脆弱性模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI07 |
| **Slug** | shared_frailty |
| **名称(中文)** | 共享脆弱性模型 |
| **Name(EN)** | Shared Frailty |
| **家族** | survival |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Cox model with shared frailty for clustered survival data

## 使用场景

- 关键词：survival, frailty, clustered

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TIME_VAR__` | string | 是 | Time variable |
| `__FAILVAR__` | string | 是 | Failure indicator |
| `__INDEPVARS__` | list[string] | 否 | Covariates |
| `__GROUPVAR__` | string | 是 | Cluster variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TI07_frailty.csv | table | Frailty model results |
| data_TI07_frailty.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | stcox shared command |

## 示例

```stata
* Template: TI07_shared_frailty
* Script: assets/stata_do_library/do/TI07_shared_frailty.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

