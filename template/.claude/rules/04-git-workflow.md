# Git 工作流规范

本规范适用于 P6（部署交付）阶段的 Git 操作，以及所有阶段的版本控制行为。

---

## 1. 分支策略

### 分支命名
```
feature/<简短描述>    # 新功能
fix/<简短描述>        # Bug 修复
refactor/<简短描述>   # 重构
docs/<简短描述>       # 文档更新
test/<简短描述>       # 测试补充
```

### 规则
- 从最新的 main/master 创建分支
- 分支名使用小写字母和连字符
- 分支名应简洁明了：`feature/user-auth`, `fix/login-crash`

---

## 2. Conventional Commits 格式

### 提交信息格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型
| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(auth): add JWT token refresh` |
| `fix` | Bug 修复 | `fix(login): resolve crash on empty password` |
| `refactor` | 重构（不改变功能） | `refactor(utils): simplify date formatting` |
| `test` | 测试相关 | `test(user): add edge case tests` |
| `docs` | 文档更新 | `docs(readme): update installation guide` |
| `style` | 格式调整 | `style: fix indentation in config` |
| `chore` | 构建/工具变更 | `chore: update dependencies` |
| `perf` | 性能优化 | `perf(query): optimize database lookup` |

### Subject 规则
- 使用祈使语气（"add" 而非 "added"）
- 首字母小写
- 不加句号结尾
- 不超过 72 字符

### Body 规则（可选）
- 与 subject 之间空一行
- 解释"为什么"做这个改动，而非"做了什么"
- 每行不超过 72 字符

### Footer 规则（可选）
- 关联 issue：`Closes #123`
- 破坏性变更：`BREAKING CHANGE: <描述>`

---

## 3. 提交粒度

### 原则
- **原子性**：每个 commit 只包含一个逻辑变更
- **可编译**：每个 commit 后项目应能正常构建
- **可回退**：每个 commit 都可以安全地 revert

### 拆分建议
- 功能代码和测试代码可以在同一个 commit
- 重构和功能变更必须分开 commit
- 配置变更和代码变更分开 commit
- 不要把不相关的改动放在一个 commit

---

## 4. PR (Pull Request) 规范

### PR 标题
- 遵循 Conventional Commits 格式
- 简明描述本 PR 的核心变更

### PR 描述模板
```markdown
## Summary
- 简要描述变更内容（1-3 条）

## Changes
- 具体修改了什么

## Test Plan
- 如何验证这些变更

## Related Issues
- Closes #xxx
```

### PR 规则
- PR 应尽可能小（建议 < 400 行变更）
- 每个 PR 只解决一个问题或实现一个功能
- PR 提交前确保 CI 通过

---

## 5. Git 操作安全规则

### 禁止操作（除非用户明确要求）
- ❌ `git push --force` (到 main/master)
- ❌ `git reset --hard`
- ❌ `git clean -f`
- ❌ `git branch -D`（大写 D 强制删除）

### 谨慎操作（需向用户确认）
- ⚠️ `git push`（首次推送到远程）
- ⚠️ `git merge`（合并到 main/master）
- ⚠️ `git rebase`（变基操作）

### 安全操作（可自由执行）
- ✅ `git status`
- ✅ `git diff`
- ✅ `git log`
- ✅ `git branch`（查看分支）
- ✅ `git stash`（暂存变更）

---

## 6. 冲突解决

- 优先使用 `git merge`，保留完整历史
- 合并冲突时：逐文件解决，保留双方有效改动，不丢弃他人工作
- 解决后运行测试验证无回归
- 复杂冲突向用户确认后再提交
