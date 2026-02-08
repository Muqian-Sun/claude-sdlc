# SDLC v1.8.0 质量测试计划

## 测试目标

验证 v1.8.0 优化后：
1. ✅ 核心功能完整性
2. ✅ 精简效果达标
3. ✅ 规范可执行性
4. ✅ 文件一致性
5. ✅ 恢复能力完整

---

## 测试清单

### 一、核心功能完整性测试

#### 1.1 阶段定义完整性
- [ ] P0-P5 五个阶段定义完整
- [ ] 每个阶段的允许工具列表清晰
- [ ] 阶段推进条件明确
- [ ] P4 唯一审查关卡规则保留

#### 1.2 PRD 约束完整性
- [ ] "严格按 PRD 开发"规则存在
- [ ] 禁止 PRD 外变更规则存在
- [ ] PRD 锁定机制存在
- [ ] PRD 修改需回 P1 规则存在

#### 1.3 审查清单完整性
- [ ] 代码质量检查项（Lint/Typecheck/Build/依赖安全）
- [ ] 测试质量检查项（覆盖率要求）
- [ ] PRD 追溯检查项
- [ ] 安全规范检查项

#### 1.4 工具限制完整性
- [ ] P1 禁止 Bash 规则存在
- [ ] P2 禁止测试命令规则存在
- [ ] 各阶段工具白名单完整

#### 1.5 自动驱动机制
- [ ] P1→P2 启动自动驱动规则
- [ ] P2-P5 自动推进规则
- [ ] P4 审查失败自动修复规则（最多3次）

#### 1.6 安全规则
- [ ] OWASP 安全规范存在
- [ ] Git 安全规则存在（禁止 force push 等）
- [ ] 敏感文件保护规则存在

---

### 二、精简效果验证

#### 2.1 规范文件行数统计

**目标**：总行数 < 760 行（Markdown 文件）

```bash
cd template && find . -name "*.md" -type f | xargs wc -l | tail -1
```

**预期结果**：
- v1.7.0: ~801 行
- v1.8.0: ~750 行（含新增的 09-memory-management.md 和 archive/SKILL.md）

#### 2.2 关键文件行数验证

| 文件 | 目标行数 | 实际行数 | 状态 |
|------|---------|---------|------|
| CLAUDE.md | ≤ 45 | ? | ⬜ |
| 01-lifecycle-phases.md | ≤ 105 | ? | ⬜ |
| 02-coding-standards.md | ≤ 70 | ? | ⬜ |
| 03-testing-standards.md | ≤ 55 | ? | ⬜ |
| 05-anti-amnesia.md | ≤ 25 | ? | ⬜ |
| 07-parallel-agents.md | ≤ 30 | ? | ⬜ |
| review/SKILL.md | ≤ 105 | ? | ⬜ |
| phase/SKILL.md | ≤ 65 | ? | ⬜ |
| status/SKILL.md | ≤ 40 | ? | ⬜ |

#### 2.3 生成文档格式验证

**P4 审查报告格式**：
- [ ] 使用简洁 Markdown（无 ASCII 装饰）
- [ ] 总长度 ≤ 15 行
- [ ] PRD 追溯单行展示

**P5 交付摘要格式**：
- [ ] 使用简洁 Markdown
- [ ] 总长度 ≤ 10 行
- [ ] 数据量化展示

**PRD 格式规范**：
- [ ] 使用表格展示需求
- [ ] 需求描述 ≤ 30 字
- [ ] 验收标准 1 条
- [ ] 总长度 ≤ 150 行

---

### 三、文件一致性测试

#### 3.1 跨文件引用验证

**CLAUDE.md 引用检查**：
- [ ] `@.claude/project-state.md` 引用存在
- [ ] `/phase`、`/status`、`/checkpoint`、`/review`、`/archive` 命令列出
- [ ] 引用 09-memory-management.md

**规则文件引用检查**：
- [ ] 01-lifecycle-phases.md 引用 02-coding-standards.md
- [ ] 01-lifecycle-phases.md 引用 06-review-tools.md
- [ ] review/SKILL.md 引用 06-review-tools.md
- [ ] 各文件引用 09-memory-management.md

#### 3.2 术语一致性

