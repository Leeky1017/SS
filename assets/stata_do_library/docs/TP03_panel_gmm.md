# TP03_panel_gmm — 面板GMM

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP03 |
| **Slug** | panel_gmm |
| **名称(中文)** | 面板GMM |
| **Name(EN)** | Panel GMM |
| **家族** | panel |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Dynamic panel GMM estimation (Arellano-Bond)

## 使用场景

- 关键词：panel, gmm, dynamic, arellano_bond

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP03_gmm.dta | data | Output data |
| result.log | log | Execution log |
| table_TP03_diagnostics.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TP03_gmm_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtabond2 | ssc | System GMM |

## 示例

```stata
* Template: TP03_panel_gmm
* Script: assets/stata_do_library/do/TP03_panel_gmm.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

