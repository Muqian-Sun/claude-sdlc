#!/bin/bash
# UserPromptSubmit — 注入当前 SDLC 阶段上下文
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(awk '/^current_phase:/{gsub(/[^A-Za-z0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)

if [ -z "$PHASE" ] || [ "$PHASE" = "P0" ]; then
  exit 0
fi

# 注入阶段提醒（非阻塞，仅注入上下文）
CONTEXT="[SDLC 当前阶段: ${PHASE}] 请遵守 ${PHASE} 阶段的工具限制和规范要求。操作前先确认 .claude/project-state.md 状态是否最新。"

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}' "$CONTEXT"
