#!/bin/bash
# SubagentStart — 子 Agent 启动时注入 SDLC 上下文
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
[ ! -f "$STATE_FILE" ] && exit 0

# 单次 awk 提取所有字段
eval "$(awk '
  /^current_phase:/ { phase=$2 }
  /^task_description:/ { sub(/^task_description:[[:space:]]*"?/,""); sub(/"$/,""); task=$0 }
  /^prd:/,/^[a-z]/ {
    if(/^\s*-\s*id:/) { sub(/.*id:[[:space:]]*/,""); id=$0 }
    if(/^\s*description:/) { sub(/.*description:[[:space:]]*"?/,""); sub(/"$/,""); prd=prd id": "$0"; " }
  }
  END {
    gsub(/["\\]/,"",task)
    gsub(/["\\]/,"",prd)
    printf "PHASE=%s\nTASK=%s\nPRD_SUMMARY=%s\n", phase, task, prd
  }
' "$STATE_FILE" 2>/dev/null)"

[ -z "$PHASE" ] || [ "$PHASE" = "P0" ] && exit 0

# 阶段工具限制
case "$PHASE" in
  P3) TOOLS_NOTE="P3 编码阶段：可用 Read/Glob/Grep/Write/Edit/Bash（非测试非 git），严格按 PRD 编码" ;;
  P4) TOOLS_NOTE="P4 测试阶段：可用 Read/Glob/Grep/Write/Edit/Bash（含测试），每条 PRD 需求至少一个测试" ;;
  P5) TOOLS_NOTE="P5 审查阶段：可用 Read/Glob/Grep，Write/Edit 仅修复审查问题" ;;
  *)  TOOLS_NOTE="当前阶段 ${PHASE}，请遵守该阶段工具限制" ;;
esac

CONTEXT="[SDLC 子 Agent 上下文] 阶段=${PHASE}，任务=${TASK}。${TOOLS_NOTE}。PRD 摘要：${PRD_SUMMARY}。编码规范：函数≤50行、嵌套≤3层、命名遵循语言约定。完成后报告修改的文件列表。"

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"%s"}}' "$CONTEXT"
