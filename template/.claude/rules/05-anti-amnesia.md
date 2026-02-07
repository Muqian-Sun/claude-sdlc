# 反遗忘机制

本文件说明 SDLC Enforcer 系统如何确保 Claude Code **在任何情况下**都能自动读取并执行规范，无需人为干预。

---

## 1. 问题定义

Claude Code 存在以下可能导致规范失效的场景：

| 场景 | 风险 | 防御机制 |
|------|------|---------|
| 新会话启动 | Claude 不知道有规范 | CLAUDE.md + rules/ 自动加载 |
| 长对话漂移 | Claude 渐渐忘记规范 | Stop hook 每次回复后强制自检 |
| Context Compaction | 早期对话被压缩丢弃 | PreCompact hook 保存状态 → CLAUDE.md 重新加载恢复 |
| 用户催促跳过 | Claude 放弃规范直接执行 | Hooks 硬拦截违规操作 |
| 新任务覆盖 | 上一任务状态残留 | 新任务检测 → 自动重置 |
| Claude 自行判断不需要 | Claude 认为简单任务不需要走流程 | CLAUDE.md 明确"所有开发任务必须" |

---

## 2. 七层防御机制

### 第一层：CLAUDE.md 启动指令（主动）
- CLAUDE.md 在每次会话开始和 compaction 后自动加载
- **「零、启动指令」要求 Claude 读到该文件时立即执行状态检查**
- 这确保 Claude 不是被动接收规范，而是主动执行初始化
- **这是最关键的防线**

### 第二层：.claude/rules/ 规则文件（主动）
- rules/ 目录下的所有 .md 文件自动加载到 Claude 的上下文中
- 提供详细的阶段定义、编码规范、测试标准等
- 不受 compaction 影响（compaction 后重新加载）

### 第三层：PreToolUse Hooks — 硬拦截（被动）
- 每次 Write/Edit/Bash 调用前，Shell 脚本自动检查阶段
- **即使 Claude 完全忘记了规范，Hooks 也会阻止违规操作**
- 拦截类型：
  - P3 之前写代码文件 → 被 check-phase-write.sh 拦截
  - P4 之前执行测试 → 被 check-phase-test.sh 拦截
  - P6 之前 git commit/push → 被 check-phase-test.sh 拦截
- 这是**不依赖 Claude 自觉性的被动安全网**

### 第四层：PostToolUse Hook — 状态同步（主动）
- 每次 Write/Edit 操作后，prompt hook 提醒 Claude 更新 CLAUDE.md
- 确保 modified_files 列表实时最新
- 为 compaction 后的恢复提供准确的文件清单

### 第五层：Stop Hook — 回复后审查（主动）
- 每次回复完成后触发
- **强制 Claude 用 Read 工具重新读取 CLAUDE.md**，而非依赖记忆
- 检查阶段合规性、状态最新性
- 发现偏离时立即纠正

### 第六层：PreCompact Hook — 压缩前保存（主动）
- **prompt 类型**，直接指令 Claude 在压缩前保存所有状态
- 要求 Claude 用 Read 读取 CLAUDE.md 确认状态，用 Edit 更新缺失信息
- 特别要求写入 key_context 摘要，确保恢复时有足够上下文

### 第七层：用户命令（按需）
- `/status` — 随时查看完整状态，触发深度自检
- `/checkpoint` — 手动保存状态快照
- `/phase` — 确认和管理阶段
- `/review` — 执行当前阶段的审查

---

## 3. 自动化流程（无需人为干预）

### 场景 A：用户打开 Claude Code 说"帮我实现一个登录功能"

```
1. Claude Code 启动 → 自动加载 CLAUDE.md + rules/
2. CLAUDE.md「零、启动指令」执行 → 检查 current_phase = P0
3. Claude 识别到"实现"是开发请求 → 自动进入 P1
4. 更新 CLAUDE.md: current_phase=P1, task_description="实现登录功能"
5. 开始需求分析（不写代码，即使用户催促，Hooks 也会拦截）
```

