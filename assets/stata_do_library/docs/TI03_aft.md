# TI03_aft — 加速失效时间模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI03 |
| **Slug** | aft |
| **名称(中文)** | 加速失效时间模型 |
| **Name(EN)** | AFT Model |
| **家族** | survival |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Accelerated Failure Time survival model

## 使用场景

- 关键词：survival, aft, parametric

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TIMEVAR__` | string | 是 | Time variable |
| `__FAILVAR__` | string | 是 | Failure indicator |
| `__INDEPVARS__` | list[string] | 否 | Covariates |
| `__DIST__` | string | 否 | Distribution |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TI03_aft.csv | table | AFT results |
| data_TI03_aft.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | streg command |

## 示例

```stata
* Template: TI03_aft
* Script: assets/stata_do_library/do/TI03_aft.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

