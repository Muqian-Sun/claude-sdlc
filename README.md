<p align="center">
  <img src="logo-banner.svg" alt="claude-sdlc" width="700"/>
</p>

<p align="center">
  <strong>让 Claude Code 严格按 SDLC 规范开发 — 一条命令安装，零配置开箱即用。</strong>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/claude-sdlc"><img src="https://img.shields.io/npm/v/claude-sdlc.svg?style=flat-square" alt="npm version"/></a>
  <a href="https://www.npmjs.com/package/claude-sdlc"><img src="https://img.shields.io/npm/dm/claude-sdlc.svg?style=flat-square" alt="downloads"/></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/npm/l/claude-sdlc.svg?style=flat-square" alt="license"/></a>
  <a href="https://github.com/Muqian-Sun/claude-sdlc"><img src="https://img.shields.io/github/stars/Muqian-Sun/claude-sdlc?style=flat-square" alt="stars"/></a>
  <a href="https://github.com/Muqian-Sun/claude-sdlc/issues"><img src="https://img.shields.io/github/issues/Muqian-Sun/claude-sdlc?style=flat-square" alt="issues"/></a>
  <a href="https://github.com/Muqian-Sun/claude-sdlc/commits"><img src="https://img.shields.io/github/last-commit/Muqian-Sun/claude-sdlc?style=flat-square" alt="last commit"/></a>
  <a href="https://www.npmjs.com/package/claude-sdlc"><img src="https://img.shields.io/bundlephobia/min/claude-sdlc?style=flat-square" alt="size"/></a>
</p>

---

## 一条命令安装

```bash
npx claude-sdlc
```

安装到指定目录：

```bash
npx claude-sdlc ./my-project
```

安装完成后，在项目目录启动 `claude` 即可自动加载全部规范。**每个项目只需安装一次。**

一键卸载：

```bash
npx claude-sdlc uninstall
```

---

## 解决什么问题

| 痛点 | 解决方案 |
|------|---------|
| Claude 不走流程，直接写代码 | 六阶段强制流程：需求 → 设计 → 编码 → 测试 → 审查 → 交付 |
| 需要反复输入指令推进 | **自动驱动**：确认需求和设计后，编码到交付全自动 |
| 规范需要每次手动提醒 | CLAUDE.md + rules/ 自动加载，14 个 Hooks 运行时拦截 |
| Claude 自行加减功能 | **PRD 驱动**：严格按需求清单，每行代码对应 PRD |
| **UI 设计很丑很土很过时** | **✨ UI/UX Pro Max 强制集成**：67 风格+96 配色+57 字体，禁止 Bootstrap 3/jQuery UI |
| 每个阶段都要审查太慢 | **只审查一次**：P5 综合审查是唯一关卡，P3/P4/P6 完成即推进 |
| 长对话后遗忘规范 | **多层防御** + 抗压缩机制，compaction 后自动恢复 |
| 单线程开发效率低 | **3 个自定义 Agent** 并行编码/测试/审查 |
| CLAUDE.md 过长导致遵循率下降 | 精简到 ~44 行，详细规则拆到 rules/ 按需加载 |

---

## 工作流程

```
你说"帮我实现XX"
  ↓
P1 需求分析 → 整理 PRD →【你确认】
  ↓
P2 系统设计 → 设计方案 →【你确认】
  ↓ 以下全自动
P3 编码 → P4 测试 → P5 综合审查（唯一审查）→ P6 交付 → 完成报告
```

**用户只需两次确认（PRD + 设计），其余全自动。** P5 是唯一正式审查关卡（代码质量+测试质量+集成一致性+PRD追溯），未通过自动修复重试，最多 3 次后才请求帮助。

---

## 核心特性

### 14 个 Hooks — 全生命周期拦截

