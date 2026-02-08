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

1. **读取 project-state.md**：所有 YAML 字段（current_phase、task_description、prd、modified_files、todo_items、phase_history、architecture_decisions、review_retry_count、key_context、时间信息）
2. **收集 Git 信息**（如可用）：当前分支、未提交变更、最近 commit
3. **生成状态报告**：

```
╔══════════════════════════════════════╗
║        SDLC 项目状态报告             ║
╚══════════════════════════════════════╝

基本信息：任务 / 开始时间 / 最后更新

阶段进度：
  当前：{阶段编号} — {名称}
  模式：{用户确认 (P1) / 自动驱动 (P3-P6)}
  审查重试：{n}/3
  历史：P1 ✅ → P3 🔄 → P4 ⬜ → P5 ⬜ → P6 ⬜
  退出条件：✅ {已满足} / ❌ {未满足}

文件变更：已修改 {n} 个文件 + 未提交变更摘要
架构决策：{列表}
待办事项：{列表}

合规性：SDLC 流程 / 编码规范 / 测试覆盖 / 文档更新
```

4. **同步更新** project-state.md（如信息不是最新）+ 更新 `last_updated`