**关键术语检查**：
- [ ] "P4 是唯一正式审查关卡" - 出现在 CLAUDE.md, 01-lifecycle-phases.md, review/SKILL.md
- [ ] "严格按 PRD 开发" - 出现在 CLAUDE.md, 01-lifecycle-phases.md, 02-coding-standards.md
- [ ] "自动驱动" - 出现在 CLAUDE.md, 01-lifecycle-phases.md, phase/SKILL.md
- [ ] "精简格式" - 出现在 CLAUDE.md, 09-memory-management.md, project-state.md

#### 3.3 数值一致性

**长度限制检查**：
- [ ] PRD ≤ 150 行 - 出现在 CLAUDE.md, 01-lifecycle-phases.md, 09-memory-management.md
- [ ] 需求描述 ≤ 30 字 - 出现在 01-lifecycle-phases.md, 09-memory-management.md, project-state.md
- [ ] completed_tasks ≥ 5 归档 - 出现在 CLAUDE.md, 09-memory-management.md, project-state.md, archive/SKILL.md
- [ ] phase_history ≥ 10 压缩 - 出现在 09-memory-management.md, project-state.md, archive/SKILL.md

---

### 四、规范可执行性测试

#### 4.1 Hooks 配置验证

**检查 settings.json**：
- [ ] SessionStart hook 配置
- [ ] UserPromptSubmit hook 配置
- [ ] PreToolUse hook 配置（Write/Edit, Bash）
- [ ] PostToolUse hook 配置
- [ ] PreCompact hook 配置
- [ ] SubagentStart hook 配置

**检查 hooks 脚本**：
- [ ] `.claude/hooks/session-start.sh` 存在且可执行
- [ ] `.claude/hooks/user-prompt-submit.sh` 存在
- [ ] `.claude/hooks/check-phase-write.sh` 存在
- [ ] `.claude/hooks/check-phase-test.sh` 存在
- [ ] `.claude/hooks/pre-compact.sh` 存在
- [ ] `.claude/hooks/statusline.sh` 存在

#### 4.2 Skills 配置验证

**检查 skills 定义**：
- [ ] `/phase` - phase/SKILL.md 存在
- [ ] `/status` - status/SKILL.md 存在
- [ ] `/checkpoint` - checkpoint/SKILL.md 存在
- [ ] `/review` - review/SKILL.md 存在
- [ ] `/archive` - archive/SKILL.md 存在（新增）

**检查 skills 格式**：
- [ ] 每个 SKILL.md 包含 YAML front matter
- [ ] 每个 SKILL.md 包含 `name` 字段
- [ ] 每个 SKILL.md 包含 `description` 字段
- [ ] 每个 SKILL.md 包含 `allowed-tools` 或 `context` 字段

#### 4.3 Agents 配置验证

**检查 agents 定义**：
- [ ] `.claude/agents/sdlc-coder.md` 存在
- [ ] `.claude/agents/sdlc-tester.md` 存在
- [ ] `.claude/agents/sdlc-reviewer.md` 存在

---

### 五、恢复能力测试

#### 5.1 project-state.md 格式验证

**检查必需字段**：
- [ ] `current_phase` 字段存在
- [ ] `task_description` 字段存在
- [ ] `prd` 字段存在（含 id, desc, accept）
- [ ] `completed_tasks` 字段存在（含精简格式说明）
- [ ] `phase_history` 字段存在
- [ ] `key_context` 字段存在

**检查精简格式说明**：
- [ ] completed_tasks 包含格式示例
- [ ] completed_tasks 包含长度限制（≤50字）
- [ ] completed_tasks 包含自动清理说明（≥5个归档）
- [ ] key_context 包含长度限制（≤50字）

#### 5.2 Compaction 保护验证

**检查 Compact Instructions**：
- [ ] 包含保留优先级列表
- [ ] 包含删除内容列表
- [ ] 引用 09-memory-management.md
- [ ] 保留 completed_tasks 最近 3 个规则

---

### 六、记忆精简功能测试

#### 6.1 归档机制验证

**检查 archive/SKILL.md**：
- [ ] 归档触发条件（≥5个）
- [ ] 归档格式（极简）
- [ ] 归档位置（.claude/archive/tasks-{year}.md）
- [ ] 安全保护（备份机制）

**检查归档规则**：
- [ ] completed_tasks 归档格式定义
- [ ] phase_history 压缩规则
- [ ] architecture_decisions 精简规则

#### 6.2 PRD 精简格式验证

**检查 09-memory-management.md**：
- [ ] PRD 表格格式示例
- [ ] PRD 长度限制（≤150行）
- [ ] 需求描述限制（≤30字）
- [ ] 验收标准规则（1条）
- [ ] 示例对比（冗余 vs 精简）

