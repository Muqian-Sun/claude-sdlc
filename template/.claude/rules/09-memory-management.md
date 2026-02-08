# 记忆与文档精简管理

## 核心原则

**最小必要原则**：只保存恢复工作所需的最小信息集，删除冗余、装饰性、可推导的内容。

---

## 1. project-state.md 精简规则

### completed_tasks 归档格式（精简版）

```yaml
completed_tasks:
  - task: "一句话任务描述"              # ✅ 必须：简短描述（≤20字）
    prd_summary: "R1:核心需求1 R2:核心需求2"  # ✅ 必须：需求ID+一句话（不超过50字）
    key_decisions: ["关键技术栈", "重要架构决策"]  # ⚠️ 可选：仅影响全局的决策（≤3条）
    files_count: 5                      # ✅ 必须：修改文件数（不列举文件名）
    completed_at: "2025-01-15"         # ✅ 必须：完成日期（YYYY-MM-DD）
```

**禁止保存**：
- ❌ 完整 PRD 内容（prd_summary 已足够）
- ❌ 所有文件列表（files_count 已足够）
- ❌ 详细的验收标准、范围排除项
- ❌ 代码片段、测试输出

**自动清理**：
- completed_tasks 超过 **5 个**时，自动归档最旧的 2 个到 `.claude/archive/tasks-{year}.md`
- 归档文件仅保留 task + completed_at，删除其他字段

### prd 字段格式（精简版）

```yaml
prd:
  - id: R1
    desc: "一句话需求描述（≤30字）"     # ✅ 必须：核心需求
    accept: "可验证的标准"              # ✅ 必须：验收标准（1条，可测试）
    # 删除：范围排除项（仅在有歧义时口头说明，不写入）
```

**架构方案单独记录**（不在 prd 中）：
```yaml
architecture_decisions:
  - "技术栈: React 18 + TypeScript"    # 技术选型
  - "数据流: Redux Toolkit"            # 核心架构模式
  # 不记录：详细的模块划分、接口定义（在代码中体现）
```

### phase_history 精简

**只记录阶段转换**，删除中间细节：
```yaml
phase_history:
  - "P1→P2 2025-01-15 10:30"  # ✅ 保留：阶段转换+时间
  - "P4→P2 lint错误"          # ✅ 保留：回退+原因
  # 删除：每次小修改、每次保存、中间状态
```

**压缩规则**：超过 10 条时，合并连续的同阶段记录。

### key_context 精简（compaction 恢复用）

**最多 50 字**，只记录：
- 当前正在做什么（一句话）
- 遇到的关键问题（如有）

```yaml
key_context: "正在实现R2用户登录，Redux集成完成，待补充测试"  # ✅ 50字内
```

❌ 不记录：已完成的工作、详细技术细节、代码片段

---

## 2. PRD 生成格式（精简版）

### P1 阶段输出的 PRD

**格式**：
```markdown
# PRD - {任务名称}

## 需求（核心功能）
| ID | 需求 | 验收标准 |
|----|------|----------|
| R1 | 用户登录 | 输入正确凭证后跳转首页，错误时显示提示 |
| R2 | 数据展示 | 加载后显示列表，支持分页（10条/页） |

## 架构
- **技术栈**: React 18 + TS + Redux Toolkit
- **核心模块**: Auth / Dashboard / API Client

## 原型
见 `/tmp/prototype-{timestamp}.html`（P1 阶段已展示）
```

**禁止添加**：
- ❌ 长篇背景说明（用户已知）
- ❌ 范围排除项（默认只实现列出的需求）
- ❌ 详细的数据模型/接口定义（在架构决策中简述）
- ❌ 实现细节/代码示例

**长度限制**：PRD 总长度 ≤ **150 行**（含表格），超过说明粒度过细。

---

## 3. 审查报告精简（已在 v1.8.0 实现）

见 `review/SKILL.md` 的简洁版格式（~10 行）。

---

## 4. 交付摘要精简（已在 v1.8.0 实现）

见 `phase/SKILL.md` 的简洁版格式（~5 行）。

---

## 5. 状态报告精简（已在 v1.8.0 实现）

见 `status/SKILL.md` 的简洁版格式（~8 行）。

---

## 6. Compaction 保护精简

**压缩时必须保留**（优先级排序）：
1. ✅ current_phase + task_description
2. ✅ prd（精简格式）
3. ✅ modified_files（仅文件路径，不含内容）
4. ✅ key_context（≤50字）
5. ✅ project_roadmap（如有）
6. ⚠️ completed_tasks（最近 3 个，精简格式）
7. ⚠️ global_architecture（关键决策，≤5条）

**压缩时删除**：
- ❌ phase_history 详细记录（保留最近 5 条）
- ❌ todo_items（可从 prd 重建）
- ❌ architecture_decisions 详细内容（保留摘要）
- ❌ 超过 3 个的 completed_tasks（归档）

---

## 7. 自动归档机制

### 触发条件
- completed_tasks ≥ 5 个 → 归档最旧 2 个
- phase_history ≥ 10 条 → 合并重复阶段
- 手动触发：`/archive`（清理所有可归档内容）

