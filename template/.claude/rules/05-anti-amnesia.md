# 反遗忘机制

本文件说明 SDLC Enforcer 系统如何确保 Claude Code **在任何情况下**都能自动读取并执行规范，无需人为干预。

---

## 1. 问题定义

Claude Code 存在以下可能导致规范失效的场景：

| 场景 | 风险 | 防御机制 |
|------|------|---------|
| 新会话启动 | Claude 不知道有规范 | SessionStart hook 确定性注入 + CLAUDE.md + rules/ 自动加载 |
| 长对话漂移 | Claude 渐渐忘记规范 | UserPromptSubmit 每次注入阶段 + Stop agent 回复后自检 |
| Context Compaction | 早期对话被压缩丢弃 | PreCompact agent 保存状态 → SessionStart hook 恢复注入 |
| 用户催促跳过 | Claude 放弃规范直接执行 | Hooks 硬拦截违规操作 + Permissions 声明式 deny |
| 新任务覆盖 | 上一任务状态残留 | 新任务检测 → 自动重置 |
| Claude 自行判断不需要 | Claude 认为简单任务不需要走流程 | CLAUDE.md 明确"所有开发任务必须" |
| 子 Agent 脱离规范 | 并行子 Agent 不知道 SDLC 上下文 | SubagentStart hook 自动注入阶段+PRD+工具限制 |
| 子任务结果不合规 | 子任务完成但代码不符合 PRD | TaskCompleted hook 提醒主 Agent 验证合规性 |
| 敏感文件泄露 | Claude 读写 .env 等敏感文件 | Permissions deny 规则（平台层面强制，无法绕过） |

---

## 2. 十六层防御机制

### 第一层：SessionStart Hook — 确定性注入（主动）
- **会话启动、恢复、compaction 后自动触发**
- Shell 脚本读取 `.claude/project-state.md`，通过 `additionalContext` 确定性注入当前阶段和任务信息
- 不依赖 Claude "读 CLAUDE.md 启动指令" 的不确定方式，改为**程序化确定性注入**
- **这是最关键的防线 — 确保 Claude 在任何恢复场景下都立即获得 SDLC 上下文**

### 第二层：CLAUDE.md + rules/ 规则文件（主动）
- CLAUDE.md 在每次会话开始和 compaction 后自动加载
- CLAUDE.md 通过 @import 引用 `.claude/project-state.md`，项目状态存储在该文件中
- rules/ 目录下的 .md 文件自动加载（编码规范按文件类型生效、测试规范按测试文件生效）
- 不受 compaction 影响（compaction 后重新加载）

### 第三层：UserPromptSubmit Hook — 每次提交注入（主动）
- **每次用户提交 prompt 时自动触发**
- 注入当前 SDLC 阶段提醒，确保 Claude 在处理每条用户消息前都知道当前阶段
- **大幅减少长对话中的阶段漂移**

### 第四层：PreToolUse Hooks — 硬拦截（被动）
- 每次 Write/Edit/Bash 调用前，Shell 脚本自动检查阶段
- **即使 Claude 完全忘记了规范，Hooks 也会阻止违规操作**
- 拦截类型：
  - P3 之前写代码文件 → 被 check-phase-write.sh 拦截
  - P4 之前执行测试 → 被 check-phase-test.sh 拦截
  - P6 之前 git commit/push → 被 check-phase-test.sh 拦截
- 这是**不依赖 Claude 自觉性的被动安全网**

### 第五层：PostToolUse Hook — 状态同步（主动）
- 每次 Write/Edit 操作后，通过 `additionalContext` 提醒 Claude 更新 .claude/project-state.md
- 确保 modified_files 列表实时最新（状态存储在 .claude/project-state.md 中）
- 为 compaction 后的恢复提供准确的文件清单

