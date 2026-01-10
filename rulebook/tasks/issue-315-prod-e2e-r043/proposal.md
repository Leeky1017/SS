# issue-315-prod-e2e-r043 — Proposal

移除 runtime `FakeObjectStore`（upload sessions 生产只允许 S3）：

- runtime 不再允许 `SS_UPLOAD_OBJECT_STORE_BACKEND=fake`（稳定错误码 + 可诊断日志）
- production 启动时校验 S3 配置（缺失则 fail-fast）
- 测试使用注入的 fake object store（仅存在于 `tests/**`）

