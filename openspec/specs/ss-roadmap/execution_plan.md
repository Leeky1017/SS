# SS 执行路线图（依赖图 & 并行策略）

本文件把 roadmap 子 Issue 变成“可执行顺序”，并明确哪些可以并行、哪些必须先做依赖。

说明：
- “依赖”以 hard dependency 为准：不做完会阻塞后续任务验收或会导致接口反复返工。
- “可并行”表示逻辑可并行，但 PR 合并仍由 `merge-serial` 串行化；并行开发应尽量减少同文件冲突。

## 0) 必须先做（Foundation）

1. #16（job.json v1 + models）是全链路的数据合同基座。
2. #17（状态机 + 幂等）依赖 #16，并且会影响 run trigger、worker 推进与重试语义。

结论：
- #16 MUST first。
- #17 MUST after #16。

## 1) #16 完成后，可三路并行推进

### Lane A：API Read-only（低风险并行）

- #18（GET /jobs/{job_id}）hard depends on：#16

### Lane B：LLM Trace（并行，但会触及 artifacts/index）

- #21（LLM 调用 artifacts）hard depends on：#16

### Lane C：Runner 基座（并行）

- #24（StataRunner port + LocalStataRunner）hard depends on：#16

建议：
- 这三条 lane 可以并行开发，避免改同一个 domain model 文件导致冲突。

## 2) #17 完成后，可并行推进“写入型能力”

### Lane D：API Write / Artifacts

- #19（Artifacts API + Run trigger）hard depends on：#16 + #17

### Lane E：Plan（主脑计划冻结）

- #20（PlanService + LLMPlan schema）hard depends on：#16 + #17

### Lane F：Queue

- #22（Queue 抽象 + claim）hard depends on：#16 + #17

结论：
- #19/#20/#22 可以并行，但都可能触及 `job.json` 与 artifacts 索引口径；合并前需对齐字段。

## 3) 执行引擎收口（存在 hard dependencies）

- #25（DoFileGenerator）hard depends on：#20（因为输入是 plan）+ #16
- #23（Worker loop + run attempt + retry）hard depends on：#22 + #20 + #16 + #17
- #36（Do 模板库接入）hard depends on：#24 + #16（可选依赖：#25，如果用它承载模板生成策略）

并行建议：
- #25 与 #36 可以并行（一个做 plan→do 的生成，一个做模板库与替换/加载），但两者会在“最终 do-file 生成策略”处汇合。
- #23 需要 queue + plan 已稳定，建议在 #22/#20 合并后再做，避免反复返工。

## 4) Observability & Security（跨切任务的落点）

- #26（结构化日志 + 配置化 log_level）
  - hard depends on：无（但会触及 main/worker 初始化，建议在 worker 入口稳定后合并）
  - 可并行：与所有任务并行，但易产生文件冲突
- #27（安全红线）
  - hard depends on：#16（路径模型/工作区）+（#19 下载安全）+（#24 runner 隔离）
  - 建议：与 #19/#24/#36 同步推进，并用测试锁定边界

## 推荐执行顺序（最少返工）

1) #16 → #17  
2) 并行：#18 + #21 + #24  
3) 并行：#19 + #20 + #22  
4) #25 + #36（可并行）  
5) #23（收口执行引擎）  
6) #26（穿透式补全）+ #27（和 #19/#24/#36 一起验证）