### 第六层：Stop Hook — 回复后自检（主动，轻量 command）
- 每次回复完成后触发
- **command 类型**（轻量，不消耗主会话上下文）：shell 脚本读取 `.claude/project-state.md` 检查状态
- P1/P2 提醒等待用户确认、P3-P5 提醒继续自动驱动、P6 提醒输出交付摘要
- 通过 `additionalContext` 注入自检结果

### 第七层：PreCompact Hook — 压缩前保存（主动，轻量 command）
- **command 类型**（轻量，不消耗主会话上下文）：shell 脚本检查状态完整性
- 检查 key_context、last_updated、modified_files 是否完整
- 通过 `additionalContext` 注入紧急保存提醒，由 Claude 执行实际的 Edit 更新
- **不启动子 Agent**，避免在上下文即将满时雪上加霜

### 第八层：SubagentStart Hook — 子 Agent 上下文注入（主动）
- **子 Agent 启动时自动触发**
- 注入当前 SDLC 阶段、任务描述、PRD 摘要和该阶段的工具限制
- 确保并行子 Agent（P3/P4/P5）自动获得完整 SDLC 上下文
- **防止子 Agent 脱离 PRD 范围或违反阶段规范**

### 第九层：TaskCompleted Hook — 子任务完成验证（主动）
- **子任务标记完成时自动触发**（仅 P3-P5 自动驱动阶段）
- 提醒主 Agent 验证：modified_files 已更新、代码符合 PRD、无 PRD 外代码
- **防止不合规的子任务结果进入下一阶段**

### 第十层：Permissions 声明式权限（被动）
- **声明式安全规则，无法被 Claude 绕过**
- deny 规则：禁止读写 .env 文件（即使 Claude 忘记规范，声明式 deny 也无法绕过）
- allow 规则：安全的 git 查询和 lint 操作无需权限弹窗，减少操作摩擦
- **这是超越 Hooks 的硬性安全保障 — 不依赖脚本执行，由 Claude Code 平台层面强制执行**

### 第十一层：statusLine — 实时状态显示（被动）
- 终端底部持续显示当前 SDLC 阶段和进度
- 用户无需执行 `/status` 即可一目了然
- 提供视觉化进度条和任务摘要

### 第十二层：用户命令 / Skills（按需）
- `/status` — 随时查看完整状态，触发深度自检
- `/checkpoint` — 手动保存状态快照
- `/phase` — 确认和管理阶段
- `/review` — 执行当前阶段的审查
- Skills 升级：支持 `allowed-tools` 声明减少权限弹窗，支持自然语言意图自动触发

### 第十三层：SubagentStop Hook — 子 Agent 输出质量门控（主动）
- **子 Agent 完成时自动触发**（仅 P3-P5 自动驱动阶段）
- 验证子 Agent 输出：是否符合 PRD、代码质量、无 PRD 外变更
- 通过 `additionalContext` 注入验证要求，提醒主 Agent 检查结果
- **防止低质量子 Agent 输出进入下一阶段**

### 第十四层：PostToolUseFailure Hook — 失败恢复指导（主动）
- **工具执行失败后自动触发**
- 记录失败工具名称和当前阶段
- 注入恢复建议：检查路径/命令、确认阶段允许性、检查权限配置
- **防止工具失败后无指导的盲目重试**

### 第十五层：PermissionRequest Hook — 阶段感知自动权限决策（被动）
- **权限请求时自动触发**，根据当前 SDLC 阶段自动判断是否允许
- 决策矩阵：P0-P2 禁止代码写入、P3+ 允许代码写入、P4+ 允许测试、P6 允许 Git 提交
- Chrome 工具仅在 P2（UI 调研）和 P4（视觉测试）阶段允许
- **不依赖 Claude 自觉性，由脚本自动做出权限决策**

### 第十六层：SessionEnd Hook — 会话结束状态归档（主动）
- **会话结束时自动触发**
- 将当前阶段、任务、已修改文件归档到 `.claude/reviews/session-end-{timestamp}.md`
- 为下次会话恢复提供额外参考信息
- **确保会话间状态不丢失**

