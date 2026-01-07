# TG16_panel_iv — 面板工具变量

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG16 |
| **Slug** | panel_iv |
| **名称(中文)** | 面板工具变量 |
| **Name(EN)** | Panel IV |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Panel data IV estimation

## 使用场景

- 关键词：iv, panel, fe, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__ENDOG_VAR__` | string | 是 | Endogenous variable |
| `__INSTRUMENTS__` | string | 是 | Instruments |
| `__EXOG_VARS__` | string | 否 | Exogenous controls |
| `__ID_VAR__` | string | 是 | Panel ID |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__METHOD__` | string | 否 | Method: fe/re/ht |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG16_panel_iv.csv | table | Panel IV results |
| table_TG16_diagnostics.csv | table | Diagnostics |
| data_TG16_panel_iv.dta | data | Panel IV data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtivreg2 | ssc | Panel IV |

## 示例

```stata
* Template: TG16_panel_iv
* Script: assets/stata_do_library/do/TG16_panel_iv.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

