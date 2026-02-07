#!/bin/bash
# PostToolUseFailure — 工具失败时记录和恢复建议
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
INPUT=$(cat)

PHASE="P0"
if [ -f "$STATE_FILE" ]; then
  PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
fi
PHASE="${PHASE:-P0}"

TOOL_NAME=""
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi

CONTEXT="[SDLC 工具失败] 阶段=${PHASE}，工具=${TOOL_NAME}。建议：(1) 检查命令/路径是否正确 (2) 确认当前阶段允许此操作 (3) 如为权限问题检查 permissions 配置 (4) 更新 project-state.md 记录异常。"

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure","additionalContext":"%s"}}' "$CONTEXT"
