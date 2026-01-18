# Task cards: ss-ux-remediation

本目录将 SS UX 全面修复拆成**独立可执行**的任务卡。

## 执行轮次规划

### Wave 1: 功能解锁（P0-BLOCKER）

- BE-006: 辅助文件列纳入候选
- BE-007: 列名标准化
- BE-008: ID/Time 变量选择
- BE-009: Plan freeze 错误结构化
- BE-005: 辅助文件 Sheet 选择
- FE-043: 可操作错误信息

### Wave 2: 核心 UX（P1-HIGH）

**CSS/布局**: FE-007, FE-009, FE-010, FE-019, FE-020, FE-023, FE-024, FE-025

**交互反馈**: FE-001, FE-002, FE-006, FE-057

**状态管理**: FE-032, FE-035, FE-038

### Wave 3: 异常处理

BE-004, FE-030, FE-034, FE-037, FE-039, FE-040, FE-041, FE-053, FE-054, FE-055

### Wave 4: 上传下载

BE-001, BE-002, BE-003, FE-026, FE-027, FE-028, FE-029, FE-036, FE-056

### Wave 5: 可访问性 & i18n（P2-MEDIUM）

FE-003, FE-008, FE-012, FE-014, FE-016, FE-045, FE-047, FE-048, FE-049, FE-050

### Wave 6: 打磨收尾（P2/P3）

FE-004, FE-005, FE-011, FE-013, FE-015, FE-017, FE-018, FE-021, FE-022, FE-031, FE-033, FE-042, FE-044, FE-046, FE-051, FE-052, FE-058, FE-059, FE-060, FE-061, FE-062, FE-063, FE-064

### 验收

E2E-001: 面板回归完整工作流

## 约定（强制）

- 每张卡必须包含：问题描述 / 技术分析 / 解决方案 / 验收标准 / 优先级 / Dependencies
- 后端任务先行，完成后运行 `scripts/contract_sync.sh generate` 再改前端
