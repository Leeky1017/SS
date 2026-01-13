## 1. Implementation
- [x] 1.1 Add plan generation input models (`PlanGenerationInput`, `DataSchema`, `PlanConstraints`)
- [x] 1.2 Extend plan schema (`LLMPlan.plan_source`, `PlanStep.purpose`, `PlanStep.fallback_step_id`)
- [x] 1.3 Add new `PlanStepType` values for semantic planning steps
- [x] 1.4 Implement `plan_generation_llm` prompt builder + parser
- [x] 1.5 Implement PlanService `generate_plan_with_llm()` + fallback to rule plan
- [x] 1.6 Persist fallback reason in plan artifact when falling back

## 2. Testing
- [x] 2.1 Unit tests: prompt builder + parser
- [x] 2.2 Unit tests: fallback logic (parse/schema/unsupported step type)
- [x] 2.3 Unit tests: integrates with template selection (uses selected template ids)

## 3. Documentation
- [x] 3.1 Add spec delta in Rulebook task
- [x] 3.2 Update canonical spec `openspec/specs/ss-llm-brain/spec.md`
