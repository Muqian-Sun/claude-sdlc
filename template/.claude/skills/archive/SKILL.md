---
name: archive
description: "清理和归档历史记忆，释放上下文空间。用户说'清理历史'/'归档'/'释放空间'时触发。"
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
---

用法：`/archive`

参数：$ARGUMENTS

---

## 功能

自动清理 `project-state.md` 中的历史记忆，将不常用的信息归档到 `.claude/archive/`，释放上下文空间。

---

## 执行逻辑

### 1. 读取当前状态
Read `.claude/project-state.md` 提取：
- `completed_tasks` 数量
- `phase_history` 数量
- `architecture_decisions` 数量

### 2. 归档 completed_tasks（≥5个时）
如果 `completed_tasks.length >= 5`：
1. 提取最旧的 `N-3` 个任务（保留最近 3 个）
2. 追加到 `.claude/archive/tasks-{year}.md`（极简格式）：
   ```markdown
   - {completed_at}: {task} ({files_count}文件)
   ```
3. 从 `project-state.md` 中删除已归档的任务

### 3. 压缩 phase_history（≥10条时）
如果 `phase_history.length >= 10`：
1. 保留最近 5 条
2. 删除其余记录
3. 在文件中添加注释：`# 历史记录已压缩，保留最近5条`

### 4. 精简 architecture_decisions（≥8条时）
如果 `architecture_decisions.length >= 8`：
1. 识别全局性决策（涉及多个模块的）→ 同步到 `global_architecture`
2. 保留当前任务相关的决策（≤5条）
3. 删除过时/重复的决策

### 5. 生成归档报告
```markdown
# 归档完成

**清理前**: completed_tasks {n}个 | phase_history {n}条 | architecture_decisions {n}条
**清理后**: completed_tasks 3个 | phase_history 5条 | architecture_decisions {n}条
**归档位置**: .claude/archive/tasks-{year}.md
**节省空间**: 约 {n} 行（~{n} tokens）
```

---

## 归档文件格式

### `.claude/archive/tasks-{year}.md`（极简）

```markdown
# {year} 已完成任务归档

> 归档时间：{timestamp}

- 2025-01-15: 用户登录功能 (5文件)
- 2025-01-20: 数据展示优化 (3文件)
- 2025-02-01: 性能优化 (8文件)
```

**不保存**：prd_summary、key_decisions、详细信息（已不需要）

---

## 触发时机

### 自动触发
- P5 完成后，如果 `completed_tasks >= 5`，提示用户是否归档
- Context Compaction 前，自动压缩 phase_history

### 手动触发
- 用户执行 `/archive`
- 用户说"清理历史"、"归档旧任务"、"释放空间"

---

## 安全保护

- ✅ 归档前先备份原始 `project-state.md` → `.claude/archive/state-backup-{timestamp}.md`
- ✅ 归档文件只追加，不删除
- ✅ 保留最近 3 个 completed_tasks（不归档）
- ✅ `project_roadmap` 和 `global_architecture` 永不归档

---

## 示例

### 归档前（project-state.md，~180行）

```yaml
completed_tasks:
  - task: "实现用户登录"
    prd_summary: "R1:用户登录 R2:密码加密"
    key_decisions: ["React18", "JWT"]
    files_count: 5
    completed_at: "2024-12-01"
  - task: "数据展示功能"
    prd_summary: "R1:列表展示 R2:分页"
    key_decisions: ["Redux Toolkit", "Ant Design"]
    files_count: 3
    completed_at: "2024-12-15"
  - task: "搜索功能"
    prd_summary: "R1:关键词搜索 R2:筛选"
    key_decisions: ["Debounce", "URL参数"]
    files_count: 4
    completed_at: "2025-01-05"
  - task: "导出功能"
    prd_summary: "R1:Excel导出 R2:PDF导出"
    key_decisions: ["xlsx库", "jsPDF"]
    files_count: 6
    completed_at: "2025-01-20"
  - task: "权限管理"
    prd_summary: "R1:角色权限 R2:菜单控制"
    key_decisions: ["RBAC", "动态路由"]
    files_count: 7
    completed_at: "2025-02-01"

phase_history:
  - "P1→P2 2024-12-01 10:00"
  - "P2→P3 2024-12-01 14:00"
  - "P3→P4 2024-12-01 16:00"
  - "P4→P5 2024-12-01 17:00"
  - "P0→P1 2024-12-15 09:00"
  - "P1→P2 2024-12-15 11:00"
  # ... 总共 15 条
```

### 归档后（project-state.md，~60行）

```yaml
completed_tasks:
  - task: "搜索功能"
    prd_summary: "R1:关键词搜索 R2:筛选"
    key_decisions: ["Debounce"]
    files_count: 4
    completed_at: "2025-01-05"
  - task: "导出功能"
    prd_summary: "R1:Excel导出 R2:PDF导出"
    key_decisions: ["xlsx库"]
    files_count: 6
    completed_at: "2025-01-20"
  - task: "权限管理"
    prd_summary: "R1:角色权限 R2:菜单控制"
    key_decisions: ["RBAC"]
    files_count: 7
    completed_at: "2025-02-01"

phase_history:
  # 历史记录已压缩，保留最近5条
  - "P1→P2 2025-02-01 10:00"
  - "P2→P3 2025-02-01 14:00"
  - "P3→P4 2025-02-01 16:00"
  - "P4→P5 2025-02-01 17:00"
  - "P0→P1 2025-02-08 09:00"
```

### 归档文件（tasks-2024.md + tasks-2025.md，~10行）

```markdown
# 2024 已完成任务归档

> 归档时间：2025-02-08 10:30

- 2024-12-01: 实现用户登录 (5文件)
- 2024-12-15: 数据展示功能 (3文件)
```

**节省**：180 → 60 行（**-67%**，约 1500 tokens）

---

## 注意事项

- 归档是**单向操作**，归档后的详细信息不会恢复（只保留摘要）
- 如需查看归档任务详细信息，需要查看 Git 历史或代码
- 建议在项目稳定期（多个任务完成后）批量归档
