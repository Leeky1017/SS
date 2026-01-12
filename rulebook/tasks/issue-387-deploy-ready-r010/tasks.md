## 1. Implementation
- [ ] 1.1 Add repo-root `Dockerfile` for `ss:prod`
- [ ] 1.2 Add `.dockerignore` to reduce build context
- [ ] 1.3 Link task card `Issue:` to `#387`
- [ ] 1.4 Add `openspec/_ops/task_runs/ISSUE-387.md`

## 2. Testing
- [ ] 2.1 `docker build -t ss:prod .`
- [ ] 2.2 Start API container (`python -m src.main`) with minimal env
- [ ] 2.3 Start worker container (`python -m src.worker`) with minimal env and `SS_STATA_CMD`

## 3. Documentation
- [ ] 3.1 Document build/run evidence in run log