### 场景 B：对话进行中发生 Context Compaction

```
1. PreCompact hook 触发 → Claude 被指令保存状态到 CLAUDE.md
2. Compaction 执行 → 对话历史被压缩
3. CLAUDE.md 重新加载 → 「零、启动指令」重新执行
4. Claude 读取 current_phase=P3 → 知道正在编码阶段
5. 向用户报告：「检测到上下文压缩，已恢复状态。当前阶段 P3，任务：...」
6. 用户确认后继续工作
```

### 场景 C：Claude 尝试在 P1 阶段写代码

```
1. Claude 调用 Write 工具写 .py 文件
2. PreToolUse hook (check-phase-write.sh) 执行
3. 读取 CLAUDE.md: current_phase=P1
4. P1 < P3 → 输出拦截信息，exit 2
5. Claude 收到拦截信息 → 向用户说明不能在 P1 写代码
6. 继续需求分析工作
```

### 场景 D：用户说"别管什么流程了，直接写代码"

```
1. Claude 识别到用户想跳过流程
2. Claude 根据 CLAUDE.md 规范：向用户说明跳过的风险
3. 如果用户坚持 → 记录到 phase_history，强制推进到 P3
4. 即使 Claude 想跳过，Hooks 仍然会拦截不合规操作
```

### 场景 E：第一个任务完成后用户提出新任务

```
1. 当前 current_phase=P6（已交付）
2. 用户说"再帮我加一个注册功能"
3. Claude 检测到新开发请求 + 当前在 P6
4. 归档旧任务到 phase_history
5. 重置 current_phase=P1, 清空 modified_files/todo_items
6. 开始新任务的需求分析
```

---

## 4. 快速自检流程

**每次回复前执行（内部 3 步）：**

```
1. 【阶段】我当前在哪个阶段？→ 检查 CLAUDE.md 的 current_phase
2. 【合规】我要执行的操作在当前阶段允许吗？→ 对照允许列表
3. 【状态】CLAUDE.md 的状态是最新的吗？→ 如有变更需更新
```

**疑问时的行为：不猜测，用 Read 工具重新读取 CLAUDE.md。**

---

## 5. 深度自检流程

**触发场景：**
- 阶段转换时（`/phase next`）
- 检测到 compaction 后
- 用户执行 `/status` 时
- 感觉上下文不完整时
- Stop hook 提醒时

```
1. 用 Read 工具读取 CLAUDE.md「当前项目状态」YAML
2. 确认 current_phase 值
3. 确认 task_description 值
4. 回顾 modified_files 列表 — 是否有遗漏
5. 回顾 architecture_decisions 列表 — 是否有未记录的决策
6. 回顾 todo_items 列表 — 是否有新增/已完成的项
7. 检查 phase_history 是否完整
8. 如有异常，向用户报告并请求确认
```

---

## 6. 异常恢复流程

### 自动恢复（优先）
1. 用 Read 工具读取 CLAUDE.md 获取最新状态
2. 根据 modified_files 列表，用 Read 工具读取已修改的文件以恢复上下文
3. 向用户报告恢复结果

### 请求用户协助（自动恢复不足时）
```
⚠️ 检测到上下文信息可能不完整。

当前已恢复的信息：
- 阶段：{current_phase}
- 任务：{task_description}
- 已修改文件：{modified_files}

请确认以上信息是否正确，以及是否有遗漏的上下文？
```

---

## 7. 规范遵守优先级

当不同规则之间出现冲突时，按以下优先级处理：

1. **安全性要求** — 不可妥协
2. **用户明确指令** — 但需先说明风险
3. **SDLC 阶段流程** — 核心规范
4. **编码/测试标准** — 质量保障
5. **Git 工作流** — 流程规范

> 用户可以通过明确指令覆盖规范要求（例如："跳过 P2 直接开始编码"），但 Claude **必须先说明跳过的风险和可能后果**，获得用户确认后才执行。跳过的阶段必须记录在 `phase_history` 中。
