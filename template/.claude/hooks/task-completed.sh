#!/bin/bash
# TaskCompleted — 子任务完成时验证
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)

# 仅在自动驱动阶段（P3-P5）检查
PHASE_NUM=$(echo "$PHASE" | sed 's/[^0-9]//g')
PHASE_NUM=${PHASE_NUM:-0}

if [ "$PHASE_NUM" -lt 3 ] || [ "$PHASE_NUM" -gt 5 ]; then
  exit 0
fi

# 提醒主 Agent 验证子任务结果
CONTEXT="[SDLC 子任务完成检查] 阶段=${PHASE}。子任务已完成，请验证：(1) 修改的文件已追加到 modified_files (2) 代码符合 PRD 需求 (3) 无 PRD 范围外的代码。如有问题请修复后再推进。"

printf '{"hookSpecificOutput":{"hookEventName":"TaskCompleted","additionalContext":"%s"}}' "$CONTEXT"