| Hook | 类型 | 作用 |
|------|------|------|
| SessionStart | command | 会话启动/恢复时注入 SDLC 上下文 |
| SessionEnd | command | 会话结束时归档状态摘要 |
| UserPromptSubmit | command | 每次用户输入时注入阶段提醒 |
| PreToolUse (Write/Edit) | command | P3 前拦截代码写入 |
| PreToolUse (Bash) | command | P4 前拦截测试、P6 前拦截 git |
| PostToolUse | command | 文件修改后提醒更新状态（async） |
| PostToolUseFailure | command | 工具失败时注入恢复建议 |
| Stop | agent | 回复后自检阶段合规性 |
| PreCompact | agent | 压缩前自动保存状态 |
| SubagentStart | command | 子 Agent 注入 SDLC + PRD 上下文 |
| SubagentStop | command | 子 Agent 完成时验证输出质量 |
| TaskCompleted | command | 子任务完成时提醒验证合规 |
| PermissionRequest | command | 按 SDLC 阶段自动决策权限 |
| fileSuggestion | command | `@` 文件补全优先显示 SDLC 文件 |

### 3 个自定义 Agent — 并行开发

| Agent | 阶段 | 核心能力 |
|-------|------|---------|
| sdlc-coder | P3 | 严格按 PRD 编码，禁止 PRD 外功能 |
| sdlc-tester | P4 | 每条 PRD 需求至少一个测试 |
| sdlc-reviewer | P5 | PRD 四环追溯（需求→设计→代码→测试） |

### ✨ UI/UX Pro Max — 现代设计智能（自动安装）

安装 SDLC 规范时**自动安装** UI/UX Pro Max Skill 作为依赖：

| 特性 | 内容 |
|------|------|
| **67 种 UI 风格** | glassmorphism、claymorphism、minimalism、brutalism、neumorphism、bento grid 等 |
| **96 个配色方案** | SaaS、电商、医疗、金融、教育等行业专属配色 |
| **57 种字体配对** | 精选标题+正文字体组合（集成 Google Fonts）|
| **99 条 UX 指南** | 可访问性、交互、性能、布局最佳实践 |
| **25 种图表类型** | 数据可视化和仪表板推荐 |
| **强制现代化** | ✅ shadcn/ui、Radix、Ant Design 5+ &nbsp; ❌ Bootstrap 3、jQuery UI、90年代风格 |

**自动激活**：P1 阶段涉及 UI 时自动使用 ui-ux-pro-max skill 调研和设计。

**质量保障**：P4 自动审查 Lighthouse（可访问性≥90）+ axe-core（0 违规）+ 响应式 + Core Web Vitals。

---

### 4 个 Skills — 斜杠命令

| 命令 | 作用 | 增强特性 |
|------|------|---------|
| `/review` | P5 综合审查（唯一正式审查） | `context: fork` 隔离上下文 + 技能级 hooks |
| `/status` | 查看完整项目状态 | `!`command`` 动态注入实时状态 |
| `/phase` | 阶段管理（查看/推进/回退） | `!`command`` 动态读取当前阶段 |
| `/checkpoint` | 手动保存状态快照 | — |

### 声明式权限控制

```
deny  → .env 文件绝对禁止读写（平台层面强制）
allow → Read/Glob/Grep/git只读/lint 自动放行（减少弹窗）
ask   → rm -rf / git push --force 等危险命令强制弹框确认
```

### 更多特性

- **statusLine** — 终端底部实时显示 `[SDLC P3] 编码实现 ●●●○○○ 任务描述`
- **sandbox** — 限制网络访问域名白名单
- **env** — 声明式注入 `SDLC_PROJECT`/`SDLC_VERSION` 环境变量
- **attribution** — Git commit 自动署名
- **spinnerVerbs** — 自定义中文加载动词（审查中、编码中、测试中...）
- **language** — 界面语言设为中文

---

## 审查策略

**P5 是唯一正式审查关卡**，一次性完成所有质量检查：

| 审查维度 | 检查内容 |
|---------|---------|
| 代码质量 | Lint + Typecheck + Build + 依赖安全 + 编码规范 |
| 测试质量 | PRD 测试覆盖 + 通过率 + 覆盖率（行≥80%/关键≥90%/分支≥70%） |
| 集成一致性 | PRD 四环追溯 + 全局一致性 + 安全性 + 性能 |
| 交付就绪 | 无敏感信息 + Commit 粒度 + 文档更新 |

其他阶段不审查——P1/P2 靠用户确认推进，P3/P4/P6 完成条件满足后直接推进。

---

## 安装后的文件结构

