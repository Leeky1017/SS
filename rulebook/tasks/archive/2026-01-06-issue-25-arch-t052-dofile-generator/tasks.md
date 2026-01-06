## 1. Spec-first
- [ ] 1.1 Update `openspec/specs/ss-stata-runner/spec.md` with DoFileGenerator contract + scenarios

## 2. Implementation
- [ ] 2.1 Add domain `DoFileGenerator` (plan + inputs manifest → do-file + expected outputs)
- [ ] 2.2 Support minimal template: load data, describe/summarize, export a basic table artifact
- [ ] 2.3 Capture exported table into run artifacts on `LocalStataRunner` runs

## 3. Testing
- [ ] 3.1 Add unit tests for deterministic generation and manifest/plan edge cases
- [ ] 3.2 Add unit test for exported table artifact capture (no real Stata dependency)
- [ ] 3.3 Run `ruff check .` and `pytest -q` and record outputs in `openspec/_ops/task_runs/ISSUE-25.md`

## 4. Delivery
- [ ] 4.1 Ensure `openspec/_ops/task_runs/ISSUE-25.md` exists and is updated
- [ ] 4.2 Open PR with `Closes #25` and enable auto-merge
