# 反遗忘机制

---

## 风险场景与防御

| 场景 | 防御 |
|------|------|
| 新会话启动 | SessionStart hook + CLAUDE.md 自动加载 |
| 长对话漂移 | UserPromptSubmit 每次注入阶段提醒 |
| Context Compaction | PreCompact 保存状态 → SessionStart 恢复 |
| 用户催促跳过 | Hooks 硬拦截 + Permissions deny |
| 新任务覆盖旧规划 | 归档到 completed_tasks → project_roadmap/global_architecture 永不重置 |
| 子 Agent 脱离上下文 | SubagentStart hook 注入阶段+PRD+工具限制 |

---

## 优先级

1. **安全性** > 2. **用户指令**（先说明风险）> 3. **SDLC 流程** > 4. **编码标准** > 5. **Git 规范**
