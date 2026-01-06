# TR01_spatial_weight — 空间权重

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR01 |
| **Slug** | spatial_weight |
| **名称(中文)** | 空间权重 |
| **Name(EN)** | Spatial Weight |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Create spatial weight matrix

## 使用场景

- 关键词：spatial, weight, matrix

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
| data_TR01_spatial.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TR01_weight_summary.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spmat | stata | Spatial matrix |

## 示例

```stata
* Template: TR01_spatial_weight
* Script: tasks/do/TR01_spatial_weight.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

