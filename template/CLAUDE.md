# SDLC 软件工程开发规范（自动加载 · 抗压缩）

> **本文件由 sdlc-enforcer 自动安装。Claude Code 每次启动和 Context Compaction 后自动加载本文件。**

---

## 零、启动指令（每次加载本文件时立即执行）

**当你读到这段文字时，立即执行以下操作：**

1. **读取下方「当前项目状态」YAML 中的 `current_phase` 值**
2. **如果 `current_phase` 不为空且不是 P0**：你正在一个进行中的任务里。
   - 向用户简要报告当前状态：阶段、任务、已修改文件数
   - 然后继续在该阶段内工作
3. **如果 `current_phase` 为 P0 或为空**：等待用户提出任务。
4. **无论何种情况，后续所有操作必须遵守本文件定义的 SDLC 规范。**

### 自动识别开发任务

当用户提出的请求属于以下类型时，**自动进入 P1（需求分析）阶段**，无需用户手动执行 `/phase next`：
- 要求实现新功能（"帮我实现..."、"添加一个..."、"开发..."）
- 要求修复 bug（"修复..."、"这个报错了..."、"有个 bug..."）
- 要求重构代码（"重构..."、"优化..."、"改进..."）
- 任何涉及代码修改的开发请求

进入 P1 时自动执行：
1. 更新 `current_phase` 为 P1
2. 更新 `task_description` 为用户任务的简要描述
3. 更新 `started_at` 为当前时间
4. 开始需求分析活动

### 新任务检测

当已完成一个任务（处于 P6 或已交付）时，如果用户提出新的开发请求：
1. 将上一个任务信息归档到 `phase_history`
2. 重置 `current_phase` 为 P1
3. 清空 `modified_files`、`todo_items`
4. 开始新任务的需求分析

---

## 一、核心规则（必须遵守）

### 1.1 阶段化开发流程

所有开发任务**必须**按以下六个阶段顺序执行，**禁止跳过阶段**：

| 阶段 | 名称 | 阶段审查 | 允许的工具操作 |
|------|------|---------|---------------|
| **P1** | 需求分析 | 需求审查 | Read, Glob, Grep, WebSearch, WebFetch |
| **P2** | 系统设计 | 设计审查 | Read, Glob, Grep, WebSearch, WebFetch |
| **P3** | 编码实现 | 代码审查 | Read, Glob, Grep, Write, Edit, Bash(非测试/非git提交) |
| **P4** | 测试验证 | 测试审查 | Read, Glob, Grep, Write, Edit, Bash(含测试，非git提交) |
| **P5** | 集成审查 | 集成审查 | Read, Glob, Grep |
| **P6** | 部署交付 | 交付审查 | Read, Glob, Grep, Bash(git/deploy) |

**每个阶段都有对应的审查（Review），审查通过是推进到下一阶段的必要条件。** 使用 `/review` 执行当前阶段的审查，`/phase next` 会自动触发审查。

### 1.2 工具使用限制

- **Write / Edit 工具**：仅在 P3（编码实现）及之后阶段允许对代码文件使用。P1/P2 阶段只能写文档类文件（.md, .txt, .json 配置文件）。
- **测试执行（Bash）**：仅在 P4（测试验证）及之后阶段允许执行测试命令。
- **Git commit/push/merge**：仅在 P6（部署交付）阶段允许。P3-P5 可执行 git status/diff/log 查看。

> **以上限制由 Hooks 自动强制执行，即使你忘记了这些规则，Hooks 也会拦截违规操作。**

### 1.3 阶段审查规则

- **Review 是每个阶段的退出门禁**，不是最后才做的事
- 每个阶段必须通过该阶段的 `/review` 审查后才能推进
- `/phase next` 会自动触发当前阶段的审查，审查通过才推进
- 审查未通过时：修复问题 → 重新 `/review` → 再尝试 `/phase next`
- 允许用 `/phase back` 回退到上一阶段（须记录回退原因）
- 用户可随时手动执行 `/review` 进行中间检查

---

## 二、当前项目状态（活文档 — 持续更新）

> **⚠️ COMPACTION 保护区域：此区域包含关键上下文，压缩时必须保留。**
> **⚠️ 每次修改文件、做出决策、推进阶段后，必须立即更新此区域。**