### 归档位置
`.claude/archive/tasks-{year}.md`（只读，不加载到上下文）

### 归档内容（极简）
```markdown
# {year} 已完成任务归档

- 2025-01-15: 用户登录功能 (3文件)
- 2025-01-20: 数据展示优化 (5文件)
```

---

## 8. 文档生成通用规则

### 所有生成的文档必须遵守：

| 规则 | 说明 |
|------|------|
| **一句话原则** | 能用一句话说清楚的不用两句 |
| **表格优先** | 结构化信息用表格，不用段落 |
| **无装饰** | 不用 ASCII 边框、不用 emoji（除非必要）|
| **无重复** | 相同信息只在一处出现 |
| **可量化** | 优先用数字（5个文件）而非描述（修改了多个文件）|

### 长度限制

| 文档类型 | 最大行数 |
|---------|---------|
| PRD | 150 |
| 架构设计 | 50 |
| 审查报告 | 15 |
| 交付摘要 | 10 |
| 状态报告 | 10 |
| 单次 compaction 保留 | 200 |

超过限制 → 自动触发精简/归档。

---

## 9. 执行检查

### P1 阶段（PRD 生成）
- [ ] PRD ≤ 150 行
- [ ] 每条需求 ≤ 30 字
- [ ] 架构决策 ≤ 5 条
- [ ] 无范围排除项（或 ≤ 3 条且必要）

### P5 阶段（任务归档）
- [ ] prd_summary ≤ 50 字
- [ ] key_decisions ≤ 3 条
- [ ] 记录 files_count，不列举文件名
- [ ] completed_tasks ≥ 5 时触发归档

### Compaction 前（压缩保护）
- [ ] key_context ≤ 50 字
- [ ] completed_tasks ≤ 3 个（最近的）
- [ ] phase_history ≤ 5 条（最近的）
- [ ] 总保留内容 ≤ 200 行

---

## 10. 示例对比

### ❌ 冗余版本（180行）

```yaml
prd:
  - id: R1
    description: "实现用户登录功能，用户可以通过用户名和密码登录系统。登录成功后跳转到首页，登录失败时显示错误提示。需要支持记住密码功能。需要防止暴力破解。需要支持多种登录方式（用户名/邮箱/手机号）。"
    acceptance_criteria:
      - "用户输入正确的用户名和密码后，点击登录按钮，系统验证通过后跳转到首页"
      - "用户输入错误的用户名或密码，系统显示错误提示：'用户名或密码错误'"
      - "用户勾选'记住密码'选项后，下次打开页面自动填充用户名和密码"
      - "连续输入错误密码5次后，账号锁定10分钟"
      - "支持通过用户名、邮箱或手机号登录"
    scope_exclusion:
      - "不包含注册功能"
      - "不包含忘记密码功能"
      - "不包含第三方登录"
    technical_details:
      - "使用 JWT 做身份验证"
      - "密码使用 bcrypt 加密"
      - "使用 Redux 管理登录状态"

completed_tasks:
  - task: "实现了用户登录功能，包括前端表单、后端验证、状态管理等完整流程"
    prd_summary: "R1: 实现用户登录功能，用户可以通过用户名和密码登录系统。登录成功后跳转到首页，登录失败时显示错误提示。R2: 实现数据展示功能，用户登录后可以看到数据列表，支持分页和搜索。"
    key_decisions:
      - "选择使用 React 18 作为前端框架，因为它有更好的性能和更简洁的代码"
      - "选择使用 Redux Toolkit 作为状态管理方案，因为它减少了样板代码"
      - "选择使用 TypeScript，提供类型安全"
      - "选择使用 Ant Design 5 作为 UI 组件库"
      - "后端使用 Express + JWT 做身份验证"
      - "数据库使用 PostgreSQL"
    files:
      - "src/components/Login.tsx"
      - "src/store/authSlice.ts"
      - "src/api/auth.ts"
      - "src/types/user.ts"
      - "test/Login.test.tsx"
    completed_at: "2025-01-15T10:30:00Z"
```

### ✅ 精简版本（30行）

```yaml
prd:
  - id: R1
    desc: "用户登录（用户名/密码）"
    accept: "正确凭证→首页，错误→提示"
  - id: R2
    desc: "数据列表展示+分页"
    accept: "加载后显示，10条/页"

architecture_decisions:
  - "技术栈: React 18 + TS + Redux Toolkit + Ant Design 5"
  - "认证: JWT + bcrypt"

completed_tasks:
  - task: "用户登录功能"
    prd_summary: "R1:用户登录 R2:数据展示"
    key_decisions: ["React18+TS+Redux", "JWT认证"]
    files_count: 5
    completed_at: "2025-01-15"
```

**节省**：180 → 30 行（**-83%**）

---

## 验证

生成任何文档后，自检：
1. 能删掉的描述都删了吗？
2. 能用表格的用表格了吗？
3. 能用一句话的用两句了吗？
4. 有重复信息吗？
5. 超过长度限制了吗？
