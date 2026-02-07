#!/bin/bash
# PreCompact — 压缩前状态检查（command 版，不消耗主会话上下文）
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(sed -n 's/^task_description:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g')

PHASE="${PHASE:-P0}"

# 检查关键字段完整性
WARNINGS=""

# key_context 是否为空
KEY_CONTEXT=$(sed -n 's/^key_context:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
if [ -z "$KEY_CONTEXT" ]; then
  WARNINGS="key_context 为空！"
fi

# modified_files 计数
FILES_COUNT=$(sed -n '/^modified_files:/,/^[a-z]/p' "$STATE_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
FILES_COUNT="${FILES_COUNT:-0}"

# PRD 计数
PRD_COUNT=$(grep -c '^\s*-\s*id:' "$STATE_FILE" 2>/dev/null || true)
PRD_COUNT="${PRD_COUNT:-0}"

# last_updated 检查
LAST_UPDATED=$(sed -n 's/^last_updated:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
if [ -z "$LAST_UPDATED" ]; then
  WARNINGS="${WARNINGS} last_updated 未设置。"
fi

CONTEXT="[SDLC 压缩前紧急保存] 上下文即将被压缩！阶段=${PHASE}，任务=${TASK}，PRD ${PRD_COUNT}条，已修改${FILES_COUNT}个文件。${WARNINGS}请立即用 Edit 更新 project-state.md：(1) 确认 modified_files 列表完整 (2) 将当前工作摘要写入 key_context (3) 更新 last_updated。压缩后早期对话将丢失，这是最后保存机会。"

printf '{"hookSpecificOutput":{"hookEventName":"PreCompact","additionalContext":"%s"}}' "$CONTEXT"
