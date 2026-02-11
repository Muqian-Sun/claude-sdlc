# SDLC 开发规范

> 可用命令：`/phase`、`/status`、`/checkpoint`、`/review`、`/archive`

@.claude/project-state.md

## 启动指令

1. Read `.claude/project-state.md` 获取 `current_phase`
2. P1-P5：报告状态，继续工作
3. P0：等待用户任务

## 核心规则

- **严格按 PRD 开发**：每行代码对应 PRD 哪条需求？答不上来就不写。禁止增减 PRD 外内容
- **五阶段顺序执行**：P1需求+设计→P2编码→P3测试→P4审查→P5交付
- **只审查一次**：P4 是唯一正式审查关卡（代码+测试+集成+PRD追溯）。P1 靠用户确认推进，P2/P3/P5 完成后直接推进
- **自动驱动**：P1 用户确认 PRD 后，P2-P5 全自动。P4 审查未通过自动修复（最多3次）
- **任务自动识别**：用户说"实现/修复/重构..." → 自动进入 P1。旧任务完成后新请求 → 归档到 `completed_tasks` + 重置任务字段 + 新 P1。**`project_roadmap`/`completed_tasks`/`global_architecture` 永不重置**

## P1 需求澄清+调研+设计+原型

**P1 执行流程**：需求澄清+智能补充 → 技术调研+技术栈确认 → PRD确认 → 架构设计+方案对比确认 → 原型设计+设计确认

### 1. 需求澄清+智能补充
充分对话，从功能性角度补充（核心/扩展/相关功能），使用 AskUserQuestion 系统性提问，判断充分性后记录 `requirements_clarification`。**【决策点1：需求确认】**

### 2. 技术调研+技术栈确认
先询问技术偏好，Context7 MCP + WebSearch 调研，UI 强制用 ui-ux-pro-max（67风格+96配色+57字体）。**【决策点2：技术栈确认】**

### 3. 编写 PRD 并确认
编写精简 PRD（≤150行），写入 `.claude/prd.md`，记录 `prd_file`，删除 `requirements_clarification`，锁定。**【决策点3：PRD 确认】**

### 4. 架构设计+方案对比
提供 2-3 个方案（含模块/数据/API/部署/优缺点/场景），用户选择后写入 `architecture_decisions`。**【决策点4：架构确认】**

### 5. 原型设计+设计确认（UI项目）
应用设计系统，Chrome 展示响应式（375/768/1440px），写入 `ui_design`，禁止 Bootstrap 3/4/jQuery UI。**【决策点5：设计确认】**

**5个决策点确认 → P2 自动驱动**

## 每次回复前自检

1. `current_phase` 是什么？
2. 要做的事对应 PRD 哪条？
3. 操作在当前阶段允许吗？
4. `.claude/project-state.md` 更新了吗？

有疑问 → Read `.claude/project-state.md`，不依赖记忆。

## 执行规范

**Bash 格式**：所有命令必须单行。禁止在 `2>&1`、`|`、`&&` 前换行。
**测试效率**：只跑一次（`tee /tmp/sdlc-test-output.txt`），Read 分析结果，批量修复后再跑一次。最多 3 次。
**输出精简**：报告/PRD/文档使用简洁格式（详见 09-memory-management.md）：
- 一句话原则：能用一句话不用两句
- 表格优先：结构化信息用表格
- 长度限制：PRD≤150行，审查≤15行，交付≤10行
- 记忆精简：completed_tasks 用精简格式，≥5个时自动归档
