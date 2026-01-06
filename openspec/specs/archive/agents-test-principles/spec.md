# Spec — Testing principles in AGENTS

## Goal

将测试编写原则作为团队约定写入 `AGENTS.md`，用于指导后续 SS 的单元/集成测试写法与组织方式。

## Requirements

- `AGENTS.md` 增加 `## 测试编写原则` 章节，包含：
  - 三个目标、命名规范、AAA 模式示例
  - 什么该测/不该测、Mock 原则、覆盖率指导
  - “测试是设计反馈”表格、测试目录组织、运行命令

## Scenarios (verifiable)

### Scenario: repository includes testing principles

Given `AGENTS.md` exists  
When checking the file content  
Then it contains a `## 测试编写原则` section with the required subsections.

