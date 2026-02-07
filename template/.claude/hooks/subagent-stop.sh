#!/bin/bash
# SubagentStop — 子 Agent 完成时验证输出质量
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 单次 awk 提取阶段和 PRD 数量
eval "$(awk '
  /^current_phase:/ { gsub(/[^A-Za-z0-9]/,"",$2); phase=$2; gsub(/[^0-9]/,"",phase); num=phase+0; phase=$2 }
  /^\s*-\s*id:/ { prd++ }
  END { printf "PHASE=%s\nPHASE_NUM=%d\nPRD_COUNT=%d\n", phase, num, prd }
' "$STATE_FILE" 2>/dev/null)"

if [ -z "$PHASE" ] || [ "$PHASE" = "P0" ]; then
  exit 0
fi

# 仅在自动驱动阶段（P3-P5）检查
if [ "$PHASE_NUM" -lt 3 ] || [ "$PHASE_NUM" -gt 5 ]; then
  exit 0
fi

CONTEXT="[SDLC 子 Agent 完成验证] 阶段=${PHASE}。子 Agent 已完成。请验证：(1) 输出符合 PRD（共${PRD_COUNT}条需求） (2) 代码质量符合规范 (3) 无 PRD 外变更 (4) modified_files 已更新。如不合规请修复后再推进。"

printf '{"hookSpecificOutput":{"hookEventName":"SubagentStop","additionalContext":"%s"}}' "$CONTEXT"
