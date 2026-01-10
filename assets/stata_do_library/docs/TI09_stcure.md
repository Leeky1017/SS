# TI09_stcure — 治愈模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI09 |
| **Slug** | stcure |
| **名称(中文)** | 治愈模型 |
| **Name(EN)** | Cure Model |
| **家族** | survival |
| **等级** | L2 |
| **版本** | 2.0.2 |

## 功能描述

Mixture cure survival model (built-in approximation)

## 使用场景

- 关键词：survival, cure, mixture

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

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TI09_cure.csv | table | Cure model results |
| data_TI09_cure.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

无（仅依赖 Stata 内置命令）

## 示例

```stata
* Template: TI09_stcure
* Script: assets/stata_do_library/do/TI09_stcure.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

