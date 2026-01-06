# [ROUND-00-ARCH-A] ARCH-T053: Do 模板库（legacy tasks）接入与契约

## Metadata

- Issue: #36 https://github.com/Leeky1017/SS/issues/36
- Epic: #14 https://github.com/Leeky1017/SS/issues/14
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Goal

明确 SS 内 do 模板库的落盘位置/命名、版本策略、加载接口（TemplateRepository port）与最小校验；MVP 接入最小子集跑通端到端。

## In scope

- OpenSpec：补齐 meta schema / placeholders / outputs 的契约细节
- domain：定义 DoTemplateRepository port（按 template_id 获取模板 + meta）
- infra：实现 FileSystemDoTemplateRepository（从配置路径加载 index + 读取模板文件）
- 安全边界：模板执行仅允许 job/run 工作目录内读写；输出必须登记到 artifacts

## Dependencies & parallelism

- Hard dependencies: #24（runner 执行边界）+ #16
- Soft dependencies: #25（如果把“模板选择/替换”并入统一 do-file 生成策略）
- Parallelizable with: #25（两者最终会在 do-file 生成策略处汇合）

## Acceptance checklist

- [ ] 模板库被当作数据资产管理（不与 tasks 系统混淆）
- [ ] 模板加载/缺失/占位符替换/输出声明一致性 有测试保护
- [ ] end-to-end 最小闭环跑通（选模板→填参→生成→执行→归档）
- [ ] `openspec/_ops/task_runs/ISSUE-36.md` 记录关键命令与输出
