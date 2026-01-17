## 1. Implementation
- [ ] 1.1 Baseline-check remote runtime (ready + schtasks + queue depth) and record in run log.
- [ ] 1.2 Add repo-native remote E2E runner (SSH tunnel + v1 flow + artifact verification + on-failure diagnostics).
- [ ] 1.3 Replace release/deploy gate to require real E2E (no dual-path), with rollback on failure.

## 2. Testing
- [ ] 2.1 Add unit coverage for any pure helpers (artifact assertions, redaction, parsing).
- [ ] 2.2 Run `ruff check .` and `pytest -q` and record outputs in run log.
- [ ] 2.3 Deploy and run remote E2E on `47.98.174.3` until stable.

## 3. Documentation
- [ ] 3.1 Keep evidence in `openspec/_ops/task_runs/ISSUE-503.md` (no new `docs/` content).
- [ ] 3.2 Update relevant OpenSpec(s) if any authoritative deployment gate text is present.