---

## 自动化测试脚本

### 测试 1：文件完整性检查

```bash
#!/bin/bash
echo "=== 测试 1：文件完整性检查 ==="

TEMPLATE_DIR="template"
REQUIRED_FILES=(
  "$TEMPLATE_DIR/CLAUDE.md"
  "$TEMPLATE_DIR/.claude/project-state.md"
  "$TEMPLATE_DIR/.claude/settings.json"
  "$TEMPLATE_DIR/.claude/rules/01-lifecycle-phases.md"
  "$TEMPLATE_DIR/.claude/rules/02-coding-standards.md"
  "$TEMPLATE_DIR/.claude/rules/03-testing-standards.md"
  "$TEMPLATE_DIR/.claude/rules/04-git-workflow.md"
  "$TEMPLATE_DIR/.claude/rules/05-anti-amnesia.md"
  "$TEMPLATE_DIR/.claude/rules/06-review-tools.md"
  "$TEMPLATE_DIR/.claude/rules/07-parallel-agents.md"
  "$TEMPLATE_DIR/.claude/rules/08-chrome-integration.md"
  "$TEMPLATE_DIR/.claude/rules/09-memory-management.md"
  "$TEMPLATE_DIR/.claude/skills/phase/SKILL.md"
  "$TEMPLATE_DIR/.claude/skills/status/SKILL.md"
  "$TEMPLATE_DIR/.claude/skills/checkpoint/SKILL.md"
  "$TEMPLATE_DIR/.claude/skills/review/SKILL.md"
  "$TEMPLATE_DIR/.claude/skills/archive/SKILL.md"
  "$TEMPLATE_DIR/.claude/agents/sdlc-coder.md"
  "$TEMPLATE_DIR/.claude/agents/sdlc-tester.md"
  "$TEMPLATE_DIR/.claude/agents/sdlc-reviewer.md"
)

PASSED=0
FAILED=0

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file"
    PASSED=$((PASSED + 1))
  else
    echo "❌ $file - 文件不存在"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "通过: $PASSED | 失败: $FAILED"
[ $FAILED -eq 0 ] && echo "✅ 文件完整性测试通过" || echo "❌ 文件完整性测试失败"
```

### 测试 2：行数统计

```bash
#!/bin/bash
echo "=== 测试 2：行数统计 ==="

cd template

echo "核心文件行数："
wc -l CLAUDE.md
wc -l .claude/rules/01-lifecycle-phases.md
wc -l .claude/rules/02-coding-standards.md
wc -l .claude/rules/03-testing-standards.md
wc -l .claude/rules/05-anti-amnesia.md
wc -l .claude/rules/07-parallel-agents.md
wc -l .claude/skills/review/SKILL.md
wc -l .claude/skills/phase/SKILL.md
wc -l .claude/skills/status/SKILL.md

echo ""
echo "总行数（所有 Markdown 文件）："
find . -name "*.md" -type f | xargs wc -l | tail -1
```

### 测试 3：关键术语检查

```bash
#!/bin/bash
echo "=== 测试 3：关键术语一致性检查 ==="

cd template

echo "检查 'P4 是唯一正式审查关卡'："
grep -r "P4 是唯一正式审查关卡" --include="*.md" . | wc -l

echo "检查 '严格按 PRD 开发'："
grep -r "严格按 PRD" --include="*.md" . | wc -l

echo "检查 '自动驱动'："
grep -r "自动驱动" --include="*.md" . | wc -l

echo "检查 'PRD ≤ 150'："
grep -r "≤ 150" --include="*.md" . | wc -l

echo "检查 'completed_tasks ≥ 5'："
grep -r "≥ 5" --include="*.md" . | wc -l
```

### 测试 4：引用完整性检查

```bash
#!/bin/bash
echo "=== 测试 4：引用完整性检查 ==="

cd template

echo "检查 CLAUDE.md 引用："
grep "@.claude/project-state.md" CLAUDE.md && echo "✅ project-state.md 引用存在"
grep "09-memory-management" CLAUDE.md && echo "✅ 09-memory-management 引用存在"
grep "/archive" CLAUDE.md && echo "✅ /archive 命令列出"

echo ""
echo "检查跨文件引用："
grep "02-coding-standards" .claude/rules/01-lifecycle-phases.md && echo "✅ 01→02 引用存在"
grep "06-review-tools" .claude/rules/01-lifecycle-phases.md && echo "✅ 01→06 引用存在"
grep "09-memory-management" .claude/rules/01-lifecycle-phases.md && echo "✅ 01→09 引用存在"
```

