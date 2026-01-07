# TR04_moran_test — Moran检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR04 |
| **Slug** | moran_test |
| **名称(中文)** | Moran检验 |
| **Name(EN)** | Moran Test |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Moran's I spatial autocorrelation test

## 使用场景

- 关键词：moran, spatial_autocorrelation, test

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TR04_moran.dta | data | Output data |
| fig_TR04_moran_scatter.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TR04_moran_global.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TR04_moran_local.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spatwmat | ssc | Spatial tests |

## 示例

```stata
* Template: TR04_moran_test
* Script: assets/stata_do_library/do/TR04_moran_test.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

