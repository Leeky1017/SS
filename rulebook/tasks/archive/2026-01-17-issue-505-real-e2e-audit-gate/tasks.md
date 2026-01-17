## 1. Implementation
- [x] 1.1 更新 `scripts/ss_ssh_e2e/flow.py`：显式命中全链路 endpoints；改为 plan/freeze + run；新增负例与 artifacts 强断言
- [x] 1.2 更新 `scripts/ss_ssh_e2e/cli.py` 文案/默认 requirement（移除 confirm）
- [x] 1.3 更新 `scripts/ss_windows_release_gate.py`：加入 restart recoverability 步骤；失败 rollback；结果写入 out_dir

## 2. Testing
- [x] 2.1 `ruff check .`
- [x] 2.2 `pytest -q`
- [x] 2.3 `.venv/bin/python scripts/ss_windows_release_gate.py --out-dir /tmp/...` 在 47.98 实跑并归档证据

## 3. Documentation / Ops Evidence
- [x] 3.1 新增 `openspec/_ops/task_runs/ISSUE-505.md` 并持续追加 Runs（含证据路径）
