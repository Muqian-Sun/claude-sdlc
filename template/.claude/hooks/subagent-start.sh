#!/bin/bash
# SubagentStart — 子 Agent 启动时注入 SDLC 上下文
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(sed -n 's/^task_description:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
# JSON 安全转义（防止任务描述中的引号破坏 JSON）
TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g')

if [ -z "$PHASE" ] || [ "$PHASE" = "P0" ]; then
  exit 0
fi

# 提取 PRD 摘要（前 5 条需求的 id 和 description）
PRD_SUMMARY=$(sed -n '/^prd:/,/^[a-z]/p' "$STATE_FILE" 2>/dev/null | grep -E '^\s*-\s*id:|^\s*description:' | head -10 | tr '\n' ' ' | sed 's/"/\\"/g')

# 阶段对应的工具限制
case "$PHASE" in
  P3) TOOLS_NOTE="P3 编码阶段：可用 Read/Glob/Grep/Write/Edit/Bash（非测试非 git），严格按 PRD 编码，不添加 PRD 外功能" ;;
  P4) TOOLS_NOTE="P4 测试阶段：可用 Read/Glob/Grep/Write/Edit/Bash（含测试），每条 PRD 需求至少一个测试用例" ;;
  P5) TOOLS_NOTE="P5 审查阶段：可用 Read/Glob/Grep，Write/Edit 仅修复审查问题" ;;
  *)  TOOLS_NOTE="当前阶段 ${PHASE}，请遵守该阶段工具限制" ;;
esac

CONTEXT="[SDLC 子 Agent 上下文] 阶段=${PHASE}，任务=${TASK}。${TOOLS_NOTE}。PRD 摘要：${PRD_SUMMARY}。编码规范：函数≤50行、嵌套≤3层、命名遵循语言约定。完成后报告修改的文件列表。"

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}' "$CONTEXT"
