---
name: review
description: "执行 P5 综合审查（唯一正式审查关卡）。检查代码质量、测试覆盖、集成一致性、PRD 追溯。用户说'审查'/'检查'/'review'时自动触发。"
argument-hint: "[filepath]"
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Edit
hooks:
  Stop:
    - hooks:
        - type: command
          command: "echo '{\"hookSpecificOutput\":{\"additionalContext\":\"审查完成前确保：(1) 报告已写入 .claude/reviews/ (2) 所有检查项已标注通过/未通过\"}}'"
---

用法：`/review [文件路径]`

参数：$ARGUMENTS

---

## 核心原则

**P5 是唯一正式审查关卡**，涵盖代码质量+测试质量+集成一致性+PRD追溯。其他阶段无需审查（P1/P2 靠用户确认，P3/P4/P6 完成即推进）。

非 P5 阶段执行 `/review` 时提示"当前阶段无需审查"。

---

## 工具辅助审查

审查 = 工具链输出（客观数据）+ LLM 审查（主观判断）。

1. 自动检测项目类型（见 06-review-tools.md）
2. 检测并安装缺失工具
3. 运行工具收集输出
4. 基于输出 + LLM 分析执行审查清单
5. 生成报告 → 写入 `.claude/reviews/P5-review-{时间}.md`

---

## 工具执行（审查前必须运行）

**所有 Bash 命令写成单行。** 工具未安装时自动安装（见 06-review-tools.md）。

### 代码工具链
1. **Lint**：`npx eslint . 2>&1; echo "LINT_EXIT=$?"` — 0 error → ✅
2. **Typecheck**：`npx tsc --noEmit 2>&1; echo "TSC_EXIT=$?"` — 0 error → ✅
3. **Build**：`npm run build 2>&1; echo "BUILD_EXIT=$?"` — 成功 → ✅
4. **依赖审计**：`npm audit 2>&1; echo "AUDIT_EXIT=$?"` — 0 high/critical → ✅

（以上为 Node.js 示例，其他语言见 06-review-tools.md 对照表）

### 测试验证
**核心规则：测试只运行一次，从输出文件分析。整个审查最多 3 次测试。**

1. **运行一次**：`npx vitest run --coverage 2>&1 | tee /tmp/sdlc-test-output.txt; echo "TEST_EXIT=${PIPESTATUS[0]}"`
2. **Read 分析**：读取 `/tmp/sdlc-test-output.txt` 提取通过数/失败数/覆盖率
3. **如有失败**：一次性收集所有错误 → 批量修复 → 再运行一次验证
4. 禁止：重复运行测试、`-t "name"` 单跑、每修一个跑一次

---

## 审查清单

### 5.1 代码质量
- [ ] **Lint + Typecheck + Build 通过** + **依赖安全**无 high/critical
- [ ] 无已废弃 API 调用 + 与 P2 设计方案一致
- [ ] 代码质量 — 按 02-coding-standards.md 检查（函数≤50行、嵌套≤3层）
- [ ] 无注入/XSS/硬编码敏感信息 + 无冗余代码

### 5.2 测试质量
- [ ] **每条 PRD 需求有对应测试** + 测试全部通过
- [ ] **覆盖率**：行 ≥80%、关键业务 ≥90%、分支 ≥70%
- [ ] 测试质量 — 命名清晰、独立、mock 合理、回归保护

### 5.3 集成一致性 + PRD 追溯
- [ ] **PRD 四环追溯** — 需求→设计→代码文件:行号→测试用例，无断链
- [ ] **无 PRD 外变更**
- [ ] 全局一致性（接口、数据模型、错误处理策略一致）
- [ ] 安全性 + 性能（无 N+1、无重复 I/O）+ 无遗漏 TODO/FIXME

### 5.4 交付就绪
- [ ] 无敏感信息 + Commit 粒度合理 + 文档按需更新

---

## 输出格式
```
╔══════════════════════════════════════╗
║       P5 综合审查报告                ║
╚══════════════════════════════════════╝

工具链：Lint {✅/❌} | Typecheck {✅/❌} | Build {✅/❌} | 依赖 {✅/⚠️}
测试：通过 {n} / 失败 {n} / 覆盖率 {n}%

5.1 代码质量：{✅ / ❌}
5.2 测试质量：{✅ / ❌}
5.3 集成+PRD：{✅ / ❌}
5.4 交付就绪：{✅ / ❌}

PRD 追溯表：
  R1 → 设计模块A → src/foo.ts:10-50 → test/foo.test.ts ✅
  R2 → 设计模块B → src/bar.ts:5-30 → test/bar.test.ts ✅

发现的问题：
  1. [严重程度] {描述} → {建议}

结论：{通过 / 需修改后通过}
```

---

## 未通过处理

- 代码问题 → 回 P3 修复
- 测试问题 → 回 P4 补充/修复
- 自动修复后重新审查（最多 3 次）
