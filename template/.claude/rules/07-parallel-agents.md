# 多 Agent 并行开发

利用 Task 工具派发子 Agent（`.claude/agents/` 中的 sdlc-coder/sdlc-tester/sdlc-reviewer）并行工作。

---

## 核心原则

1. **独立性** — 只有无依赖的任务才可并行
2. **原子性** — 每个子 Agent 负责一个完整逻辑单元
3. **PRD 对齐** — 每个子 Agent 任务对应明确的 PRD 需求
4. **主 Agent 协调** — 拆分、分配、汇总、解决冲突

---

## Agent 派发

| 阶段 | 触发条件 | 子 Agent | 拆分粒度 | 汇总后操作 |
|------|---------|---------|---------|-----------|
| P3 | 2+ 独立实现模块 | sdlc-coder | 按模块/文件 | 检查接口一致性 |
| P4 | 2+ 独立被测模块 | sdlc-tester | 按被测模块 | 统一执行全部测试 |
| P5 | modified_files ≥5 | sdlc-reviewer | 按审查维度（最多3个） | 合并审查报告 |

---

## 限制

- 最多 **2 个**并行子 Agent
- 小任务（单文件或 <50 行）直接主 Agent 完成，不并行
- P1/P2/P6 不适用并行
- 子 Agent 失败 → 不重试，改主 Agent 串行完成
