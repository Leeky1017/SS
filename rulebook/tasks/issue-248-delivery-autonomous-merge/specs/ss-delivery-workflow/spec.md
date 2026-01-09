# Spec Delta: issue-248-delivery-autonomous-merge

## Requirements (delta)
- Auto-merge must be verified as actually merged (`mergedAt != null`) before considering delivery complete.
- SS repository settings must support fully autonomous merges (no human approvals), either by allowing admin bypass or by providing a bot/app that can approve/merge.
