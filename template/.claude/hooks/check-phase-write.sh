#!/usr/bin/env bash
# check-phase-write.sh — PreToolUse hook for Write/Edit
# P3 前拦截代码文件写入，文档/配置文件任何阶段放行，P1 允许原型 HTML/CSS
# 性能：bash 内置提取 + case 匹配，典型路径 1-2 个子进程
set -euo pipefail

INPUT=$(cat)

# 提取文件路径 — bash 内置字符串操作（零子进程）
_t="${INPUT#*\"file_path\"}"
[ "$_t" = "$INPUT" ] && exit 0
_t="${_t#*\"}"
FILE_PATH="${_t%%\"*}"
[ -z "$FILE_PATH" ] && exit 0

# 文档/配置文件扩展名 — 兼容 bash 3.2（macOS 默认）
EXT=$(printf '%s' "${FILE_PATH##*.}" | tr 'A-Z' 'a-z')
case "$EXT" in
  md|txt|json|yaml|yml|toml|ini|cfg|conf|gitignore|editorconfig|prettierrc|eslintrc|csv|xml|svg|lock|log)
    exit 0 ;;
esac
# .env 及 .env.* 文件也放行（由 permissions deny 控制）
case "$FILE_PATH" in
  *.env|*.env.*) exit 0 ;;
esac

# 读取阶段 — 单次 awk
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
[ ! -f "$STATE_FILE" ] && exit 0
PHASE_NUM=$(awk '/^current_phase:/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)
[ -z "$PHASE_NUM" ] && exit 0

# P3+ 放行所有代码文件
[ "$PHASE_NUM" -ge 3 ] && exit 0

# P1 放行原型文件（HTML/CSS）— 用于 Chrome 展示设计原型
if [ "$PHASE_NUM" -eq 1 ]; then
  case "$EXT" in
    html|css) exit 0 ;;
  esac
fi

# 拦截 — JSON permissionDecision 格式（printf 零子进程）
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"当前阶段 P%s 不允许修改代码文件（P3 起可用，P1 仅允许原型 HTML/CSS）"}}' "$PHASE_NUM"
exit 0
