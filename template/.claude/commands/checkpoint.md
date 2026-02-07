# /checkpoint — 保存状态快照

用法：`/checkpoint [描述]`

参数：$ARGUMENTS

---

## 执行逻辑

1. **收集当前状态信息**：
   - 读取 CLAUDE.md 中的 `current_phase`
   - 读取 CLAUDE.md 中的 `task_description`
   - 执行 `git status`（如果是 git 仓库）获取文件变更状态
   - 执行 `git diff --stat`（如果是 git 仓库）获取变更统计

2. **生成快照摘要**：
   ```
   === SDLC Checkpoint ===
   时间：{当前时间}
   描述：{用户提供的描述 或 "手动检查点"}
   当前阶段：{阶段编号} — {阶段名称}
   任务：{task_description}

   已修改文件：
   - {文件列表}

   架构决策：
   - {决策列表}

   待办事项：
   - {待办列表}

   Git 状态：
   {git status 输出摘要}
   ========================
   ```

3. **更新 CLAUDE.md**：
   - 确保 `modified_files` 列表是最新的
   - 确保 `todo_items` 列表是最新的
   - 更新 `last_updated` 时间戳
   - 更新 `key_context` 为当前关键上下文的摘要

4. **输出确认信息**：
   ```
   ✅ 检查点已保存。

   如果后续发生上下文压缩（compaction），可以从 CLAUDE.md 恢复以下状态：
   - 阶段：{阶段}
   - 任务：{任务描述}
   - 已修改 {n} 个文件
   - {n} 项待办事项
   ```

---

## 使用建议

建议在以下时机使用 `/checkpoint`：
- 完成一个重要步骤后
- 进行长对话之前（预防 compaction）
- 做出重要架构决策后
- 切换工作方向之前
- 任何你觉得"这些信息不能丢"的时候
