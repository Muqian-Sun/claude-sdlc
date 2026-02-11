# 记忆与文档精简管理

## 核心原则

**最小必要原则**：只保存恢复工作所需的最小信息集，删除冗余、装饰性、可推导的内容。

---

## 1. project-state.md 精简规则

### completed_tasks 归档格式

```yaml
completed_tasks:
  - task: "任务描述"  # ≤20字
    prd_summary: "R1:需求1 R2:需求2"  # ≤50字
    key_decisions: ["技术栈", "架构"]  # ≤3条
    files_count: 5
    completed_at: "2025-01-15"
```

**禁止**：完整 PRD、文件列表、验收标准、代码片段

**自动清理**：≥5 个时归档最旧 2 个到 `.claude/archive/`

### PRD 文件引用（v1.11.0+）

```yaml
prd_file: ".claude/prd.md"  # 仅保存路径引用
```

**优势**：减少上下文、易管理、压缩保护、符合精简原则

**PRD 文件格式**（`.claude/prd.md`，≤150 行）：
```markdown
# PRD - {任务}

## 需求
| ID | 需求≤30字 | 验收标准 |
|----|----------|---------|
| R1 | 登录 | 正确凭证→首页 |

## 技术栈
- React 18 + TS

## 非功能
- 性能: <300ms
```

### 其他字段精简

- `architecture_decisions`: ≤5条（技术栈+核心模式）
- `phase_history`: 仅转换记录，≥10条时压缩
- `key_context`: ≤50字（当前做什么+关键问题）

---

## 2. PRD 生成格式

**内容**：需求表（ID|描述≤30字|验收）、技术栈、非功能、UI方向

**禁止**：背景说明、范围排除、详细数据模型、实现细节

**长度**：≤150行

---

## 3. 报告精简（v1.8.0+）

- 审查报告：~10行
- 交付摘要：~5行
- 状态报告：~8行

详见对应 SKILL.md

---

## 4. Compaction 保护

**保留**：
1. current_phase + task_description
2. prd_file + `.claude/prd.md` 文件
3. modified_files + key_context（≤50字）
4. project_roadmap
5. completed_tasks（最近3个）
6. global_architecture（≤5条）

**删除**：
- phase_history详细（保留最近5条）
- todo_items（可从prd重建）
- requirements_clarification（PRD后删除）
- 超过3个的completed_tasks

---

## 5. 自动归档

**触发**：
- completed_tasks ≥5 → 归档最旧2个
- phase_history ≥10 → 合并重复

**位置**：`.claude/archive/tasks-{year}.md`

---

## 6. 文档生成规则

| 规则 | 说明 |
|------|------|
| 一句话原则 | 能用一句话不用两句 |
| 表格优先 | 结构化信息用表格 |
| 无装饰 | 无 ASCII 边框、emoji |
| 无重复 | 信息只在一处出现 |
| 可量化 | 用数字而非描述 |

**长度限制**：PRD≤150行、架构≤50行、审查≤15行、交付≤10行、状态≤10行、compaction≤200行

---

## 7. 执行检查

**P1**：PRD文件≤150行、需求≤30字、架构≤5条、记录prd_file

**P5**：prd_summary≤50字、key_decisions≤3条、记录files_count、completed_tasks≥5时归档

**Compaction前**：key_context≤50字、completed_tasks≤3个、phase_history≤5条、总保留≤200行
