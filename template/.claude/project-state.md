# SDLC 项目状态（活文档 — 持续更新）

> **COMPACTION 保护区域：压缩时必须保留。每次变更后立即更新。**
> 本文件是项目状态唯一存储位置，通过 CLAUDE.md 的 @import 自动加载。
> 升级 claude-sdlc 时本文件不会被覆盖。

```yaml
# === SDLC 项目状态 ===
current_phase: P0  # P0=未开始, P1=需求, P2=设计, P3=编码, P4=测试, P5=审查, P6=部署
task_description: ""
started_at: ""
last_updated: ""

# PRD — 用户确认的需求清单（P1 产出，P2-P6 唯一依据）
prd:
  # - id: R1
  #   description: "需求描述"
  #   acceptance_criteria: "验收标准"

architecture_decisions: []
modified_files: []
todo_items: []
review_retry_count: 0  # 自动驱动审查重试计数，阶段推进后重置
phase_history: []
key_context: ""  # compaction 后恢复用
```

### 状态更新时机

| 事件 | 更新字段 |
|------|---------|
| 新任务 | `current_phase`→P1, `task_description`, `started_at` |
| PRD 确认 | `prd`（编号化需求列表，此后为唯一依据） |
| 阶段推进 | `current_phase`, `phase_history`, `review_retry_count`→0, `last_updated` |
| 文件修改 | `modified_files`（追加路径）, `last_updated` |
| 架构决策 | `architecture_decisions`, `last_updated` |
| 审查重试 | `review_retry_count`+1, `last_updated` |
| 即将压缩 | 所有字段确认最新, `key_context`（写入当前工作摘要） |

# Compact Instructions

压缩时必须保留：(1) 本文件路径和存在性 (2) 上方 YAML 块完整内容 (3) 当前阶段和任务 (4) 已修改文件列表 (5) 架构决策 (6) 用户最近指令。恢复后：P1/P2 等待用户确认继续，P3-P6 自动恢复自动驱动继续完成。
