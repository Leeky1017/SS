# DEPLOY-READY-R001 — do-template 数据形态能力审计（wide / long / panel）

## Scope（审计范围）
- 资产库：`assets/stata_do_library/`
- 审计对象：`assets/stata_do_library/do/*.do`（310）+ `assets/stata_do_library/do/meta/*.meta.json`（310）
- 证据口径：以 **do-file 实际行为** + **meta 合同（inputs/parameters/tags）** 为准；docs 仅作辅助说明。

## Definitions（数据形态定义）
- **Wide（宽表 / many columns）**：同一实体的多期/多状态信息展开为多列（例如 `roa2019 roa2020`），或“before/after”成对变量在同一行。
- **Long（长表 / tidy）**：一条观测一行（例如 `id time value`），多期/多状态以行堆叠表示。
- **Panel（面板数据）**：长表 + 明确 `entity/time` 键，且模板内执行 `xtset`/面板变换/面板估计。

## Boundaries（必须/可选/不支持 的判定边界）
- **必须支持（MUST）**：模板显式声明并验证/设置该形态的关键结构（如 `reshape` / `xtset`），且 meta 中暴露必要参数（如 `__ID_VAR__`, `__TIME_VAR__`）。
- **可选支持（OPTIONAL）**：模板能在该形态上运行，但未做形态/键完整性验证；需要调用者自行保证语义正确（否则可能“能跑但结论不对”）。
- **不支持（NOT）**：模板逻辑依赖另一种形态（例如必须存在成对列变量），不做转换；在目标形态下将失败或产生不可解释输出。

## 宽/长/面板能力矩阵（结论 + 证据指针）

| 数据形态 | 结论 | 覆盖情况（按模板家族/关键路径） | 证据指针（模板 id + 关键位置） |
|---|---|---|---|
| **Wide** | **MUST** | 大多数统计/回归模板以“列变量”为输入，适配宽表（many columns）场景；部分模板明确依赖成对列变量（典型宽表专用）。 | `T01`（多变量列表处理）：`assets/stata_do_library/do/T01_desc_overview.do#L125`；`T14`（成对变量强依赖，体现宽表专用）：`assets/stata_do_library/do/T14_ttest_paired.do#L116`；`T06`（可将 long→wide）：`assets/stata_do_library/do/T06_reshape_wide_long.do#L235` + meta `assets/stata_do_library/do/meta/T06_reshape_wide_long.meta.json#L49` |
| **Long** | **MUST（但需转换链路）** | 库内存在显式 wide↔long 转换模板；多数“逐行观测”的分析模板可在 long 上运行，但对“同一实体多期列”的宽表方法需先 reshape。 | `T06`（识别当前形态 + 执行 reshape）：`assets/stata_do_library/do/T06_reshape_wide_long.do#L167` + `assets/stata_do_library/do/T06_reshape_wide_long.do#L235`；meta（方向/ID/time/stub 参数）：`assets/stata_do_library/do/meta/T06_reshape_wide_long.meta.json#L49` |
| **Panel** | **MUST** | 面板关键路径覆盖：面板结构预检/设置、平衡化/去重、以及多种面板估计器与稳健标准误。 | `T30`（面板预检 + `ss_smart_xtset`）：`assets/stata_do_library/do/T30_panel_setup_check.do#L118` + `assets/stata_do_library/do/T30_panel_setup_check.do#L138`；`T31`（面板 FE：变量检查 + `ss_smart_xtset`）：`assets/stata_do_library/do/T31_panel_fe_basic.do#L140` + `assets/stata_do_library/do/T31_panel_fe_basic.do#L159`；`TA06`（平衡化：去重 + `xtset`）：`assets/stata_do_library/do/TA06_panel_balance.do#L167` + `assets/stata_do_library/do/TA06_panel_balance.do#L172`；`ss_smart_xtset`（字符串键→数值/去重/xtset）：`assets/stata_do_library/do/includes/ss_smart_xtset.ado#L24` + `assets/stata_do_library/do/includes/ss_smart_xtset.ado#L90` |

## Coverage notes（覆盖面观察，用于审计透明度）
- meta `tags` 中包含 `panel`：39/310；`family == "panel"`：14/310（其余为“非面板家族但依赖面板结构”的模板，如部分 DID/稳健误差等）。
- do-file 关键词覆盖（用于粗粒度盘点）：包含 `xtset` 的模板 51 个；包含 `tsset` 的模板 30 个；包含 `reshape` 的模板 12 个。
- meta 中显式声明 `wide/long` 的仅 `T06`（说明：wide/long 形态信息主要隐含在模板逻辑与参数语义中，尚未形成统一的 meta 口径）。

## Risks & gaps（风险项与缺口）
- **缺口：wide/long 形态要求缺少统一 machine-readable 标注**：除 `T06` 外，meta 层基本不直接声明“要求宽/长”；导致自动路由/预检难以仅靠 meta 完成，审计只能依赖代码与人工解释。
- **风险：wide-only 方法在 long 数据上容易误用**：例如成对变量检验类模板要求“两个列变量同一行”，在 long 结构下需要先 reshape（否则失败或需要人工改写）。
- **风险：panel 参数命名不统一**：同类模板在 meta/代码中出现 `__ID_VAR__` 与 `__PANELVAR__` 并存，自动化填参/前置检查需要额外映射层。
- **风险：部分 panel 能力依赖 SSC 包**（如 `TF05` 的 `xtabond2`）：部署侧需要配套依赖安装策略，否则“面板能力存在但不可用”。

## 缺口 → 整改任务映射（DEPLOY-READY-R030）
- **R030-A（meta 口径整改）**：为模板补充统一的数据形态声明（建议新增 `data_shape` 或标准化 `tags`，并配套 schema + CI 校验），使“宽/长/面板矩阵”可自动生成且可回归。
- **R030-B（形态错配的最小可复现用例）**：为 wide-only（如 `T14`）与 panel-only（如 `T31`）分别补充最小输入 fixture + smoke 路径，并在矩阵中标注“需先 T06 reshape”的强依赖链路。
- **R030-C（参数命名一致性）**：在不破坏现有模板的前提下，统一/别名化 `__ID_VAR__` vs `__PANELVAR__`（至少在 runner 层做映射），降低调用侧耦合与误填参风险。
