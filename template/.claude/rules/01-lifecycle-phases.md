# SDLC 阶段定义

所有阶段顺序执行，禁止跳过。严格按 PRD 开发。

---

## P1 — 需求分析 + 设计

分析用户需求，检查 `project_roadmap` 和 `completed_tasks` 确保与整体规划一致。**执行流程：需求澄清+智能补充 → 技术调研+技术栈确认 → PRD确认 → 架构设计+方案对比确认 → 原型设计+设计确认**，**5 个关键决策点都确认后直接推进到 P2 并启动自动驱动**。

### 1. 需求澄清+智能补充

**目标**：多轮对话充分理解需求，从功能性角度智能补充，避免假设开发。

**执行步骤**：
1. **智能补充**（从功能性角度）：
   - 核心功能：用户明确要求的
   - 扩展功能：常见配套（如：登录→忘记密码/记住我，数据→分页/搜索/筛选）
   - 相关功能：体验提升（加载/错误/反馈/权限）

2. **系统性提问**（AskUserQuestion）：功能范围、目标用户、技术约束、非功能需求、UI偏好、数据集成

3. **确认并记录** project-state.md：
   ```yaml
   requirements_clarification:
     core_features: []
     extended_features: []
     related_features: []
     priority: "核心>扩展>相关"
     target_users: ""
     constraints: []
   ```

4. **【决策点1：需求确认】**

**判断充分性**（满足全部才推进）：核心/扩展/相关功能明确、优先级清楚、约束已知、UI方向确定

**禁止**：跳过澄清、凭记忆假设、问题过少、不做补充

### 2. 技术调研+技术栈确认

**询问偏好**：现有技术栈、团队技能、项目约束、性能/兼容性要求

**调研执行**：
- 技术：Context7 MCP + WebSearch 查最新文档和方案
- UI（强制）：ui-ux-pro-max skill，从 67 风格+96 配色+57 字体选择，组件库：shadcn/ui/Radix/Ant Design 5+，禁止 Bootstrap 3/4/jQuery UI

**调研输出**：技术栈推荐+理由、方案对比、最佳实践、UI建议

**【决策点2：技术栈确认】**

### 3. 编写 PRD 并确认

**PRD 内容**（≤150行）：需求清单（ID|描述≤30字|验收标准）按优先级排序、技术栈、非功能需求、UI方向

**【决策点3：PRD 确认】**：
- 用户确认后：写入 `.claude/prd.md` → 记录 `prd_file: ".claude/prd.md"` → 删除 `requirements_clarification`
- PRD 锁定，严格执行

**独立文件优势**：减少上下文、易管理、压缩保护、符合精简原则

### 4. 架构设计+方案对比

**提供 2-3 个方案**，每个含：方案名、模块划分、数据模型、API设计、技术细化、部署架构、优缺点、适用场景

**【决策点4：架构确认】**：用户选择后写入 `architecture_decisions`（≤5条），锁定不可擅改

### 5. 原型设计+设计确认（UI项目）

**创建原型**：应用 ui-ux-pro-max 设计系统，现代 CSS（Flexbox/Grid），自包含 HTML，Chrome 展示响应式（375/768/1440px）

**【决策点5：设计确认】**：演示交互，确认设计，锁定系统

### 6. 推进 P2

**5 个决策点确认** → 写入 project-state.md → 启动自动驱动

**允许工具**：Read, Glob, Grep, WebSearch, WebFetch, Context7, Chrome, Write/Edit（仅原型）

---

## P2 — 编码实现

**自动驱动**。编码前 Context7 MCP 查最新 API + WebSearch 查实现模式。严格按 PRD 架构编码。可并行派发 `sdlc-coder` Agent。

**禁止**：PRD 外功能、跳过需求、擅改方案。PRD 遗漏→回 P1。

**工具**：Read, Glob, Grep, Write, Edit, Bash（非测试非git）, Context7, WebSearch

---

## P3 — 测试验证

**自动驱动**。可并行派发 `sdlc-tester` Agent。

**UI测试**（必须）：视觉回归（Playwright）、响应式（3断点）、可访问性（axe-core 0违规）、交互（Testing Library）

**工具**：Read, Glob, Grep, Write, Edit, Bash（含测试）, Chrome

---

## P4 — 综合审查

**自动驱动**。唯一正式审查，涵盖代码/测试/集成/PRD追溯。产出：审查报告 + PRD 追溯表（需求→架构→代码→测试）

**审查清单**（`/review`）：
- **代码**：Lint/Typecheck/Build/依赖安全通过，符合 02-coding-standards.md，无安全漏洞
- **测试**：每条 PRD 有测试且通过，覆盖率（行≥80%/关键≥90%/分支≥70%），质量合格
- **集成**：PRD 追溯无断链、无 PRD 外变更、全局一致、安全性能合格
- **UI**（必须）：设计一致、现代组件库、Lighthouse≥90、响应式（3断点）、性能达标

详见 `.claude/rules/10-ui-ux-standards.md`

**工具**：Read, Glob, Grep, Bash（检查+测试），Write/Edit（仅修复）

---

## P5 — 部署交付

**自动完成**：git commit/push + PR + 文档 + 交付报告

**工具**：Read, Glob, Grep, Bash（git/deploy），Write/Edit（仅文档）
