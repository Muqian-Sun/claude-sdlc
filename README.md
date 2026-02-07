<p align="center">
  <img src="logo-banner.svg" alt="claude-sdlc" width="700"/>
</p>

<p align="center">
  <strong>让 Claude Code 严格按 SDLC 规范开发 — 一条命令安装，零配置开箱即用。</strong>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/claude-sdlc"><img src="https://img.shields.io/npm/v/claude-sdlc.svg" alt="npm version"/></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/npm/l/claude-sdlc.svg" alt="license"/></a>
  <a href="https://www.npmjs.com/package/claude-sdlc"><img src="https://img.shields.io/npm/dm/claude-sdlc.svg" alt="downloads"/></a>
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
| 规范需要每次手动提醒 | CLAUDE.md + rules/ 自动加载，Hooks 运行时拦截 |
| Claude 自行加减功能 | **PRD 驱动**：严格按需求清单，每行代码对应 PRD |
| 长对话后遗忘规范 | 七层防御 + 抗压缩机制，compaction 后自动恢复 |
| CLAUDE.md 过长导致遵循率下降 | 精简到 ~100 行，详细规则拆到 rules/ 自动加载 |

---

## 工作流程

```
你说"帮我实现XX"
  ↓
P1 需求分析 → 整理 PRD →【你确认】
  ↓
P2 系统设计 → 设计方案 →【你确认】
  ↓ 以下全自动
P3 编码 → P4 测试 → P5 集成审查 → P6 交付 → 完成报告
```

**用户只需两次确认（PRD + 设计），其余全自动。** 审查失败时自动修复重试，最多 3 次后才请求帮助。

---

## 核心特性

- **自动驱动** — P3→P6 全自动，用户坐等结果
- **PRD 驱动** — 每行代码对应 PRD 需求，禁止添加/减少
- **运行时拦截** — Hooks 自动拦截违规操作（P3 前写代码、P4 前跑测试、P6 前 git）
- **自动审查** — 每阶段通过 `/review` 审查才推进，集成真实工具链（Lint/Typecheck/Coverage）
- **抗压缩** — PreCompact Hook 保存状态，compaction 后自动恢复继续
- **多 Agent 并行** — P3/P4/P5 阶段支持 Task 工具并行开发
- **斜杠命令** — `/phase`、`/status`、`/checkpoint`、`/review`

---

## 安装后的文件结构

```
your-project/
├── CLAUDE.md                       # 核心控制文件（~100行）
└── .claude/
    ├── settings.json               # Hooks 配置
    ├── rules/                      # 7 个规则文件（自动加载）
    │   ├── 01-lifecycle-phases.md
    │   ├── 02-coding-standards.md
    │   ├── 03-testing-standards.md
    │   ├── 04-git-workflow.md
    │   ├── 05-anti-amnesia.md
    │   ├── 06-review-tools.md
    │   └── 07-parallel-agents.md
    ├── hooks/                      # 2 个拦截脚本
    │   ├── check-phase-write.sh
    │   └── check-phase-test.sh
    ├── commands/                   # 4 个斜杠命令
    │   ├── phase.md
    │   ├── checkpoint.md
    │   ├── status.md
    │   └── review.md
    └── reviews/                    # 审查报告持久化
```

---

## 七层防御机制

| 层 | 机制 | 作用 |
|----|------|------|
| 1 | CLAUDE.md 启动指令 | 自动状态检查和初始化 |
| 2 | rules/ 规则文件 | 详细规范自动加载 |
| 3 | PreToolUse Hooks | 硬拦截违规操作，不依赖 Claude 自觉 |
| 4 | PostToolUse Hook | 文件修改后同步状态 |
| 5 | Stop Hook | 每次回复后自检 + 自动驱动 |
| 6 | PreCompact Hook | 压缩前保存状态 |
| 7 | 用户命令 | /status、/checkpoint、/phase、/review |

---

## 其他安装方式

### 全局安装

```bash
npm install -g claude-sdlc
claude-sdlc
```

### Shell 脚本安装（无需 Node.js）

```bash
git clone https://github.com/muqian/claude-sdlc.git
cd claude-sdlc
./install.sh /path/to/your-project
```

### 前置依赖

- **Node.js >= 16**（npx/npm 方式）
- **jq**（可选）：Hook 脚本优先用 jq 解析 JSON，未安装时自动降级为 sed

---

## 自定义

| 需求 | 编辑 |
|------|------|
| 修改阶段定义 | `.claude/rules/01-lifecycle-phases.md` |
| 修改编码规范 | `.claude/rules/02-coding-standards.md` |
| 添加新规则 | `.claude/rules/` 下新增 `.md` 文件 |
| 调整拦截规则 | `.claude/hooks/` 下的脚本 |
| 添加斜杠命令 | `.claude/commands/` 下新增 `.md` 文件 |

---

## 常见问题

**已有 CLAUDE.md 会被覆盖吗？**
会直接覆盖为最新版本。

**已有 settings.json 怎么办？**
自动智能合并 hooks 配置（去重），保留原有配置不丢失。

**可以跳过阶段吗？**
可以，Claude 会先说明风险，确认后记录跳过原因并推进。

**如何卸载？**
```bash
npx claude-sdlc uninstall              # 卸载当前目录
npx claude-sdlc uninstall ./my-project # 卸载指定目录
```
自动清除 CLAUDE.md、.claude/rules/、hooks/、commands/、reviews/、settings.json 中的 hooks 配置。

---

## License

MIT
