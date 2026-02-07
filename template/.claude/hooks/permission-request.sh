#!/usr/bin/env bash
# PermissionRequest — 根据 SDLC 阶段自动决策权限
set -euo pipefail

INPUT=$(cat)
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

# 获取当前阶段
PHASE="P0"
if [ -f "$STATE_FILE" ]; then
  PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
fi
PHASE="${PHASE:-${SDLC_PHASE:-P0}}"
PHASE_NUM=$(echo "$PHASE" | sed 's/[^0-9]//g')
PHASE_NUM="${PHASE_NUM:-0}"

# 提取工具信息
TOOL_NAME=""
TOOL_ACTION=""
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
  TOOL_ACTION=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // ""' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi

# 默认：交给用户决定
BEHAVIOR="allow"
MESSAGE=""

# 文档类文件扩展名
DOC_EXT='\.(md|txt|json|yaml|yml|toml|ini|cfg|conf|csv|xml|svg|log)$'

case "$TOOL_NAME" in
  Write|Edit)
    if echo "$TOOL_ACTION" | grep -qiE "$DOC_EXT"; then
      BEHAVIOR="allow"
    elif [ "$PHASE_NUM" -ge 3 ]; then
      BEHAVIOR="allow"
    else
      BEHAVIOR="deny"
      MESSAGE="阶段 ${PHASE} 不允许修改代码文件（P3 起可用）"
    fi
    ;;
  Bash)
    if echo "$TOOL_ACTION" | grep -qiE '^git[[:space:]]+(status|diff|log|branch|stash)'; then
      BEHAVIOR="allow"
    elif echo "$TOOL_ACTION" | grep -qiE '(rm -rf|--force|reset --hard)'; then
      # 危险命令始终交给用户
      exit 0
    elif echo "$TOOL_ACTION" | grep -qiE '^git[[:space:]]+(commit|push|tag|merge)'; then
      [ "$PHASE_NUM" -ge 6 ] && BEHAVIOR="allow" || { BEHAVIOR="deny"; MESSAGE="Git 提交操作仅 P6 允许"; }
    elif echo "$TOOL_ACTION" | grep -qiE '(npm test|npx jest|npx vitest|pytest|go test|cargo test)'; then
      [ "$PHASE_NUM" -ge 4 ] && BEHAVIOR="allow" || { BEHAVIOR="deny"; MESSAGE="测试命令仅 P4 起允许"; }
    elif echo "$TOOL_ACTION" | grep -qiE '^(npx eslint|npx tsc|npm run lint|npm run build)'; then
      [ "$PHASE_NUM" -ge 3 ] && BEHAVIOR="allow" || BEHAVIOR="allow"
    else
      [ "$PHASE_NUM" -ge 3 ] && BEHAVIOR="allow"
    fi
    ;;
  Chrome)
    if [ "$PHASE_NUM" -eq 2 ] || [ "$PHASE_NUM" -eq 4 ]; then
      BEHAVIOR="allow"
    else
      BEHAVIOR="deny"
      MESSAGE="Chrome 仅在 P2（UI 调研）和 P4（视觉测试）阶段允许"
    fi
    ;;
  Read|Glob|Grep|WebSearch|WebFetch)
    BEHAVIOR="allow"
    ;;
  *)
    # 未知工具：不干预，让用户决定
    exit 0
    ;;
esac

# 输出决策 JSON
if [ "$BEHAVIOR" = "deny" ] && [ -n "$MESSAGE" ]; then
  printf '{"hookSpecificOutput":{"decision":{"behavior":"deny","message":"%s"}}}' "$MESSAGE"
elif [ "$BEHAVIOR" = "allow" ]; then
  printf '{"hookSpecificOutput":{"decision":{"behavior":"allow"}}}'
fi
