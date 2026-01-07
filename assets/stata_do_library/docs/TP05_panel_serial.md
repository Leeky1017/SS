# TP05_panel_serial — 面板序列相关检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP05 |
| **Slug** | panel_serial |
| **名称(中文)** | 面板序列相关检验 |
| **Name(EN)** | Panel Serial Correlation |
| **家族** | panel |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Test for serial correlation in panel data

## 使用场景

- 关键词：panel, serial_correlation, diagnostics

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
| data_TP05_serial.dta | data | Output data |
| result.log | log | Execution log |
| table_TP05_serial_tests.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtserial | ssc | Wooldridge test |

## 示例

```stata
* Template: TP05_panel_serial
* Script: assets/stata_do_library/do/TP05_panel_serial.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