### 测试 5：Hooks 脚本检查

```bash
#!/bin/bash
echo "=== 测试 5：Hooks 脚本检查 ==="

cd template/.claude/hooks

HOOKS=(
  "session-start.sh"
  "user-prompt-submit.sh"
  "check-phase-write.sh"
  "check-phase-test.sh"
  "pre-compact.sh"
  "statusline.sh"
)

for hook in "${HOOKS[@]}"; do
  if [ -f "$hook" ]; then
    if [ -x "$hook" ]; then
      echo "✅ $hook - 存在且可执行"
    else
      echo "⚠️ $hook - 存在但不可执行"
    fi
  else
    echo "❌ $hook - 不存在"
  fi
done
```

---

## 手动测试场景

### 场景 1：完整流程测试（P1→P5）

**目标**：验证精简后的规范可以支持完整的开发流程

**步骤**：
1. 创建测试项目
2. 安装 claude-sdlc
3. 提出开发需求（进入 P1）
4. 生成 PRD，验证格式是否符合精简要求
5. 推进到 P2-P5，验证自动驱动
6. 检查生成的审查报告和交付摘要是否精简

**验收标准**：
- [ ] PRD 总长度 ≤ 150 行
- [ ] 审查报告 ≤ 15 行
- [ ] 交付摘要 ≤ 10 行
- [ ] completed_tasks 使用精简格式
- [ ] 所有阶段正常推进

### 场景 2：归档功能测试

**目标**：验证自动归档机制

**步骤**：
1. 模拟完成 5 个任务
2. 触发 `/archive` 命令
3. 验证归档文件生成
4. 验证 completed_tasks 保留最近 3 个

**验收标准**：
- [ ] `.claude/archive/tasks-{year}.md` 生成
- [ ] completed_tasks 从 5 个减少到 3 个
- [ ] 归档格式符合极简要求
- [ ] 生成节省空间报告

### 场景 3：Compaction 恢复测试

**目标**：验证压缩后的恢复能力

**步骤**：
1. 模拟 context compaction
2. 验证保留的信息
3. 验证删除的信息
4. 模拟恢复，检查工作是否能继续

**验收标准**：
- [ ] key_context ≤ 50 字
- [ ] completed_tasks 保留最近 3 个
- [ ] phase_history 保留最近 5 条
- [ ] 当前任务状态完整
- [ ] 恢复后可以继续工作

---

## 质量评分标准

### 完整性得分（40分）
- 核心功能保留（10分）
- 审查清单完整（10分）
- 工具限制完整（10分）
- 安全规则完整（10分）

### 精简效果得分（30分）
- 规范文件精简达标（10分）
- 生成文档精简达标（10分）
- 记忆存储精简达标（10分）

### 一致性得分（20分）
- 跨文件引用正确（10分）
- 术语使用一致（10分）

### 可执行性得分（10分）
- Hooks 配置正确（5分）
- Skills 配置正确（5分）

**总分**：100 分
**及格线**：80 分

---

## 测试执行记录

**测试日期**：待执行
**测试人员**：待定
**测试环境**：待定

| 测试项 | 结果 | 得分 | 备注 |
|--------|------|------|------|
| 文件完整性 | ⬜ | - / 10 | |
| 行数统计 | ⬜ | - / 10 | |
| 术语一致性 | ⬜ | - / 10 | |
| 引用完整性 | ⬜ | - / 10 | |
| Hooks 配置 | ⬜ | - / 10 | |
| Skills 配置 | ⬜ | - / 10 | |
| 完整流程 | ⬜ | - / 20 | |
| 归档功能 | ⬜ | - / 10 | |
| Compaction | ⬜ | - / 10 | |
| **总分** | - | **- / 100** | |

---

## 问题记录

| 序号 | 问题描述 | 严重程度 | 状态 | 解决方案 |
|------|---------|---------|------|---------|
| 1 | - | - | - | - |

---

## 结论

**待测试后填写**

- [ ] ✅ 质量测试通过（≥80分）
- [ ] ⚠️ 质量测试部分通过（60-79分）
- [ ] ❌ 质量测试未通过（<60分）

**建议**：
- 待测试后填写
