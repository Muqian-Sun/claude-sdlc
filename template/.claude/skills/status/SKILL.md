---
name: status
description: "查看 SDLC 项目完整状态。用户说'查看状态'/'项目状态'/'当前进度'时自动触发。"
allowed-tools:
  - Read
  - Glob
  - Grep
---

用法：`/status`

参数：$ARGUMENTS

---

## 当前状态快照

!`bash "${CLAUDE_PROJECT_DIR}"/.claude/hooks/statusline.sh 2>/dev/null || echo "状态未知"`

## 执行逻辑

1. **读取 project-state.md**：所有 YAML 字段
2. **收集 Git 信息**（如可用）：当前分支、未提交变更、最近 commit
3. **生成状态报告**（Markdown 格式）：

**SDLC 项目状态报告**

- **任务**：{task_description} | 开始：{started_at} | 更新：{last_updated}
- **阶段进度**：当前 {current_phase}（{用户确认/自动驱动}）| 审查重试：{n}/3
- **进度**：P1 ✅ → P2 🔄 → P3 ⬜ → P4 ⬜ → P5 ⬜
- **文件变更**：已修改 {n} 个文件
- **架构决策**：{列表}
- **待办事项**：{列表}

4. **同步更新** project-state.md（如信息不是最新）+ 更新 `last_updated`
