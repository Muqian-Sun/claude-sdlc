# 反遗忘机制

确保 Claude Code 在任何场景下自动执行 SDLC 规范，无需人为干预。

---

## 1. 风险场景

| 场景 | 风险 | 防御机制 |
|------|------|---------|
| 新会话启动 | 不知道有规范 | SessionStart hook + CLAUDE.md + rules/ 自动加载 |
| 长对话漂移 | 渐忘规范 | UserPromptSubmit 每次注入 + Stop 回复后自检 |
| Context Compaction | 早期对话丢失 | PreCompact 保存状态 → SessionStart 恢复注入 |
| 用户催促跳过 | 放弃规范 | Hooks 硬拦截 + Permissions 声明式 deny |
| 新任务覆盖 | 状态残留 | 新任务检测 → 自动重置 |
| Claude 自行跳过 | 认为不需要流程 | CLAUDE.md 明确要求 |
| 子 Agent 脱离 | 不知 SDLC 上下文 | SubagentStart hook 注入阶段+PRD+工具限制 |
| 子任务不合规 | 代码不符 PRD | TaskCompleted hook 提醒验证 |
| 敏感文件泄露 | 读写 .env | Permissions deny（平台层面强制） |

---

## 2. 十六层防御机制

| 层 | 机制 | 类型 | 触发时机 | 作用 |
|----|------|------|---------|------|
| 1 | SessionStart Hook | 主动 | 启动/恢复/压缩后 | 确定性注入阶段+任务，最关键防线 |
| 2 | CLAUDE.md + rules/ | 主动 | 会话开始+压缩后 | 规范上下文自动加载 |
| 3 | UserPromptSubmit Hook | 主动 | 每次用户提交 | 注入阶段提醒，防漂移 |
| 4 | PreToolUse Hooks | 被动 | Write/Edit/Bash 前 | 硬拦截违规操作 |
| 5 | PostToolUse Hook | 主动 | Write/Edit 后 | 提醒更新 modified_files |
| 6 | Stop Hook | 主动 | 每次回复后 | 轻量自检，注入阶段提醒 |
| 7 | PreCompact Hook | 主动 | 压缩前 | 检查状态完整性，注入保存提醒 |
| 8 | SubagentStart Hook | 主动 | 子 Agent 启动 | 注入 SDLC 阶段+PRD+工具限制 |
| 9 | TaskCompleted Hook | 主动 | 子任务完成 | 提醒验证合规性 |
| 10 | Permissions 声明式 | 被动 | 始终生效 | deny .env，allow 安全操作 |
| 11 | statusLine | 被动 | 始终显示 | 终端底部实时显示阶段进度 |
| 12 | Skills（/status 等） | 按需 | 用户触发 | 查看状态、手动保存、执行审查 |
| 13 | SubagentStop Hook | 主动 | 子 Agent 完成 | 验证输出质量 |
| 14 | PostToolUseFailure | 主动 | 工具失败后 | 注入恢复建议 |
| 15 | PermissionRequest Hook | 被动 | 权限请求时 | 按阶段自动决策 |
| 16 | SessionEnd Hook | 主动 | 会话结束 | 归档状态摘要 |

**关键要点**：
- **主动防御**（1-3,5-9,13-14,16）：程序化注入，不依赖 Claude 自觉
- **被动安全网**（4,10,15）：即使 Claude 完全忘记规范也能拦截
- **按需恢复**（11-12）：用户随时可查看和干预

---

## 3. 正常流程示例

### 场景 A：用户说"帮我实现一个登录功能"

```
1. 启动 → 自动加载 CLAUDE.md + rules/
2. 启动指令 → 检查 current_phase = P0
3. 识别开发请求 → 自动进入 P1
4. 更新 project-state.md → P1, task="实现登录功能"
5. 需求分析 → PRD → 用户确认 → 审查 → P2
6. 设计 → 用户确认 → 审查 → 自动驱动模式
7. P3→P4→P5→P6 全自动 → 输出交付摘要
```

### 其他场景速查

| 场景 | 处理 |
|------|------|
| Compaction 发生 | PreCompact 保存 → 压缩 → SessionStart 恢复注入 → 继续自动驱动 |
| P1 写代码 | PreToolUse 拦截 → 告知阶段限制 |
| 用户要求跳过流程 | 说明风险 → 用户确认 → 记录 phase_history → 强制推进 |
| 审查未通过 | 自动修复重试（最多3次）→ 仍失败则停下请求用户帮助 |
| 多次审查失败 | 停止自动驱动 → 报告问题 → 等待用户指导 |
| 新任务 | 归档旧任务 → 重置状态 → 新 P1 |

---

## 4. 自检流程

**快速自检（每次回复前）**：
1. 【阶段】current_phase？ → 读 project-state.md
2. 【PRD】对应哪条需求？→ 对不上不做
3. 【合规】当前阶段允许吗？
4. 【状态】project-state.md 最新吗？

**深度自检（阶段转换 / compaction 后 / /status 时）**：
Read project-state.md → 逐项确认 phase/task/modified_files/architecture_decisions/todo_items/phase_history → 有异常向用户报告。

**疑问时**：不猜测，Read `.claude/project-state.md`。

---

## 5. 异常恢复

1. Read project-state.md 获取最新状态
2. 按 modified_files 读取已修改文件恢复上下文
3. 不足时向用户确认

---

## 6. 优先级

1. **安全性** — 不可妥协
2. **用户明确指令** — 需先说明风险
3. **SDLC 阶段流程** — 核心规范
4. **编码/测试标准** — 质量保障
5. **Git 工作流** — 流程规范

> 用户可覆盖规范，但 Claude 必须先说明风险。跳过的阶段记录在 `phase_history`。
