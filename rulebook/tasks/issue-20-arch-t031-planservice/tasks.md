## 1. Implementation
- [ ] Define `LLMPlan` schema (steps + produces + dependencies)
- [ ] Implement deterministic `PlanService.freeze_plan()` and persist plan artifact
- [ ] Ensure repeated freeze is idempotent (no duplicate `artifacts_index` entries)

## 2. Testing
- [ ] Add unit tests for plan generation + freeze + idempotency

## 3. Documentation
- [ ] Update OpenSpec to describe the v1 plan schema + freezing behavior
