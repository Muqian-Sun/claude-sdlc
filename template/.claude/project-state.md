# SDLC 项目状态（活文档 — 持续更新）

> **COMPACTION 保护区域。** 唯一状态存储，通过 CLAUDE.md @import 加载。升级时不被覆盖。

```yaml
# 项目级（跨任务持久化）
project_roadmap: ""  # ≤50字
completed_tasks: []  # 精简格式，≥5个时归档
global_architecture: []  # ≤5条

# 当前任务（重置时归档后清空）
current_phase: P0  # P0-P5
task_description: ""  # ≤30字
started_at: ""
last_updated: ""
requirements_clarification:  # 临时，写入 PRD 后删除
  core_features: []
  extended_features: []
  related_features: []
  priority: ""
  target_users: ""
  constraints: []
  ui_preferences: ""
prd_file: ""  # PRD 路径，如 ".claude/prd.md"
architecture_decisions: []  # ≤5条
modified_files: []
todo_items: []
review_retry_count: 0
phase_history: []  # ≥10条时压缩
key_context: ""  # ≤50字
```

**更新时机**：新任务→归档+重置 | PRD确认→写 prd.md | 阶段推进→更新 phase | 文件修改→记路径 | 架构→记决策 | 压缩前→更新全部

**Compact 保留**：current_phase、task_description、prd_file、modified_files、key_context、project_roadmap、completed_tasks（最近3个）、global_architecture、prd.md文件

**Compact 删除**：phase_history详细、todo_items、多余completed_tasks、requirements_clarification

详见 `.claude/rules/09-memory-management.md`
