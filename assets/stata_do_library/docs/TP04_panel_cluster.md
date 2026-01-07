# TP04_panel_cluster — 面板聚类标准误

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP04 |
| **Slug** | panel_cluster |
| **名称(中文)** | 面板聚类标准误 |
| **Name(EN)** | Panel Cluster SE |
| **家族** | panel |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Panel regression with clustered standard errors

## 使用场景

- 关键词：panel, cluster, robust_se

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__CLUSTER__` | string | 是 | Cluster variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP04_cluster.dta | data | Output data |
| result.log | log | Execution log |
| table_TP04_cluster_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TP04_comparison.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | vce(cluster) option |

## 示例

```stata
* Template: TP04_panel_cluster
* Script: assets/stata_do_library/do/TP04_panel_cluster.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

