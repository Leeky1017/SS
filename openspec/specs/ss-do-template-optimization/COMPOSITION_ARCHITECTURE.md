# Composition Architecture — Adaptive Multi-Data (P3)

## Purpose

Upgrade SS template composition from “single primary dataset chaining” to **adaptive multi-dataset composition** while keeping:
- wiring **explicit** (no implicit state transfer),
- behavior **auditable** (full evidence trail),
- and complexity **minimal** for simple jobs.

This document is a design note for Phase-3 tasking (see task cards under `task_cards/`).

## Non-goals (YAGNI)

- A general DAG/workflow engine (arbitrary graphs, loops, dynamic fan-out).
- Executor-side “guessing” of wiring. Any merge/append/parallel/conditional intent MUST be explicit in the plan.
- True distributed parallelism (parallel mode can be executed sequentially but isolated).

## Data Model

### Dataset roles

SS treats uploaded data files as datasets with a small set of roles:
- `primary_dataset`: main analysis dataset (default target for most templates).
- `secondary_dataset`: datasets intended to be merged/append into the primary dataset.
- `auxiliary_data`: supporting datasets (lookups, classifications, mappings) used by some steps.

Roles are **labels for planning and validation**; they do not imply any automatic wiring.

### Inputs manifest (job-level)

`job.json.inputs.manifest_rel_path` points to an inputs manifest JSON (e.g. `inputs/manifest.json`) that lists uploaded files.
Minimum recommended fields per dataset entry:
- `dataset_key` (string; stable within the job, used by the plan)
- `role` (enum; one of the roles above)
- `filename` (string; original name for UX only)
- `rel_path` (string; job-relative path to the uploaded file)
- `fingerprint` (string; content hash, optional but recommended)

The plan references datasets via `dataset_key` (not by raw paths).

### DatasetRef (plan-level)

To keep plans simple and schema-validatable, use a string `dataset_ref` grammar:
- `input:<dataset_key>` for datasets from the inputs manifest
- `prod:<step_id>:<product_id>` for intermediate products from prior steps

Examples:
- `input:main`
- `prod:merge_controls:merged`

## Execution Modes (closed set)

SS supports a small set of composition modes. The planner MUST pick exactly one for a job, and the executor MUST record it.

### 1) Sequential

Use when there is one dataset (or datasets are already pre-merged) and the analysis is straightforward.

Shape:
- template A → template B → template C

### 2) Merge-then-sequential

Use when 2+ datasets need to become a single analysis dataset first (merge/append).

Shape:
- merge/append step → template A → template B

Notes:
- The merge/append step MUST declare:
  - operation: `merge` | `append`
  - inputs: `primary_dataset` + one or more secondary/aux datasets
  - (merge only) join keys and expected cardinality (e.g. `1:1`, `1:m`) when known

### 3) Parallel-then-aggregate

Use when datasets should be analyzed separately and then summarized/combined (e.g., subgroup splits, multi-country files).

Shape:
- analysis A on D1
- analysis A on D2
- aggregate results

Notes:
- “Parallel” describes data-flow independence; actual execution can be sequential.
- Aggregation is expressed as an explicit final step consuming prior step products.

### 4) Conditional

Use when a later step depends on an explicit predicate over earlier outputs (e.g., “if diagnostics OK then run model B else run model C”).

Shape:
- step A
- condition check (explicit predicate)
- branch B or C

Notes:
- Conditional behavior MUST be explicit in the plan, and the executor MUST record:
  - predicate inputs,
  - predicate evaluation result,
  - which branch was executed and why.

## LLM Plan Contract (Composition-aware)

### Planner responsibilities

The LLM planner MUST output a schema-bound plan that includes:
- `composition_mode` (one of the modes above)
- explicit data-flow bindings (which dataset feeds each step input role)
- declared intermediate products (datasets/tables/figures) for downstream wiring

The executor MUST reject plans that:
- reference unknown datasets,
- produce ambiguous datasets without identifiers,
- or rely on “implicit” default datasets without declaring bindings.

### Recommended plan encoding (LLMPlan v1-compatible)

SS already persists `artifacts/plan.json` as `LLMPlan` with `steps[]` and free-form `params`.
To avoid unnecessary plan version churn, composition metadata is encoded in `params` with reserved keys.

Reserved keys (per step, minimal):
- `composition_mode` (string; required and MUST be identical across all steps)
- `template_id` (string; required for template steps)
- `input_bindings` (object; maps input role → `dataset_ref`)
- `products` (list; declared intermediate products with stable IDs)

`products[]` entries (recommended):
- `product_id` (string; stable within the plan)
- `kind` (`dataset` | `table` | `figure` | `report`)
- `role` (optional; for datasets, may be `primary_dataset` etc.)

### Example (simplified)

```json
{
  "plan_version": 1,
  "plan_id": "…",
  "rel_path": "artifacts/plan.json",
  "steps": [
    {
      "step_id": "merge_controls_generate",
      "type": "generate_stata_do",
      "params": {
        "composition_mode": "merge_then_sequential",
        "template_id": "TA_merge_v1",
        "input_bindings": {
          "primary_dataset": "input:main",
          "secondary_dataset": "input:controls"
        },
        "merge": { "operation": "merge", "keys": ["firm_id", "year"], "cardinality": "1:1" },
        "products": [{ "product_id": "merged", "kind": "dataset", "role": "primary_dataset" }]
      },
      "depends_on": [],
      "produces": ["stata.do"]
    },
    {
      "step_id": "merge_controls_run",
      "type": "run_stata",
      "params": { "timeout_seconds": 300 },
      "depends_on": ["merge_controls_generate"],
      "produces": ["stata.log", "run.meta.json", "run.error.json"]
    }
  ]
}
```

## Executor Contract (minimal, auditable)

### Validation (before execution)

The executor MUST validate that:
- `composition_mode` exists and is in the allowed enum.
- All `dataset_ref` values resolve to either:
  - an inputs-manifest entry (`input:<dataset_key>`), or
  - a prior step product (`prod:<step_id>:<product_id>`).
- All dependencies are satisfiable (topological ordering exists).

### Execution (data-flow correctness)

For each step, the executor MUST:
- materialize required input datasets into the step run workspace explicitly (copy/link rules are deterministic),
- execute the step,
- capture outputs as artifacts,
- and register declared products (by `product_id`) for downstream steps.

### Evidence (required artifacts)

At minimum, produce:
- per-step run directories (inputs + do-file + logs + outputs),
- a pipeline-level `composition_summary.json` artifact that records:
  - `composition_mode`,
  - inputs manifest snapshot (dataset keys/roles/fingerprints),
  - step list with resolved input bindings,
  - produced products (with final artifact paths),
  - merge/aggregate decisions and branch decisions (if any).

This summary is the primary audit artifact for “how data moved through the pipeline”.

