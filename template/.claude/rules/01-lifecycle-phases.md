# SDLC 阶段定义

所有阶段顺序执行，禁止跳过。严格按 PRD 开发。

---

## P1 — 需求分析 + 设计

分析用户需求，检查 `project_roadmap` 和 `completed_tasks` 确保与整体规划一致。**执行流程：需求澄清（多轮对话）→ 技术调研 → PRD 编写并确认 → 架构设计 → 原型设计**，**PRD 和设计方案都确认后直接推进到 P2 并启动自动驱动**。

### 1. 需求澄清（多轮对话，所有开发前必须执行）

**目标**：通过多轮对话充分理解用户真实需求，避免基于假设或过时记忆开发。

**执行步骤**：
1. **初步理解**：用户说"开发/实现/构建XX系统"时，**先不急于调研和写 PRD**
2. **多轮提问**：使用 AskUserQuestion 工具系统性获取关键信息：
   - **功能范围**：核心功能有哪些？优先级如何？哪些是必须，哪些可选？
   - **目标用户**：谁会使用？使用场景是什么？
   - **技术约束**：是否有技术栈偏好？需要兼容什么平台/浏览器？
   - **非功能需求**：性能要求？安全级别？可访问性标准？
   - **UI/UX 偏好**（如涉及界面）：风格参考？配色偏好？有无设计规范？
   - **数据和集成**：数据来源？需要对接的系统？
3. **确认理解**：整理用户回答，用简洁语言复述，确认理解正确
4. **记录到 project-state.md**：
   ```yaml
   task_description: "简短描述（≤30字）"
   requirements_clarification:  # 需求澄清结果（临时字段，写入 PRD 后删除）
     priority_features: ["必须功能1", "必须功能2", "可选功能"]
     target_users: "目标用户描述"
     constraints: ["技术约束", "性能要求", "兼容性要求"]
     ui_preferences: "UI 风格偏好或参考"  # 如涉及 UI
   ```

**何时结束对话进入调研**：
- ✅ 核心功能清晰（知道要做什么）
- ✅ 优先级明确（知道先做什么后做什么）
- ✅ 关键约束已知（知道什么不能做、必须遵守什么）
- ✅ UI 方向确定（如涉及界面：知道期望的风格和参考）

**禁止行为**：
- ❌ 跳过需求澄清直接调研
- ❌ 凭过时的对话记忆假设需求
- ❌ 只问一两个问题就开始写 PRD

### 2. 技术调研（需求澄清完成后执行）

**基于澄清的需求**进行针对性技术调研：
| 类型 | 操作 | 工具 |
|------|------|------|
| 技术调研 | 基于需求澄清的技术栈和场景，查最新文档+方案/最佳实践 | Context7 MCP, WebSearch |
| **UI 调研（涉及 UI 时强制）** | **1. 使用 ui-ux-pro-max skill**（自动激活或在提示词中明确声明）<br>**2. WebSearch** 搜索 "{框架} modern UI 2026" + "{产品类型} best practices 2026"<br>**3. 从 67 风格+96 配色+57 字体中选择**（基于用户偏好，不得随意配色）<br>**4. 组件库**：shadcn/ui、Radix、Ant Design 5+、Mantine<br>**禁止**：Bootstrap 3/4、jQuery UI、无样式 HTML、90 年代表格、float 布局 | ui-ux-pro-max skill + WebSearch |

**调研输出**：
- 推荐技术栈和理由（基于用户约束和需求）
- 关键技术方案对比（如有多个选择）
- 最佳实践和注意事项
- UI 风格建议（如涉及界面）

### 3. 编写 PRD（精简格式）

**基于需求澄清和技术调研**，编写产品需求文档：

1. **需求清单**（表格格式）：
   - ID | 需求描述（≤30字）| 验收标准（1条，可测试）
   - 按优先级排序（必须功能在前）
2. **技术栈选型**：列出主要技术和选型理由
3. **非功能需求**：性能、安全、可访问性指标
4. **UI 设计方向**（如涉及界面）：风格、配色方案名称、字体配对、组件库

**向用户展示 PRD 并确认**：
- 展示格式：精简表格（总长度≤150行）
- 用户确认后 → 写入 project-state.md 的 `prd` 字段
- **删除临时字段** `requirements_clarification`（已转化为 PRD）
- **PRD 写入即锁定**，后续开发严格按此执行

**PRD 确认是第一个检查点**：
- ✅ PRD 确认 → 继续架构设计和原型设计
- ❌ PRD 需修改 → 返回需求澄清或调研环节

### 4. 架构设计（PRD 确认后执行）

基于**已确认的 PRD** 设计技术架构：

**设计内容**：
- **模块划分**：系统分为哪几个模块？模块间如何交互？
- **数据模型**：核心实体和关系
- **接口定义**：主要 API 设计（RESTful/GraphQL）
- **技术选型细化**：具体版本、配置、依赖关系
- **部署架构**：开发/测试/生产环境

**输出**：
- 架构决策文档（≤5条关键决策）
- 写入 project-state.md 的 `architecture_decisions`

### 5. 原型设计与展示（涉及 UI 时，架构设计后执行）

基于**已确认的 PRD 和架构设计**创建可交互原型：

1. **应用 ui-ux-pro-max 设计系统**：使用调研阶段选定的风格+配色+字体
2. **现代 CSS 必须**：Flexbox/Grid 布局 + CSS Variables + 无 float/table 布局
3. **创建自包含 HTML**（内联 CSS/JS），包含 hover/focus/active 状态
4. **Chrome 展示**：使用 `mcp__claude-in-chrome__*` 打开，测试响应式（至少 3 个断点：375px/768px/1440px）
5. **原型路径写入** project-state.md 的 `ui_design.prototype`

**向用户展示原型并确认**：
- 在 Chrome 中演示交互效果
- 确认配色、字体、布局符合预期
- 用户确认后 → 锁定设计系统（不得在 P2 擅自修改）

### 6. 最终确认（第二个检查点）

**确认内容**：
- ✅ PRD（已在步骤 3 确认）
- ✅ 架构设计方案
- ✅ 原型（如涉及 UI）

**写入 project-state.md**：
```yaml
prd: [...]  # 步骤 3 已写入
architecture_decisions: [...]  # 步骤 4 写入
ui_design:  # 步骤 5 写入（如涉及 UI）
  style: "glassmorphism"
  colors: "SaaS-Blue-Professional"
  fonts: {heading: "Poppins", body: "Inter"}
  components: "shadcn/ui"
  prototype: "/tmp/prototype-{timestamp}.html"
```

**用户最终确认 → 直接推进到 P2 并启动自动驱动**

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