```
your-project/
├── CLAUDE.md                          # 核心控制文件（~44行）
└── .claude/
    ├── settings.json                  # 14 Hooks + Permissions + Settings
    ├── project-state.md               # SDLC 状态存储（活文档）
    ├── rules/                         # 8 个规则文件（按需自动加载）
    │   ├── 01-lifecycle-phases.md     # 六阶段定义 + P5 审查清单
    │   ├── 02-coding-standards.md     # 编码规范
    │   ├── 03-testing-standards.md    # 测试规范
    │   ├── 04-git-workflow.md         # Git 工作流
    │   ├── 05-anti-amnesia.md         # 反遗忘机制
    │   ├── 06-review-tools.md         # 审查工具链
    │   ├── 07-parallel-agents.md      # 多 Agent 并行
    │   └── 08-chrome-integration.md   # Chrome 浏览器集成
    ├── hooks/                         # 14 个 Hook 脚本
    ├── agents/                        # 3 个自定义 Agent
    │   ├── sdlc-coder.md             # P3 编码 Agent
    │   ├── sdlc-tester.md            # P4 测试 Agent
    │   └── sdlc-reviewer.md          # P5 审查 Agent
    ├── skills/                        # 4 个技能命令
    │   ├── phase/SKILL.md            # /phase
    │   ├── status/SKILL.md           # /status
    │   ├── checkpoint/SKILL.md       # /checkpoint
    │   └── review/SKILL.md           # /review（P5 综合审查）
    └── reviews/                       # 审查报告持久化
```

---

## PermissionRequest 权限决策矩阵

PermissionRequest Hook 根据当前 SDLC 阶段自动决策工具权限：

| 工具 | P0-P2 | P3 | P4 | P5 | P6 |
|------|-------|----|----|----|----|
| Write/Edit (代码) | deny | allow | allow | allow(修复) | allow(文档) |
| Write/Edit (文档) | allow | allow | allow | allow | allow |
| Bash (git 只读) | allow | allow | allow | allow | allow |
| Bash (测试) | deny | deny | allow | allow | allow |
| Bash (git 写入) | deny | deny | deny | deny | allow |
| Chrome | P2 allow | deny | allow | deny | deny |
| Read/Glob/Grep | allow | allow | allow | allow | allow |

---

## 其他安装方式

### 全局安装

```bash
npm install -g claude-sdlc
claude-sdlc
```

### Shell 脚本安装（无需 Node.js）

```bash
git clone https://github.com/Muqian-Sun/claude-sdlc.git
cd claude-sdlc
./install.sh /path/to/your-project
```

### 前置依赖

- **Node.js >= 16**（npx/npm 方式）
- **jq**（可选）：Hook 脚本优先用 bash 内置字符串操作解析 JSON，无需 jq

---

## 自定义

| 需求 | 编辑 |
|------|------|
| 修改阶段定义 | `.claude/rules/01-lifecycle-phases.md` |
| 修改编码规范 | `.claude/rules/02-coding-standards.md` |
| 添加新规则 | `.claude/rules/` 下新增 `.md` 文件 |
| 调整拦截规则 | `.claude/hooks/` 下的脚本 |
| 修改权限矩阵 | `.claude/hooks/permission-request.sh` |
| 自定义 Agent | `.claude/agents/` 下修改 `.md` 文件 |
| 添加技能命令 | `.claude/skills/` 下新增目录和 `SKILL.md` |

---

## 常见问题

**已有 CLAUDE.md 会被覆盖吗？**
会直接覆盖为最新版本。

**已有 settings.json 怎么办？**
自动智能合并 — hooks 按 matcher 去重升级，permissions 合并不丢失，新增字段仅在用户未设置时写入。

**可以跳过阶段吗？**
可以，Claude 会先说明风险，确认后记录跳过原因并推进。

**从旧版本升级？**
直接重新运行 `npx claude-sdlc`，安装器自动合并新旧配置，不丢失用户自定义。

**如何卸载？**
```bash
npx claude-sdlc uninstall              # 卸载当前目录
npx claude-sdlc uninstall ./my-project # 卸载指定目录
```
自动清除全部 SDLC 文件（CLAUDE.md、rules/、hooks/、agents/、skills/、reviews/、settings.json 中的 SDLC 配置）。用户自定义的 settings.json 字段保留。

---

## License

MIT
