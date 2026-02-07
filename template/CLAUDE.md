# SDLC 开发规范（自动加载 · 抗压缩）

> 详细规则见 `.claude/rules/`（自动加载）。可用命令：`/phase`、`/status`、`/checkpoint`、`/review`。

@.claude/project-state.md

## 启动指令（加载时立即执行）

1. 用 Read 工具读取 `.claude/project-state.md` 获取 `current_phase` 值
2. **P1-P6**：向用户简要报告状态（阶段、任务、已修改文件数），继续工作
3. **P0 或空**：等待用户提出任务
4. 所有后续操作遵守 SDLC 规范

### 任务自动识别

用户提出开发请求（"实现..."/"修复..."/"重构..."等涉及代码修改的请求）→ **自动进入 P1**，更新 `current_phase`=P1、`task_description`、`started_at`。

已完成任务（P6/已交付）后收到新请求 → 归档旧任务到 `phase_history`，重置状态，进入新 P1。

### 自动驱动模式（用户仅需 2 次确认）

```
P1 需求 →【用户确认 PRD】→ 审查 → P2 设计 →【用户确认】→ 审查 → P3→P4→P5→P6 全自动
```

- **P1/P2**：展示产出物 → 等待用户确认 → 自动审查推进（不自问自答）
- **P3-P6**：完成工作 → 自动审查 → 通过则推进 → 继续下一阶段
- 审查未通过 → 自动修复重试（最多 3 次）→ 仍失败则停下请求用户帮助
- **P6** 完成后输出交付摘要（PRD 完成率、修改文件、测试结果、Git 提交）
- 用户随时可介入

### 多 Agent 并行开发

P3/P4/P5 阶段有独立模块时，用 Task 工具并行派发自定义 Agents 提高效率：
- P3 编码：`sdlc-coder` Agent（`.claude/agents/sdlc-coder.md`）
- P4 测试：`sdlc-tester` Agent（`.claude/agents/sdlc-tester.md`）
- P5 审查：`sdlc-reviewer` Agent（`.claude/agents/sdlc-reviewer.md`）

详见 `.claude/rules/07-parallel-agents.md`。

### 新增防护 Hooks

- **SubagentStop** — 子 Agent 完成时验证输出质量
- **PostToolUseFailure** — 工具失败时注入恢复建议
- **PermissionRequest** — 按阶段自动决策权限请求
- **SessionEnd** — 会话结束时归档状态摘要

详见 `.claude/rules/05-anti-amnesia.md`（十六层防御机制）。

---

## 核心规则

### PRD 驱动开发（最高优先级）

严格按用户确认的 PRD 开发。每写一行代码自问 —— "对应 PRD 哪条需求？"答不上来就不写。禁止添加 PRD 外功能，禁止减少 PRD 需求。发现遗漏 → 回 P1 与用户确认。

### 最新技术与设计调研（P2/P3 必须执行）

**设计和编码前，必须查阅最新官方文档、当前最流行的架构设计和 UI/UX 设计方案，禁止凭过时记忆编码。**

- **P2 设计前**：
  - 用 Context7 MCP 查询涉及的库/框架最新文档 + WebSearch 搜索最流行的架构设计和最佳实践
  - **UI/UX 调研**：WebSearch 搜索最新 UI/UX 设计趋势和流行的交互模式（如当前主流风格、组件库最佳实践），产出原型设计（页面布局、组件结构、交互流程）
  - 将调研结果纳入设计决策依据
- **P3 编码前**：用 Context7 MCP 查询所用库的最新 API、代码示例 + WebSearch 搜索最新实现模式，确保使用当前推荐的 API，不用已废弃写法
- Context7 用法：先 `resolve-library-id` 获取库 ID → 再 `query-docs` 查询具体问题
- 调研结果记录到 `architecture_decisions`

### 六阶段顺序执行（禁止跳过）

| 阶段 | 名称 | 阶段审查 | 允许工具 |
|------|------|---------|---------|
| P1 | 需求分析 | 需求审查 | Read, Glob, Grep, WebSearch, WebFetch |
| P2 | 系统设计 | 设计审查 | Read, Glob, Grep, WebSearch, WebFetch, **Context7 MCP**, Chrome |
| P3 | 编码实现 | 代码审查(含工具链) | + Write, Edit, Bash（非测试非git）, **Context7 MCP** |
| P4 | 测试验证 | 测试审查(含覆盖率) | + Bash（含测试，非 git 提交）, Chrome |
| P5 | 集成审查 | 集成审查 | Read, Glob, Grep, Write/Edit（仅修复审查问题） |
| P6 | 部署交付 | 交付审查 | + Bash（git/deploy）, Write/Edit（仅文档） |

每阶段须通过 `/review` 审查才可推进。Hooks 自动拦截违规操作。用户可要求跳过阶段，但须先说明风险，获确认后记录到 `phase_history`。详见 `.claude/rules/01-lifecycle-phases.md`。

### 每次回复前 4 步自检

1. **阶段** — `current_phase` 是什么？（读 `.claude/project-state.md`）
2. **PRD** — 要做的事对应 PRD 哪条？对应不上则不做
3. **合规** — 操作在当前阶段允许吗？
4. **状态** — 变更后 `.claude/project-state.md` 更新了吗？

有疑问 → 用 Read 重读 `.claude/project-state.md`，不依赖记忆。详见 `.claude/rules/05-anti-amnesia.md`。

### Bash 命令格式（必须遵守）

**所有 Bash 命令必须写成单行。** 禁止在 `2>&1`、`|`、`&&` 前换行，否则 zsh 会把下一行的内容当作独立命令执行导致报错。