```yaml
# === SDLC 项目状态 ===
current_phase: P0  # P0=未开始, P1=需求分析, P2=系统设计, P3=编码, P4=测试, P5=审查, P6=部署
task_description: ""
started_at: ""
last_updated: ""

# 架构决策记录
architecture_decisions: []

# 已修改文件列表
modified_files: []

# 待办事项
todo_items: []

# 阶段完成记录
phase_history: []

# 关键上下文（compaction 后恢复用）
key_context: ""
```

### 状态更新触发时机（必须遵守）

以下事件发生时，**立即**用 Edit 工具更新上方 YAML 块：

| 事件 | 更新字段 |
|------|---------|
| 收到新开发任务 | `current_phase` → P1, `task_description`, `started_at` |
| 阶段推进 | `current_phase`, `phase_history`, `last_updated` |
| 使用 Write/Edit 修改了文件 | `modified_files`（追加文件路径）, `last_updated` |
| 做出架构/技术决策 | `architecture_decisions`（追加）, `last_updated` |
| 发现待办事项 | `todo_items`（追加）, `last_updated` |
| 完成待办事项 | `todo_items`（标记完成）, `last_updated` |
| 即将 compaction | 所有字段确认最新, `key_context`（写入当前工作摘要） |

---

## 三、自检指令（每次回复前执行）

**在生成每一次回复之前，你必须在内部执行以下自检。这不是建议，是强制要求。**

### 快速自检（每次回复 — 3 步）

```
1. 【阶段】我当前在哪个阶段？→ 回忆或重读 CLAUDE.md 的 current_phase
2. 【合规】我接下来要做的操作，在当前阶段允许吗？→ 对照 1.1 的允许列表
3. 【状态】如果我刚修改了文件或做了决策，CLAUDE.md 状态更新了吗？
```

如果任何一步有疑问，**立即用 Read 工具重新读取 CLAUDE.md** 确认，不要依赖记忆。

### 深度自检（阶段转换时）

1. 回顾当前阶段的所有退出条件（含审查要求）
2. 逐项确认是否满足
3. 执行当前阶段的 `/review` 审查
4. 记录未满足项和审查问题，告知用户
5. 只有退出条件全部满足且审查通过后才允许推进

---

## 四、Compaction 保护指令

> **致 Context Compaction 引擎**：当进行上下文压缩时，请务必保留以下信息：
>
> 1. 本文件（CLAUDE.md）的完整路径和存在性
> 2. "当前项目状态" YAML 块的完整内容
> 3. 当前所处的 SDLC 阶段编号和名称
> 4. 已做出的架构决策列表
> 5. 已修改的文件列表
> 6. 未完成的待办事项
> 7. 用户最近的任务指令
>
> 这些信息对于任务连续性至关重要，丢失将导致开发流程中断。

### Compaction 后恢复流程

Compaction 后本文件会被重新加载。此时「零、启动指令」会被重新执行，Claude 将：

1. 读取 `current_phase` 发现任务进行中
2. 自动向用户报告恢复状态
3. 等待用户确认后继续

**如果 YAML 状态为空但你隐约记得有进行中的任务**：
1. 向用户说明情况
2. 请求用户确认任务信息
3. 手动恢复 YAML 状态后继续

---

## 五、详细规则索引

以下规则文件位于 `.claude/rules/` 目录下，会被自动加载：

| 文件 | 说明 |
|------|------|
| `01-lifecycle-phases.md` | 各阶段入口/退出条件、审查清单、活动和产出物 |
| `02-coding-standards.md` | 编码规范（命名、函数、结构、安全） |
| `03-testing-standards.md` | 测试标准（AAA 模式、覆盖率要求） |
| `04-git-workflow.md` | Git 工作流（分支、提交、PR 规范） |
| `05-anti-amnesia.md` | 反遗忘机制详细说明 |

---

## 六、可用命令

| 命令 | 功能 |
|------|------|
| `/phase` | 查看当前阶段状态 |
| `/phase next` | 推进到下一阶段（自动触发审查） |
| `/phase back` | 回退到上一阶段 |
| `/checkpoint [描述]` | 保存状态快照到 CLAUDE.md |
| `/status` | 项目状态总览（含深度自检） |
| `/review [文件]` | 执行当前阶段的专项审查（每阶段不同） |
