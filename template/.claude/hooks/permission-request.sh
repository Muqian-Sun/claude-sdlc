#!/usr/bin/env bash
# PermissionRequest — 根据 SDLC 阶段自动决策权限
set -euo pipefail

INPUT=$(cat)
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

# 获取阶段 — 单次 awk
PHASE_NUM=0
if [ -f "$STATE_FILE" ]; then
  PHASE_NUM=$(awk '/^current_phase:/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)
fi
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

BEHAVIOR="allow"
MESSAGE=""

case "$TOOL_NAME" in
  Write|Edit)
    # 文档扩展名 — 兼容 bash 3.2（macOS 默认）
    EXT=$(printf '%s' "${TOOL_ACTION##*.}" | tr 'A-Z' 'a-z')
    case "$EXT" in
      md|txt|json|yaml|yml|toml|ini|cfg|conf|csv|xml|svg|log)
        BEHAVIOR="allow" ;;
      *)
        if [ "$PHASE_NUM" -ge 3 ]; then
          BEHAVIOR="allow"
        else
          BEHAVIOR="deny"
          MESSAGE="阶段 P${PHASE_NUM} 不允许修改代码文件（P3 起可用）"
        fi ;;
    esac
    ;;
  Bash)
    if echo "$TOOL_ACTION" | grep -qiE '^git[[:space:]]+(status|diff|log|branch|stash)'; then
      BEHAVIOR="allow"
    elif echo "$TOOL_ACTION" | grep -qiE '(rm -rf|--force|reset --hard)'; then
      exit 0  # 危险命令交给用户
    elif echo "$TOOL_ACTION" | grep -qiE '^git[[:space:]]+(commit|push|tag|merge)'; then
      [ "$PHASE_NUM" -ge 6 ] && BEHAVIOR="allow" || { BEHAVIOR="deny"; MESSAGE="Git 提交操作仅 P6 允许"; }
    elif echo "$TOOL_ACTION" | grep -qiE '(npm test|npx jest|npx vitest|pytest|go test|cargo test)'; then
      [ "$PHASE_NUM" -ge 4 ] && BEHAVIOR="allow" || { BEHAVIOR="deny"; MESSAGE="测试命令仅 P4 起允许"; }
    elif echo "$TOOL_ACTION" | grep -qiE '^(npx eslint|npx tsc|npm run lint|npm run build)'; then
      BEHAVIOR="allow"
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
    exit 0  # 未知工具不干预
    ;;
esac

if [ "$BEHAVIOR" = "deny" ] && [ -n "$MESSAGE" ]; then
  printf '{"hookSpecificOutput":{"decision":{"behavior":"deny","message":"%s"}}}' "$MESSAGE"
elif [ "$BEHAVIOR" = "allow" ]; then
  printf '{"hookSpecificOutput":{"decision":{"behavior":"allow"}}}'
fi