---

## 3. 自动化流程（无需人为干预）

### 场景 A：用户打开 Claude Code 说"帮我实现一个登录功能"

```
1. Claude Code 启动 → 自动加载 CLAUDE.md + rules/
2. CLAUDE.md「启动指令」执行 → 检查 current_phase = P0
3. Claude 识别到"实现"是开发请求 → 自动进入 P1
4. 更新 .claude/project-state.md: current_phase=P1, task_description="实现登录功能"
5. 开始需求分析 → 整理 PRD → 向用户展示 PRD 等待确认
6. 用户确认 PRD → 自动审查 → 进入 P2 → 设计方案 → 向用户展示等待确认
7. 用户确认设计 → 自动审查 → 进入自动驱动模式
8. P3 编码 → P4 测试 → P5 集成审查 → P6 交付 → 全自动完成
9. 输出交付摘要报告，用户无需中间操作
```

### 场景 B：对话进行中发生 Context Compaction（自动驱动中）

```
1. 当前在 P3 自动驱动中
2. PreCompact agent 触发 → 自动用 Read/Edit 工具检查并更新 .claude/project-state.md
3. Compaction 执行 → 对话历史被压缩
4. SessionStart hook 触发 → 确定性注入 "SDLC 状态恢复：阶段=P3，任务=..."
5. CLAUDE.md + rules/ 重新加载 → 完整规范上下文恢复
6. Claude 收到注入的上下文 → 立即知道当前阶段和任务
7. 继续自动驱动流程（P3 编码 → P4 → P5 → P6）
```

### 场景 C：Claude 尝试在 P1 阶段写代码

```
1. Claude 调用 Write 工具写 .py 文件
2. PreToolUse hook (check-phase-write.sh) 执行
3. 读取 .claude/project-state.md: current_phase=P1
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

### 场景 E：自动驱动中审查未通过

```
1. P3 编码完成 → 自动执行代码审查
2. 审查发现问题（如函数超过 50 行）
3. Claude 自动修复问题（拆分函数）
4. 重新执行代码审查 → 通过
5. 自动推进到 P4，继续测试
（用户全程无需操作）
```

### 场景 F：自动驱动中多次审查失败

```
1. P4 测试审查第 3 次仍未通过（覆盖率不达标）
2. Claude 停下自动驱动
3. 向用户报告：「自动驱动暂停 — P4 测试审查已重试 3 次仍未通过」
4. 列出具体问题和已尝试的修复
5. 请求用户指导
6. 用户给出建议后，Claude 修复问题并恢复自动驱动
```

### 场景 G：第一个任务完成后用户提出新任务

```
1. P6 交付完成，Claude 输出了交付摘要
2. 用户说"再帮我加一个注册功能"
3. Claude 检测到新开发请求
4. 归档旧任务到 phase_history
5. 重置 current_phase=P1, 清空 modified_files/todo_items
6. 开始新任务的需求分析（又是一轮完整流程）
```

---

## 4. 快速自检流程

**每次回复前执行（内部 4 步）：**

```
1. 【阶段】我当前在哪个阶段？→ 检查 .claude/project-state.md 的 current_phase
2. 【PRD】我接下来要做的事，对应 PRD 中的哪条需求？→ 如果对应不上，不做
3. 【合规】我要执行的操作在当前阶段允许吗？→ 对照允许列表
4. 【状态】.claude/project-state.md 的状态是最新的吗？→ 如有变更需更新
```

**疑问时的行为：不猜测，用 Read 工具重新读取 .claude/project-state.md。**

---

## 5. 深度自检流程

**触发场景：**
- 阶段转换时（`/phase next`）
- 检测到 compaction 后
- 用户执行 `/status` 时
- 感觉上下文不完整时
- Stop hook 提醒时

```
1. 用 Read 工具读取 .claude/project-state.md 的 YAML 状态
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
1. 用 Read 工具读取 .claude/project-state.md 获取最新状态
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
