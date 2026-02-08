#!/usr/bin/env bash
# PermissionRequest — 根据 SDLC 阶段自动决策权限
# 性能：bash 内置提取 + case 匹配，典型路径 1 个子进程（awk）
set -euo pipefail

INPUT=$(cat)
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

# 获取阶段 — 单次 awk
PHASE_NUM=0
if [ -f "$STATE_FILE" ]; then
  PHASE_NUM=$(awk '/^current_phase:/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)
fi
PHASE_NUM="${PHASE_NUM:-0}"

# 提取工具信息 — bash 内置字符串操作（零子进程）
_t="${INPUT#*\"tool_name\"}"
_t="${_t#*\"}"
TOOL_NAME="${_t%%\"*}"

TOOL_ACTION=""
_t2="${INPUT#*\"command\"}"
if [ "$_t2" != "$INPUT" ]; then
  _t2="${_t2#*\"}"
  TOOL_ACTION="${_t2%%\"*}"
else
  _t2="${INPUT#*\"file_path\"}"
  if [ "$_t2" != "$INPUT" ]; then
    _t2="${_t2#*\"}"
    TOOL_ACTION="${_t2%%\"*}"
  fi
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
    # bash case 统一匹配（零子进程，替代 5 个 grep 调用）
    case "$TOOL_ACTION" in
      git\ status*|git\ diff*|git\ log*|git\ branch*|git\ stash*)
        BEHAVIOR="allow" ;;
      *rm\ -rf*|*--force*|*reset\ --hard*)
        exit 0 ;;  # 危险命令交给用户
      git\ commit*|git\ push*|git\ tag*|git\ merge\ *)
        [ "$PHASE_NUM" -ge 6 ] && BEHAVIOR="allow" || { BEHAVIOR="deny"; MESSAGE="Git 提交操作仅 P6 允许"; } ;;
      npm\ test*|npx\ jest*|npx\ vitest*|npx\ mocha*|yarn\ test*|pnpm\ test*|pytest*|go\ test*|cargo\ test*|mvn\ test*|jest\ *|vitest\ *|mocha\ *)
        [ "$PHASE_NUM" -ge 4 ] && BEHAVIOR="allow" || { BEHAVIOR="deny"; MESSAGE="测试命令仅 P4 起允许"; } ;;
      npx\ eslint*|npx\ tsc*|npm\ run\ lint*|npm\ run\ build*)
        BEHAVIOR="allow" ;;
      *)
        [ "$PHASE_NUM" -ge 3 ] && BEHAVIOR="allow" ;;
    esac
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
