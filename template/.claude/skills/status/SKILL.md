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

执行深度自检并生成全面的项目状态报告：

### 1. 读取 .claude/project-state.md 状态
- `current_phase` — 当前阶段
- `task_description` — 任务描述
- `started_at` / `last_updated` — 时间信息
- `review_retry_count` — 当前审查重试次数
- `architecture_decisions` — 架构决策
- `modified_files` — 已修改文件
- `todo_items` — 待办事项
- `phase_history` — 阶段历史
- `key_context` — 关键上下文

### 2. 收集 Git 信息（如可用）
- 当前分支
- 未提交的变更
- 最近的 commit

### 3. 生成状态报告

输出格式：

```
╔══════════════════════════════════════╗
║        SDLC 项目状态报告             ║
╚══════════════════════════════════════╝

📋 基本信息
├── 任务：{task_description}
├── 开始时间：{started_at}
└── 最后更新：{last_updated}

🔄 阶段进度
├── 当前阶段：{阶段编号} — {阶段名称}
├── 驱动模式：{用户确认模式 (P1/P2) / 自动驱动模式 (P3-P6) / 未开始}
├── 审查重试计数：{review_retry_count}/3
├── 阶段历史：{P1 ✅ → P2 ✅ → P3 🔄 → P4 ⬜ → P5 ⬜ → P6 ⬜}
└── 当前阶段退出条件：
    ├── ✅ {已满足条件1}
    ├── ✅ {已满足条件2}
    └── ❌ {未满足条件3}

📁 文件变更
├── 已修改：{n} 个文件
│   ├── {文件1}
│   ├── {文件2}
│   └── ...
└── 未提交变更：{git status 摘要}

🏗️ 架构决策
├── {决策1}
└── {决策2}

📝 待办事项
├── [ ] {待办1}
├── [ ] {待办2}
└── [x] {已完成项}

🔍 合规性检查
├── SDLC 流程：{✅ 合规 / ⚠️ 有偏离}
├── 编码规范：{✅ 遵循 / ⚠️ 待检查}
├── 测试覆盖：{✅ 达标 / ⚠️ 未测试 / ⬜ 未到测试阶段}
└── 文档更新：{✅ 已更新 / ⚠️ 需更新}
```

### 4. 同步更新
- 如果发现 .claude/project-state.md 中的信息不是最新，同步更新
- 更新 `last_updated` 时间戳

---

## 说明

- `/status` 命令同时起到"深度自检"的作用
- 建议在长对话中定期执行 `/status` 以保持状态同步
- 如果 compaction 后感觉上下文不完整，执行 `/status` 可以帮助恢复
