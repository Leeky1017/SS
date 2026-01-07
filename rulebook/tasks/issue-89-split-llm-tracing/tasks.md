## 1. Refactor
- [ ] 1.1 Split retry/logging helpers into a dedicated module
- [ ] 1.2 Ensure `src/infra/llm_tracing.py` is `< 300` lines
- [ ] 1.3 Ensure functions remain `< 50` lines

## 2. Evidence
- [ ] 2.1 Record run evidence: `ruff check .`, `pytest -q`, `openspec validate --specs --strict --no-interactive`

