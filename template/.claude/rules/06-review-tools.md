# 审查工具链配置

本规则定义 `/review` 命令使用的工具链检测、自动安装和执行规范。

---

## 项目类型自动检测

审查开始时自动检测项目类型（检测项目根目录文件）：

| 检测文件 | 项目类型 | Lint | Typecheck | Test+Coverage | 依赖审计 |
|---------|---------|------|-----------|--------------|---------|
| package.json | Node.js | npx eslint . | npx tsc --noEmit | npx jest --coverage / npx vitest run --coverage | npm audit |
| pyproject.toml / requirements.txt | Python | ruff check . 或 flake8 | mypy . | pytest --cov | pip audit |
| go.mod | Go | go vet ./... | (内置) | go test -coverprofile=cover.out ./... | govulncheck ./... |
| Cargo.toml | Rust | cargo clippy | (内置) | cargo test | cargo audit |
| pom.xml | Java/Maven | (配置) | mvn compile | mvn test | mvn dependency-check:check |
| build.gradle | Java/Gradle | (配置) | gradle compileJava | gradle test | (插件) |

---

## 工具自动安装（核心机制）

审查工具不存在时，**自动安装而非跳过**。流程：

1. **检测工具是否可用**：用 `which <命令>` 或 `npx <命令> --version` 等方式检测
2. **未安装 → 自动安装**：按项目类型使用对应包管理器安装为 devDependency
3. **安装失败 → 记录警告**：不阻塞审查，但在报告中标注"⚠️ 自动安装失败"

### 各项目类型自动安装命令

| 项目类型 | 工具 | 安装命令 |
|---------|------|---------|
| Node.js | eslint | `npm install --save-dev eslint` |
| Node.js | typescript | `npm install --save-dev typescript` |
| Node.js | jest/vitest (coverage) | 检测已有测试框架，安装对应 coverage 插件 |
| Python | ruff | `pip install ruff` |
| Python | mypy | `pip install mypy` |
| Python | pytest + coverage | `pip install pytest pytest-cov` |
| Python | pip-audit | `pip install pip-audit` |
| Go | govulncheck | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| Rust | cargo-audit | `cargo install cargo-audit` |

### 安装规则

1. **仅安装为开发依赖** — Node.js 用 `--save-dev`，Python 不写入 requirements.txt（除非用户要求）
2. **安装前向用户报告** — 输出 "正在安装审查工具：eslint..."，让用户知情
3. **安装后验证** — 安装完成后再次检测，确认可用
4. **安装失败不阻塞** — 记录为风险项，继续审查其他项目

---

## 工具执行规则

1. 工具未安装 → **自动安装**（安装仍失败 → 记录警告，标注为风险项，不阻塞审查）
2. 工具执行报错 → 报错信息纳入审查报告
3. 工具执行成功 → 解析输出，提取关键指标
4. 所有工具输出原文保留在审查报告中

### Bash 命令格式要求（重要）

**所有 Bash 命令必须写成单行**，禁止在命令中间换行。zsh 会将换行后的内容当作独立命令执行，导致 `command not found` 错误。

正确示例：
```bash
npx eslint src/ 2>&1; echo "EXIT=$?"
npx tsc --noEmit 2>&1; echo "EXIT=$?"
npx jest --coverage 2>&1; echo "EXIT=$?"
npm audit 2>&1; echo "EXIT=$?"
```

错误示例（禁止）：
```bash
npx eslint src/
  2>&1; echo "EXIT=$?"    # ← zsh 会把 2 当命令执行！
```

---

## 关键指标

P3 代码审查：
- Lint 错误/警告数量
- Typecheck 错误数量
- 构建是否成功
- 依赖漏洞数量和严重等级

P4 测试审查：
- 测试通过/失败/跳过数量
- 代码覆盖率百分比（行覆盖、分支覆盖）
- 覆盖率是否达标（行 ≥80%，关键业务逻辑 ≥90%，分支 ≥70%）

---

## 审查报告持久化

每次 /review 完成后，完整报告写入：

```
.claude/reviews/P{阶段}-review-{YYYYMMDD-HHmmss}.md
```

报告包含：阶段、时间、工具输出原文、LLM 审查结论、通过/未通过。
