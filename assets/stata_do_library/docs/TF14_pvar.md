# TF14_pvar — 面板VAR

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF14 |
| **Slug** | pvar |
| **名称(中文)** | 面板VAR |
| **Name(EN)** | PVAR |
| **家族** | panel_data |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Panel VAR model for dynamic panel relationships

## 使用场景

- 关键词：panel, var, irf

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | string | 是 | VAR variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIME_VAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF14_pvar.csv | table | PVAR results |
| fig_TF14_irf.png | figure | IRF plot |
| data_TF14_pvar.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| pvar | ssc | Panel VAR |

## 示例

```stata
* Template: TF14_pvar
* Script: assets/stata_do_library/do/TF14_pvar.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

