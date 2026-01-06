# TK02_fama_french — Fama-French模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK02 |
| **Slug** | fama_french |
| **名称(中文)** | Fama-French模型 |
| **Name(EN)** | Fama-French Model |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Fama-French three/five factor model estimation

## 使用场景

- 关键词：fama_french, factor_model, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__MKT_VAR__` | string | 是 | Market factor |
| `__SMB_VAR__` | string | 是 | SMB factor |
| `__HML_VAR__` | string | 是 | HML factor |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK02_ff.dta | data | Output data |
| fig_TK02_alpha_dist.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK02_factor_loadings.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK02_ff_result.csv | table | FF results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TK02_fama_french
* Script: tasks/do/TK02_fama_french.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

