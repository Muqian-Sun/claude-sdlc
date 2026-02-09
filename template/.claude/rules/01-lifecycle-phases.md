# SDLC 阶段定义

所有阶段顺序执行，禁止跳过。严格按 PRD 开发。

---

## P1 — 需求分析 + 架构设计

分析用户需求，检查 `project_roadmap` 和 `completed_tasks` 确保与整体规划一致。**先调研，再设计架构，涉及 UI 时创建原型在 Chrome 展示**，最后输出包含架构方案的完整 PRD，**用户确认后直接推进到 P2 并启动自动驱动**。

### 1. 调研（写 PRD 前必须执行）
| 类型 | 操作 | 工具 |
|------|------|------|
| 技术调研 | 查最新文档+方案/最佳实践 | Context7 MCP, WebSearch |
| **UI 调研（涉及 UI 时强制）** | **1. 使用 ui-ux-pro-max skill**（自动激活或在提示词中明确声明）<br>**2. WebSearch** 搜索 "{框架} modern UI 2026" + "{产品类型} best practices 2026"<br>**3. 从 67 风格+96 配色+57 字体中选择**（不得随意配色）<br>**4. 组件库**：shadcn/ui、Radix、Ant Design 5+、Mantine<br>**禁止**：Bootstrap 3/4、jQuery UI、无样式 HTML、90 年代表格、float 布局 | ui-ux-pro-max skill + WebSearch |

### 2. 架构设计
基于调研结果设计技术架构：模块划分、数据模型、接口定义、技术选型

### 3. 原型设计与展示（涉及 UI 时）
1. **应用 ui-ux-pro-max 设计系统**：使用选定的风格+配色+字体创建原型
2. **现代 CSS 必须**：Flexbox/Grid 布局 + CSS Variables + 无 float/table 布局
3. **创建自包含 HTML**（内联 CSS/JS），包含 hover/focus/active 状态
4. **Chrome 展示**：使用 `mcp__claude-in-chrome__*` 打开，测试响应式（至少 3 个断点：375px/768px/1440px）
5. **原型确定的设计系统作为 PRD 一部分**，用户确认后锁定（不得在 P2 擅自修改）

### 4. PRD 确认（精简格式）
1. 向用户展示 PRD（表格格式，总长度≤150行）：
   - **需求表**：ID | 需求（≤30字）| 验收标准（1条，可测试）
   - **架构**：技术栈 + 核心模块（≤5条关键决策）
   - **UI 设计系统**（涉及 UI 时必须）：风格 + 配色名称 + 字体配对 + 组件库
   - **原型**：文件路径（已在 Chrome 展示过）
2. 用户确认 → 写入 project-state.md 的 `prd` + `architecture_decisions` + `ui_design`（精简格式，见 09-memory-management.md + 10-ui-ux-standards.md）
3. PRD 写入即锁定，后续阶段以此为唯一依据。如需修改 → 回 P1 重新获用户确认

**PRD 精简要求**：
- 需求描述 ≤30字（一句话核心功能）
- 验收标准 1条（可量化、可测试）
- 无范围排除项（默认只实现列出的需求）
- 架构决策 ≤5条（技术栈 + 核心模式）
- **UI 设计系统**（涉及 UI 时）：`ui_design: {style, colors, fonts, components, prototype}`

### 允许工具
✅ Read, Glob, Grep, WebSearch, WebFetch, Context7 MCP, Chrome, Write/Edit（仅原型） ❌ Bash

---

## P2 — 编码实现

**自动驱动** — 编码完成后直接进入 P3。

编码前必须 Context7 MCP 查最新 API + WebSearch 查最新实现模式。严格按 PRD 架构方案编码。有独立模块时可用 Task 并行派发 `sdlc-coder` Agent。

### 禁止行为
- ❌ 实现 PRD 未列出的功能 / 添加"顺手"优化
- ❌ 跳过任何 PRD 需求 / 自行替换用户确认的方案
- 发现 PRD 遗漏 → 停止编码，回 P1 确认

### 允许工具
✅ Read, Glob, Grep, Write, Edit, Bash（非测试非git）, Context7 MCP, WebSearch ❌ Bash 测试命令

---

## P3 — 测试验证

**自动驱动** — 测试全通过后直接进入 P4。有独立模块时可并行派发 `sdlc-tester` Agent。

### UI 测试要求（涉及 UI 时必须）
- [ ] **视觉回归**：Playwright screenshot 测试主要页面/组件
- [ ] **响应式**：测试 3 个断点（375px/768px/1440px）
- [ ] **可访问性**：axe-core 集成测试，0 个 critical 违规
- [ ] **交互**：Testing Library 或 Playwright 覆盖所有用户流程

详见 `.claude/rules/10-ui-ux-standards.md` 的 P3 测试规范

### 允许工具
✅ Read, Glob, Grep, Write, Edit, Bash（含测试）, Chrome

---

## P4 — 综合审查（唯一正式审查）

**自动驱动** — 通过后自动进入 P5。发现问题回退 P2/P3 修复。

**P4 是唯一正式审查关卡**，涵盖代码质量、测试质量、集成一致性、PRD 追溯。

产出物：综合审查报告 + **PRD 完整追溯表**（每条需求 → 架构模块 → 代码文件:行号 → 测试）

### 审查清单（`/review`）

#### 代码质量
- [ ] **Lint + Typecheck + Build + 依赖安全**通过（0 error，无 high/critical 漏洞）
- [ ] 代码规范按 02-coding-standards.md + 无安全漏洞（注入/XSS/硬编码敏感信息）
- [ ] **UI/UX 规范**（涉及 UI 时）：按 10-ui-ux-standards.md 检查（现代性+可访问性+响应式+设计系统一致性）

#### 测试质量
- [ ] 每条 PRD 需求有对应测试 + 测试全部通过
- [ ] 覆盖率：行 ≥80%、关键业务 ≥90%、分支 ≥70%
- [ ] 测试质量 — 命名清晰、独立、mock 合理、回归保护

#### 集成一致性 + PRD 追溯
- [ ] **PRD 追溯** — 需求→架构→代码→测试，无断链 + **无 PRD 外变更**
- [ ] 全局一致性（接口、数据模型、错误处理策略一致）
- [ ] 安全性 + 性能（无 N+1、无重复 I/O）+ 无遗漏 TODO/FIXME

#### UI/UX 审查（涉及 UI 时必须）
- [ ] **设计系统一致性** — 配色/字体/间距/圆角符合 PRD 定义，无随意修改
- [ ] **现代性** — 使用现代组件库（shadcn/ui、Radix、Ant Design 5+），无 Bootstrap 3/jQuery UI/90年代风格
- [ ] **可访问性** — Lighthouse ≥90 分 + axe-core 0 个 critical 违规
- [ ] **响应式** — 测试 3 个断点（375px/768px/1440px）通过
- [ ] **性能** — Core Web Vitals 达标（LCP<2.5s、CLS<0.1）
- [ ] **工具审查**：运行 `npx lighthouse` + `npx @axe-core/cli` 验证

详见 `.claude/rules/10-ui-ux-standards.md` 完整审查清单

### 允许工具
✅ Read, Glob, Grep, Bash（工具链检查+测试验证） ⚠️ Write/Edit（仅修复审查问题，修复后需重验证）

---

## P5 — 部署交付

**自动完成** — git add/commit/push + 创建 PR + 更新文档 + 输出交付摘要报告。

### 允许工具
✅ Read, Glob, Grep, Bash（git/deploy） ⚠️ Write/Edit（仅文档）
