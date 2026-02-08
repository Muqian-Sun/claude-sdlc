# SDLC 项目状态（活文档 — 持续更新）

> **COMPACTION 保护区域。** 唯一状态存储，通过 CLAUDE.md @import 加载。升级时不被覆盖。

```yaml
# === 项目级别（跨任务持久化，任务重置时绝不清除） ===
project_roadmap: ""  # 长期规划/里程碑
completed_tasks: []  # 已完成任务归档（task/prd_summary/key_decisions/files/completed_at）
global_architecture: []  # 跨任务架构决策

# === 当前任务（重置时归档到 completed_tasks 后清空） ===
current_phase: P0  # P0=未开始, P1=需求, P2=设计, P3=编码, P4=测试, P5=审查, P6=部署
task_description: ""
started_at: ""
last_updated: ""
prd:
  # - id: R1
  #   description: "需求描述"
  #   acceptance_criteria: "验收标准"
architecture_decisions: []
modified_files: []
todo_items: []
review_retry_count: 0
phase_history: []
key_context: ""  # compaction 恢复用
```

### 更新时机

| 事件 | 更新字段 |
|------|---------|
| 新任务 | 归档旧任务→`completed_tasks` → 重置当前任务字段 → P1。**项目级别字段绝不重置** |
| PRD 确认 | `prd`（编号化，此后唯一依据） |
| 阶段推进 | `current_phase`, `phase_history`, `review_retry_count`→0 |
| 文件修改 | `modified_files`（追加）|
| 架构决策 | `architecture_decisions` + 通用决策同步 `global_architecture` |
| 即将压缩 | 所有字段确认最新, `key_context`（当前工作摘要） |

# Compact Instructions

压缩时必须保留：(1) 本文件完整 YAML 块 (2) project_roadmap/completed_tasks/global_architecture (3) 当前阶段+任务+已修改文件 (4) 用户最近指令。恢复后：P1/P2 等用户确认，P3-P6 自动恢复驱动。
