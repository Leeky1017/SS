# Spec (Delta): issue-20-arch-t031-planservice — ss-llm-brain

## Requirements

### Requirement: LLMPlan is schema-bound and replayable

`LLMPlan` MUST be a structured, serializable plan with:
- `plan_version` (int, v1 = 1)
- `steps[]` where each step has:
  - `step_id` (string)
  - `type` (enum)
  - `params` (object; schema depends on type)
  - `depends_on[]` (string list)
  - `produces[]` (artifact kinds; aligned with `ss-job-contract`)

#### Scenario: Plan can be validated and stored
- **WHEN** a plan is generated
- **THEN** it validates against the schema and can be serialized to JSON without loss.

### Requirement: PlanService freezes plan deterministically

`PlanService` MUST:
- load job by `job_id`
- generate a deterministic plan without network access (stub)
- persist the plan into:
  - `job.json` (`llm_plan`)
  - `artifacts/plan.json` (kind: `plan.json`) and index it in `artifacts_index`

#### Scenario: Re-freeze is idempotent
- **WHEN** `freeze_plan()` is called repeatedly with the same inputs
- **THEN** it returns the same plan and does not duplicate artifact index entries.
