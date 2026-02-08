# SDLC 开发规范

> 可用命令：`/phase`、`/status`、`/checkpoint`、`/review`

@.claude/project-state.md

## 启动指令

1. Read `.claude/project-state.md` 获取 `current_phase`
2. P1-P6：报告状态，继续工作
3. P0：等待用户任务

## 核心规则

- **严格按 PRD 开发**：每行代码对应 PRD 哪条需求？答不上来就不写。禁止增减 PRD 外内容
- **六阶段顺序执行**：P1需求→P2设计→P3编码→P4测试→P5审查→P6交付
- **只审查一次**：P5 是唯一正式审查关卡（代码+测试+集成+PRD追溯）。P1/P2 靠用户确认推进，P3/P4/P6 完成后直接推进
- **自动驱动**：P2 用户确认后，P3-P6 全自动。P5 审查未通过自动修复（最多3次）
- **任务自动识别**：用户说"实现/修复/重构..." → 自动进入 P1。旧任务完成后新请求 → 归档到 `completed_tasks` + 重置任务字段 + 新 P1。**`project_roadmap`/`completed_tasks`/`global_architecture` 永不重置**

## P2/P3 必须先调研

设计/编码前用 Context7 MCP 查最新文档 + WebSearch 查最新方案。禁止凭过时记忆编码。

**P2 涉及 UI 时必须**：WebSearch 搜索当前最流行的 UI 设计趋势、组件库、配色方案。UI 必须现代化，禁止过时/简陋的设计风格。

## 每次回复前自检

1. `current_phase` 是什么？
2. 要做的事对应 PRD 哪条？
3. 操作在当前阶段允许吗？
4. `.claude/project-state.md` 更新了吗？
5. 有 `project_roadmap` 吗？当前任务在整体规划中的位置？

有疑问 → Read `.claude/project-state.md`，不依赖记忆。

## Bash 命令格式

所有 Bash 命令必须单行。禁止在 `2>&1`、`|`、`&&` 前换行。

## 测试执行效率

测试只跑一次（`tee /tmp/sdlc-test-output.txt`），Read 分析结果，批量修复后再跑一次。最多 3 次。
