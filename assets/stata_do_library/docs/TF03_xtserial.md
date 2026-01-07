# TF03_xtserial — 面板序列相关检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF03 |
| **Slug** | xtserial |
| **名称(中文)** | 面板序列相关检验 |
| **Name(EN)** | XTSERIAL |
| **家族** | panel_data |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Wooldridge test for serial correlation

## 使用场景

- 关键词：panel, serial-correlation, wooldridge

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF03_serial.csv | table | Serial correlation results |
| data_TF03_serial.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtserial | ssc | Wooldridge test |

## 示例

```stata
* Template: TF03_xtserial
* Script: assets/stata_do_library/do/TF03_xtserial.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

