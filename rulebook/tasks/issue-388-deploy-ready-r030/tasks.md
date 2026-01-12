## 1. Implementation
- [ ] 1.1 补齐形态敏感模板的 `tags`（wide/long/panel）
- [ ] 1.2 增加 `__ID_VAR__`/`__PANELVAR__` 渲染别名映射（不破坏现有模板）
- [ ] 1.3 更新能力矩阵与证据指针（基于库现状）

## 2. Testing
- [ ] 2.1 pytest：别名映射路径回归（`__ID_VAR__` → required `__PANELVAR__`）
- [ ] 2.2 pytest：wide/long/panel tag 覆盖回归（至少 1 个新增覆盖点）

## 3. Documentation
- [ ] 3.1 Delta spec + evidence（Rulebook）
- [ ] 3.2 更新 OpenSpec task card 元数据与 run log
