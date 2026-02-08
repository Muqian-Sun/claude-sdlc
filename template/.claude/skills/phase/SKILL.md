---
name: phase
description: "SDLC 阶段管理命令。查看当前阶段、推进到下一阶段、或回退。用户说'下一阶段'/'推进'/'查看阶段'时自动触发。"
argument-hint: "[next|back|status]"
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
---

用法：`/phase [next|back|status]`

参数：$ARGUMENTS

---

## 当前阶段

!`sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/当前阶段: \1/p' "${CLAUDE_PROJECT_DIR}"/.claude/project-state.md 2>/dev/null || echo "当前阶段: P0"`

## 执行逻辑

### 无参数 或 `status`
读取 .claude/project-state.md，输出：阶段编号+名称、允许操作、完成条件、推进方式。

### `next` — 推进到下一阶段

1. 读取当前阶段，检查完成条件
2. **P1/P2（用户确认即推进）**：
   - 用户已确认 → 直接更新 project-state.md，推进
   - P2→P3 提示"进入自动驱动模式"
3. **P3/P4/P6（完成即推进，不审查）**：
   - P3：PRD 全实现 + 代码可编译 → 直接进 P4
   - P4：测试全通过 + 覆盖率达标 → 直接进 P5
   - P6：交付完成 → 输出交付摘要报告
4. **P5（唯一正式审查）**：
   - 自动执行 `/review`（综合审查：代码+测试+集成+PRD追溯）
   - 通过 → 推进到 P6
   - 未通过 → 自动修复 → 重新审查（最多 3 次，仍失败则停下报告）

更新字段：`current_phase`、`phase_history`、`last_updated`，`review_retry_count`→0

### `back` — 回退到上一阶段
1. P0/P1 无法回退
2. 要求回退原因
3. 更新 project-state.md（`current_phase`、`phase_history` 含回退原因、`last_updated`）

---

## 自动驱动模式

P2 确认后，P3-P6 自动驱动：编码→测试→P5综合审查→交付→完成。P5 是唯一审查关卡，未通过自动修复重试（最多3次）。

用户随时可介入：`/phase` 查看进度、`/review` 手动审查、`/phase back` 回退、发消息暂停。

---

## P6 交付摘要报告格式

```
╔══════════════════════════════════════╗
║         交付摘要报告                 ║
╚══════════════════════════════════════╝

PRD 完成情况：
  R1: {需求} — 已实现、已测试 ...
  完成率：{n}/{n} (100%)

修改文件：{文件列表}
测试结果：通过 {n} / 失败 0
Git 提交：{hash} {message}
审查重试：{n} 次
```
