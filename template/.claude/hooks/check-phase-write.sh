#!/usr/bin/env bash
# check-phase-write.sh — PreToolUse hook for Write/Edit
# P3 前拦截代码文件写入，文档/配置文件任何阶段放行
set -euo pipefail

INPUT=$(cat)

# 提取文件路径
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi

[ -z "$FILE_PATH" ] && exit 0

# 文档/配置文件扩展名 — bash case 零子进程
EXT="${FILE_PATH##*.}"
case "${EXT,,}" in
  md|txt|json|yaml|yml|toml|ini|cfg|conf|gitignore|editorconfig|prettierrc|eslintrc|csv|xml|svg|lock|log)
    exit 0 ;;
esac
# .env 及 .env.* 文件也放行（由 permissions deny 控制）
case "$FILE_PATH" in
  *.env|*.env.*) exit 0 ;;
esac

# 读取阶段 — 单次 awk
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
if [ -f "$STATE_FILE" ]; then
  PHASE_NUM=$(awk '/^current_phase:/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)
fi
PHASE_NUM="${PHASE_NUM:-${SDLC_PHASE:+$(echo "$SDLC_PHASE" | sed 's/[^0-9]//g')}}"
[ -z "$PHASE_NUM" ] && exit 0

# P3+ 放行
[ "$PHASE_NUM" -ge 3 ] && exit 0

# 拦截 — JSON permissionDecision 格式
REASON="当前阶段 P${PHASE_NUM} 不允许修改代码文件（P3 起可用）"
if command -v jq &>/dev/null; then
  jq -n --arg r "$REASON" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$r}}'
else
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$REASON"
fi
exit 0
