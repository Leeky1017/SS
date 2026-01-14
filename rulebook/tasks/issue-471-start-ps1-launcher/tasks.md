## 1. Implementation
- [x] 1.1 Upgrade `start.ps1` to be a reliable one-command launcher (venv bootstrap + worker lifecycle)
- [x] 1.2 Add/update OpenSpec scenarios for `start.ps1` behavior

## 2. Testing
- [x] 2.1 Run `ruff check .`
- [x] 2.2 Run `pytest -q`
- [ ] 2.3 Windows smoke test: run `start.ps1`, then Ctrl+C and verify worker stops

## 3. Documentation
- [ ] 3.1 Update README usage notes if needed (flags / worker log path)
