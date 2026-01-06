# TN01_spmatrix — 空间权重矩阵

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TN01 |
| **Slug** | spmatrix |
| **名称(中文)** | 空间权重矩阵 |
| **Name(EN)** | Spatial Matrix |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Create spatial weight matrix

## 使用场景

- 关键词：spatial, weight_matrix, econometrics

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__LAT__` | string | 是 | Latitude |
| `__LON__` | string | 是 | Longitude |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TN01_spmat.dta | data | Output data |
| result.log | log | Execution log |
| spmat_TN01.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spmat | stata | Spatial matrix |

## 示例

```stata
* Template: TN01_spmatrix
* Script: tasks/do/TN01_spmatrix.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

