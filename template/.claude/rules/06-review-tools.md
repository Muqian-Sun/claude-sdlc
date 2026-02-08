# 审查工具链配置

---

## 项目类型自动检测

| 检测文件 | 项目类型 | Lint | Typecheck | Test+Coverage | 依赖审计 |
|---------|---------|------|-----------|--------------|---------|
| package.json | Node.js | npx eslint . | npx tsc --noEmit | npx jest --coverage / npx vitest run --coverage | npm audit |
| pyproject.toml / requirements.txt | Python | ruff check . 或 flake8 | mypy . | pytest --cov | pip audit |
| go.mod | Go | go vet ./... | (内置) | go test -coverprofile=cover.out ./... | govulncheck ./... |
| Cargo.toml | Rust | cargo clippy | (内置) | cargo test | cargo audit |
| pom.xml / build.gradle | Java | (配置) | mvn compile / gradle compileJava | mvn test / gradle test | mvn dependency-check:check |

---

## 工具自动安装

审查工具不存在时，**自动安装为 devDependency，不跳过**：

1. `which <命令>` 或 `npx <命令> --version` 检测是否可用
2. 未安装 → 用项目对应包管理器自动安装（Node.js 用 `--save-dev`，Python 不写入 requirements.txt）
3. 安装前告知用户，安装后验证可用
4. 安装失败 → 记录警告，标注为风险项，不阻塞审查

---

## 关键指标

| 阶段 | 指标 |
|------|------|
| P2 代码审查 | Lint 错误数、Typecheck 错误数、构建是否成功、依赖漏洞数+严重等级 |
| P3 测试审查 | 通过/失败/跳过数、行覆盖 ≥80%、关键业务 ≥90%、分支 ≥70% |
