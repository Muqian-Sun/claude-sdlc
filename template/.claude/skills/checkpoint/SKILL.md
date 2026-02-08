---
name: checkpoint
description: "保存当前工作状态快照。用户说'保存进度'/'快照'时自动触发。"
argument-hint: "[description]"
allowed-tools:
  - Read
  - Edit
  - Bash
---

用法：`/checkpoint [描述]`

参数：$ARGUMENTS

---

## 执行逻辑

1. **收集状态**：读取 project-state.md（current_phase、task_description），执行 `git status` + `git diff --stat`（如为 git 仓库）

2. **输出快照摘要**：
   ```
   === SDLC Checkpoint ===
   时间：{当前时间}
   描述：{用户描述 或 "手动检查点"}
   阶段：{阶段编号} — {名称}
   任务：{task_description}
   已修改文件：{列表}
   架构决策：{列表}
   待办事项：{列表}
   Git 状态：{摘要}
   ========================
   ```

3. **更新 project-state.md**：同步 `modified_files`、`todo_items`、`last_updated`、`key_context`（当前工作摘要）

4. **确认**：
   ```
   ✅ 检查点已保存。
   阶段：{阶段} | 已修改 {n} 个文件 | {n} 项待办
   compaction 后可从 .claude/project-state.md 恢复。
   ```
