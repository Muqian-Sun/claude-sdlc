# SDLC Enforcer for Claude Code

**让 Claude Code 严格按照软件开发生命周期（SDLC）规范进行开发。**

自动加载、运行时拦截、抗上下文压缩——零配置，开箱即用。

---

## 解决什么问题

| 问题 | 解决方案 |
|------|---------|
| Claude Code 不遵循开发流程，直接写代码 | SDLC 六阶段强制流程（需求→设计→编码→测试→审查→交付） |
| 规范需要手动每次提醒 | CLAUDE.md + rules 自动加载，Hooks 运行时拦截 |
| 长对话后 Claude 忘记规范（context compaction） | 五层防御机制，CLAUDE.md 活文档自动恢复 |

## 核心特性

- **六阶段 SDLC 流程**：P1 需求分析 → P2 系统设计 → P3 编码实现 → P4 测试验证 → P5 集成审查 → P6 部署交付
- **每阶段独立审查**：每个阶段都有对应的专项 Review，审查通过才能推进，错误越早发现修复成本越低
- **自动加载**：CLAUDE.md 和 rules/ 在 Claude Code 启动时自动加载
- **运行时拦截**：Hooks 自动拦截当前阶段不允许的操作（如 P1 阶段写代码）
- **抗压缩**：Context compaction 后自动从 CLAUDE.md 恢复项目状态
- **斜杠命令**：`/phase`、`/status`、`/checkpoint`、`/review` 管理开发流程

---

## 快速安装

### 方式 1：克隆后安装

```bash
git clone https://github.com/<your-username>/sdlc-enforcer.git
cd sdlc-enforcer
./install.sh /path/to/your-project
```

### 方式 2：安装到当前目录

```bash
git clone https://github.com/<your-username>/sdlc-enforcer.git
cd sdlc-enforcer
./install.sh .
```

### 前置依赖

- **jq**：Hook 脚本需要 jq 解析 JSON
  - macOS: `brew install jq`
  - Ubuntu: `sudo apt-get install jq`
  - 如未安装 jq，Hooks 会自动降级为放行（不会阻塞工作）

---

## 安装后的文件结构

```
your-project/
├── CLAUDE.md                          # 核心控制文件（自动加载）
└── .claude/
    ├── settings.json                  # Hooks 配置
    ├── rules/
    │   ├── 01-lifecycle-phases.md     # SDLC 阶段定义
    │   ├── 02-coding-standards.md     # 编码规范
    │   ├── 03-testing-standards.md    # 测试标准
    │   ├── 04-git-workflow.md         # Git 工作流
    │   └── 05-anti-amnesia.md         # 反遗忘机制
    ├── hooks/
    │   ├── check-phase-write.sh       # 拦截非法代码写入
    │   └── check-phase-test.sh        # 拦截非法测试执行
    └── commands/
        ├── phase.md                   # /phase 命令
        ├── checkpoint.md              # /checkpoint 命令
        ├── status.md                  # /status 命令
        └── review.md                  # /review 命令
```

---

## 使用指南

### 开始开发

在目标项目目录启动 Claude Code：

```bash
cd your-project
claude
```

Claude 会自动加载 SDLC 规范。当你提出开发任务时，Claude 会从 P1（需求分析）开始。

### 阶段管理

```
/phase           # 查看当前阶段和退出条件
/phase next      # 推进到下一阶段（自动检查退出条件）
/phase back      # 回退到上一阶段
```

### 项目状态

```
/status          # 查看全面的项目状态报告
/checkpoint      # 保存状态快照（建议长对话时定期使用）
```

### 阶段审查

```
/review                    # 执行当前阶段的专项审查
/review src/auth/login.ts  # 审查指定文件（P3+ 阶段）
```

`/review` 会根据当前阶段自动选择审查类型。`/phase next` 会自动触发审查。

### SDLC 六阶段说明

