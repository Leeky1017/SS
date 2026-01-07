# TI05_stcox_strata — 分层Cox模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI05 |
| **Slug** | stcox_strata |
| **名称(中文)** | 分层Cox模型 |
| **Name(EN)** | Stratified Cox |
| **家族** | survival |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Stratified Cox proportional hazards model

## 使用场景

- 关键词：survival, cox, stratified

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
| `__STRATA__` | string | 是 | Stratification variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TI05_stratacox.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TI05_stratacox.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | stcox command |

## 示例

```stata
* Template: TI05_stcox_strata
* Script: assets/stata_do_library/do/TI05_stcox_strata.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

