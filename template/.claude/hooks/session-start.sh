#!/bin/bash
# SessionStart hook — 注入 SDLC 阶段上下文
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(sed -n 's/^task_description:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
# JSON 安全转义（防止任务描述中的引号破坏 JSON）
TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g')

# 构建上下文信息
if [ "$PHASE" = "P0" ] || [ -z "$PHASE" ]; then
  CONTEXT="SDLC 状态：P0（等待新任务）。用户提出开发请求后自动进入 P1。"
else
  FILES_COUNT=$(sed -n '/^modified_files:/,/^[a-z]/p' "$STATE_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
  FILES_COUNT="${FILES_COUNT:-0}"
  CONTEXT="SDLC 状态恢复：阶段=${PHASE}，任务=${TASK}，已修改${FILES_COUNT}个文件。请用 Read 读取 .claude/project-state.md 获取完整状态，然后继续工作。"
fi

# 通过 $CLAUDE_ENV_FILE 导出环境变量（仅 SessionStart 支持此功能）
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "SDLC_PHASE=${PHASE:-P0}" >> "$CLAUDE_ENV_FILE"
  echo "SDLC_TASK=${TASK}" >> "$CLAUDE_ENV_FILE"
fi

# 输出 additionalContext
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$CONTEXT"