| 阶段 | 名称 | 核心活动 | 阶段审查 |
|------|------|---------|---------|
| **P1** | 需求分析 | 理解需求、分析代码库、识别范围 | 需求审查（完整性、明确性、可行性） |
| **P2** | 系统设计 | 架构设计、技术选型、实现规划 | 设计审查（架构合理性、需求覆盖） |
| **P3** | 编码实现 | 编写代码、遵循编码规范 | 代码审查（质量、安全、可维护性） |
| **P4** | 测试验证 | 编写和执行测试 | 测试审查（覆盖度、质量、结果） |
| **P5** | 集成审查 | 跨模块全局审查、需求追溯 | 集成审查（全局一致性、完整性追溯） |
| **P6** | 部署交付 | Git 提交、创建 PR | 交付审查（Commit 规范、文档） |

---

## 反遗忘机制

本系统通过五层防御对抗 Claude Code 的上下文遗忘问题：

1. **CLAUDE.md**：每次启动和 compaction 后自动加载，包含完整的规范摘要和项目状态
2. **rules/ 目录**：详细规范定义，自动加载，不受 compaction 影响
3. **PreToolUse Hooks**：运行时拦截违规操作，即使 Claude 忘记规范也能阻止
4. **Stop Hook**：每次回复后检查 SDLC 合规性
5. **PreCompact Hook**：compaction 前提醒 Claude 更新 CLAUDE.md 中的项目状态

```
正常工作 → 自检（每次回复） → Hooks 拦截（每次工具调用）
                                     ↓
Context Compaction → PreCompact 提醒更新 → 重新加载 CLAUDE.md + rules → 恢复状态
```

---

## 自定义配置

### 修改阶段定义

编辑 `.claude/rules/01-lifecycle-phases.md`，可以修改每个阶段的入口/退出条件。

### 修改编码规范

编辑 `.claude/rules/02-coding-standards.md`，根据团队习惯调整命名、格式等规范。

### 添加新的规则文件

在 `.claude/rules/` 目录下添加新的 `.md` 文件，会自动被 Claude Code 加载。

### 调整 Hook 拦截规则

编辑 `.claude/hooks/` 下的脚本，修改文件类型白名单或命令模式匹配。

### 添加新的斜杠命令

在 `.claude/commands/` 下添加新的 `.md` 文件即可注册新命令。

---

## 工作原理

```
Claude Code 启动
     ↓
自动加载 CLAUDE.md → 了解 SDLC 规范 + 当前项目状态
     ↓
自动加载 .claude/rules/*.md → 获取详细规范
     ↓
自动注册 .claude/settings.json 中的 Hooks
     ↓
自动注册 .claude/commands/*.md 为斜杠命令
     ↓
开始工作（受规范约束）
     │
     ├── 每次工具调用 → PreToolUse Hook 检查阶段合规性
     ├── 每次回复后 → Stop Hook 检查整体合规性
     └── Context Compaction 前 → PreCompact Hook 提醒保存状态
```

---

## 常见问题

### Hook 报错"jq: command not found"

安装 jq：`brew install jq`（macOS）或 `sudo apt-get install jq`（Ubuntu）。

### 已有 CLAUDE.md 会被覆盖吗？

不会。安装脚本会先将已有的 CLAUDE.md 备份为 `CLAUDE.md.bak.<时间戳>`。

### 已有 settings.json 会被覆盖吗？

如果安装了 jq，脚本会智能合并 hooks 配置。否则会备份原文件后覆盖。

### 可以跳过某个阶段吗？

可以。使用 `/phase next` 时如果退出条件未满足，Claude 会询问是否强制推进。强制推进时会记录跳过的条件。

### 如何卸载？

删除以下文件即可：
```bash
rm CLAUDE.md
rm -rf .claude/rules/ .claude/hooks/ .claude/commands/
# 如需要，手动从 .claude/settings.json 中移除 SDLC 相关的 hooks
```

---

## License

MIT
