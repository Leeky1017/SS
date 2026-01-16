## 1. Implementation
- [ ] 1.1 审计现有错误响应与错误码（run log 记录发现清单）
- [ ] 1.2 审计关键链路结构化日志覆盖（API/状态机/LLM/Stata）
- [ ] 1.3 落地最小共享组件：错误映射与日志字段（不引入新功能）
- [ ] 1.4 逐端点/服务对齐错误处理与日志事件码
- [ ] 1.5 同步 `ERROR_CODES.md`（新增/变更错误码）

## 2. Testing
- [ ] 2.1 `ruff check .`
- [ ] 2.2 `mypy`
- [ ] 2.3 `pytest -q`
- [ ] 2.4 `pytest tests/e2e/ -q`

## 3. Documentation
- [ ] 3.1 新增 `openspec/_ops/task_runs/ISSUE-499.md`（审计发现 + 修复清单 + 关键命令输出）
