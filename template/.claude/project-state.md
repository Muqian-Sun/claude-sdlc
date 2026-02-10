# SDLC 项目状态（活文档 — 持续更新）

> **COMPACTION 保护区域。** 唯一状态存储，通过 CLAUDE.md @import 加载。升级时不被覆盖。

```yaml
# === 项目级别（跨任务持久化，任务重置时绝不清除） ===
project_roadmap: ""  # 长期规划（≤50字）
completed_tasks: []  # 已完成任务归档（精简格式，见 09-memory-management.md）
  # - task: "一句话描述"
  #   prd_summary: "R1:需求1 R2:需求2"  # ≤50字
  #   key_decisions: ["技术栈", "架构决策"]  # ≤3条
  #   files_count: 5  # 不列举文件名
  #   completed_at: "2025-01-15"
  # 自动清理：≥5个时归档最旧2个到 .claude/archive/
global_architecture: []  # 跨任务架构决策（≤5条）

# === 当前任务（重置时归档到 completed_tasks 后清空） ===
current_phase: P0  # P0=未开始, P1=需求+设计, P2=编码, P3=测试, P4=审查, P5=部署
task_description: ""  # ≤30字
started_at: ""
last_updated: ""
requirements_clarification:  # P1 需求澄清结果（临时，写入 prd 后删除）
  priority_features: []  # 按优先级：必须功能、可选功能
  target_users: ""  # 目标用户描述
  constraints: []  # 技术约束、性能要求、兼容性要求
  ui_preferences: ""  # UI 风格偏好或参考（如涉及 UI）
prd:
  # - id: R1
  #   desc: "需求描述"  # ≤30字
  #   accept: "验收标准"  # 1条，可测试
  # PRD总长度≤150行，详见 09-memory-management.md
architecture_decisions: []  # ≤5条
modified_files: []  # 仅路径
todo_items: []  # 可从prd重建
review_retry_count: 0
phase_history: []  # 仅阶段转换，≥10条时压缩
key_context: ""  # compaction恢复用，≤50字
```

### 更新时机

| 事件 | 更新字段 | 精简要求 |
|------|---------|---------|
| 新任务 | 归档旧任务→`completed_tasks`（精简格式）→ 重置当前任务 → P1 | completed_tasks ≥5 时归档 |
| PRD 确认 | `prd`（精简格式，≤150行） | 需求desc≤30字，accept 1条 |
| 阶段推进 | `current_phase`, `phase_history`（仅转换记录） | phase_history ≥10 时压缩 |
| 文件修改 | `modified_files`（仅路径） | 不含文件内容 |
| 架构决策 | `architecture_decisions`（≤5条） + `global_architecture` | 仅关键决策 |
| 即将压缩 | 所有字段最新, `key_context`（≤50字） | 删除 todo_items，保留最近3个completed_tasks |

# Compact Instructions

**压缩时保留（精简优先级）**：
1. current_phase + task_description + prd（精简格式）
2. modified_files + key_context（≤50字）
3. project_roadmap（如有）
4. completed_tasks（最近3个，精简格式）
5. global_architecture（≤5条）

**压缩时删除**：
- phase_history 详细记录（保留最近5条转换）
- todo_items（可从prd重建）
- 超过3个的completed_tasks（归档到 .claude/archive/）

详见 `.claude/rules/09-memory-management.md`
