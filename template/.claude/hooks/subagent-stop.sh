#!/bin/bash
# SubagentStop — 子 Agent 完成时验证输出质量
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)

if [ -z "$PHASE" ] || [ "$PHASE" = "P0" ]; then
  exit 0
fi

# 仅在自动驱动阶段（P3-P5）检查
PHASE_NUM=$(echo "$PHASE" | sed 's/[^0-9]//g')
PHASE_NUM=${PHASE_NUM:-0}

if [ "$PHASE_NUM" -lt 3 ] || [ "$PHASE_NUM" -gt 5 ]; then
  exit 0
fi

PRD_COUNT=$(grep -c '^\s*-\s*id:' "$STATE_FILE" 2>/dev/null || echo 0)

CONTEXT="[SDLC 子 Agent 完成验证] 阶段=${PHASE}。子 Agent 已完成。请验证：(1) 输出符合 PRD（共${PRD_COUNT}条需求） (2) 代码质量符合规范 (3) 无 PRD 外变更 (4) modified_files 已更新。如不合规请修复后再推进。"

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStop","additionalContext":"%s"}}' "$CONTEXT"
