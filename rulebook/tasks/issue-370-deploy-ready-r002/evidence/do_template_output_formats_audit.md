# DEPLOY-READY-R002 — do-template 输出格式能力审计（基于 `assets/stata_do_library/`）

## Scope & sources

- Meta inventory: `assets/stata_do_library/do/meta/*.meta.json` (310 files)
- Template source (sampled): `assets/stata_do_library/do/*.do`
- Repro tool: `scripts/audit_do_template_output_formats.py`

本审计以 meta 的 `outputs[]` 为主口径，并用模板源码抽样核对输出的实现方式（命令/anchor）。

## Output format capability matrix (csv/xlsx/dta/docx/pdf/log/do)

| Format | Declared in meta (#templates) | Produced by templates? | Typical implementation | Notes / examples |
| --- | ---: | --- | --- | --- |
| `csv` | 288 | Yes | `export delimited using "<...>.csv", replace` + `SS_OUTPUT_FILE` | 主流输出；但部分“数据集 CSV”被标成 `type=table`（见 T03） |
| `xlsx` | 1 | Yes | `putexcel set "<...>.xlsx", replace` + `SS_OUTPUT_FILE` | 仅 `TO04_putexcel`；未发现 `export excel` |
| `dta` | 252 | Yes | `save "<...>.dta", replace` + `SS_OUTPUT_FILE` | 多数模板将“输出数据集”写成 `.dta`；另有约 50 个模板含 `converted_from_csv` 的 `data.dta` 转换输出 |
| `docx` | 15 | Yes | `putdocx ...` / `putdocx save "<...>.docx", replace` + `SS_OUTPUT_FILE` | 仅少数模板；meta `dependencies[]` 对 `putdocx` 声明不完整（9 个模板缺失） |
| `pdf` | 1 | Yes (figure only) | `graph export "<...>.pdf", replace` + `SS_OUTPUT_FILE` | 当前 PDF 仅用于图形导出（`TO07_graph_export`），非报告 PDF；未发现 `putpdf` |
| `log` | 310 | Yes | `log using "result.log", text replace` | 所有模板均写 `result.log`；通常不通过 `SS_OUTPUT_FILE` anchor 声明 |
| `do` | 0 | No (runner-level) | N/A | `.do` 应由 SS runner 作为“执行脚本”原始 artifact 捕获并索引，而非模板自行产出 |

## Other output extensions currently present (non-required)

meta `outputs[]` 里还出现（需要被统一输出格式器“保留/索引/可下载”，即使不在默认 output_formats 中）：

- `png`: 110 templates (`type=graph`/`type=figure`)
- `rtf`: 2 templates (`T17`, `T18`) via `file open ... table_*.rtf`
- `html`: 1 template (`TO01`) via `collect export ..., as(html)`
- `tex`: 1 template (`TO02`) via `collect export ..., as(tex)`
- `txt`: 1 template (`T50`) via `outputs/manifest.txt`

## Word / PDF feasibility & current gaps (for DEPLOY-READY-R031)

### Word (`docx`)

- **现状**：已有 15 个模板通过 `putdocx` 直接生成 `.docx`（例如 `T21_ols_with_interaction.do`）。
- **差距**：meta `dependencies[]` 对 `putdocx` 声明不一致：`docx` 输出模板中有 9 个未声明 `putdocx`。
- **可行策略**（按“改动成本”从低到高）：
  1) **Output Formatter 后处理**：基于已存在的 `csv/dta/png` 产物生成报告（可选：Stata post-run `putdocx` 统一模版；或 Python 生成 docx）。优点是避免逐模板补齐。
  2) **模板级输出**：逐模板补齐 `putdocx` 报告逻辑（内容质量可控但工作量大）。

### PDF (`pdf`)

- **现状**：仅发现 `TO07_graph_export.do` 使用 `graph export ... .pdf` 生成图形 PDF。
- **差距**：未发现任何 `putpdf`；目前不存在“报告型 PDF”输出（`pdf` 只覆盖 figure，不覆盖 report/table）。
- **可行策略**：
  1) **优先 `putpdf`**：在 Stata 层实现报告型 PDF（模板级或 formatter 级）。
  2) **docx→pdf 转换**：如果部署镜像允许引入转换工具（例如 LibreOffice/Pandoc），可以把 docx 报告转换为 pdf（但会引入额外系统依赖，需在 Docker readiness 中明确）。

## Artifact kind / naming consistency findings

### 1) `type`/`kind` 口径不统一

- meta 使用 `outputs[].type`：`table/log/data/graph/figure/report/manifest`
- 模板运行时使用 `SS_OUTPUT_FILE|...|type=...`（同样是 `type`）
- job contract 期望使用枚举化 `artifact.kind`（例如 `stata.do`, `stata.log`, `stata.export.table`, `stata.export.figure`）

建议 DEPLOY-READY-R031 明确拆分两类信息：

- `output_format`: 由文件扩展名决定（`csv/xlsx/dta/docx/pdf/log/do/...`）
- `artifact_kind`: 语义种类（建议映射到 job contract 的枚举词表）

### 2) meta 与 SS_OUTPUT_FILE 的 `type` 存在不一致

- `TO07_graph_export`: meta 对 `fig_TO07_scatter.pdf/png` 的 `type`=`graph`，但模板 anchor 写的是 `type=figure`。

### 3) 文件命名与语义存在混用

- `T03_filter_and_sample`: `table_T03_filtered_data.csv` 实际是输出数据集，但被命名为 `table_...` 且 `type=table`。
- 多个 docx 输出文件名以 `table_..._paper.docx` 命名，但 `type=report`（语义是“报告/论文表格”，不是“纯 csv table”）。

建议 R031 的 formatter/索引逻辑 **不要依赖文件名前缀** 来判断语义；应以（a）`SS_OUTPUT_FILE` anchor 的字段（b）meta outputs（c）扩展名 组合推断，并在必要时做归一化。

## Dependency declaration findings (meta)

- `dependencies[]` 总条目数：303（310 个模板中部分未显式列出任何依赖）
- `source` 计数：`built-in`=263, `ssc`=26, `stata`=14
- 观察：`pkg=stata` 常作为泛化依赖；部分模板使用到 `putdocx`/`putexcel`/`collect export` 等特性，但 meta 里未必精确声明对应 `pkg`。

对 DEPLOY-READY-R031 的建议：把 meta `dependencies[]` 视为“提示”，不要作为严格 gate；严格 gate 需要 runner/formatter 在执行时通过能力探测/错误码明确失败（例如缺少 SSC 时 fail fast）。

## Evidence pointers

- Inventory + counts: `scripts/audit_do_template_output_formats.py`
- Key examples:
  - CSV + log: `assets/stata_do_library/do/T01_desc_overview.do`
  - DTA + CSV dataset: `assets/stata_do_library/do/T03_filter_and_sample.do`
  - DOCX report: `assets/stata_do_library/do/T21_ols_with_interaction.do`
  - XLSX: `assets/stata_do_library/do/TO04_putexcel.do`
  - PDF figure: `assets/stata_do_library/do/TO07_graph_export.do`
  - HTML/TEX: `assets/stata_do_library/do/TO01_esttab_html.do`, `assets/stata_do_library/do/TO02_esttab_latex.do`

