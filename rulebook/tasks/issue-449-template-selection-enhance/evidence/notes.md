# Notes: Issue #449

## Decisions
- Use V2 schemas for stage1/stage2 prompting; still accept V1 outputs for resilience.
- Persist primary selection to `job.selected_template_id`; supplementary templates remain as evidence/artifacts for now.

## Later
- Consider extending plan generation to accept multi-template pipelines once execution supports composition.

