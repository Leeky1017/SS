# TS08_cluster_kmeans — K均值聚类

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS08 |
| **Slug** | cluster_kmeans |
| **名称(中文)** | K均值聚类 |
| **Name(EN)** | K-Means Clustering |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

K-means clustering with elbow method for optimal K

## 使用场景

- 关键词：kmeans, clustering, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Clustering variables |
| `__K__` | integer | 否 | Number of clusters |
| `__MAX_K__` | integer | 否 | Max K for elbow method |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TS08_centers.csv | table | Cluster centers |
| table_TS08_elbow.csv | table | Elbow data |
| fig_TS08_elbow.png | graph | Elbow plot |
| data_TS08_kmeans.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | cluster kmeans command |

## 示例

```stata
* Template: TS08_cluster_kmeans
* Script: assets/stata_do_library/do/TS08_cluster_kmeans.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

