#!/bin/bash
# TaskCompleted — 子任务完成时验证
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 单次 awk 提取阶段和阶段号
eval "$(awk '
  /^current_phase:/ { gsub(/[^A-Za-z0-9]/,"",$2); phase=$2; num=phase; gsub(/[^0-9]/,"",num); printf "PHASE=%s\nPHASE_NUM=%d\n", phase, num+0 }
' "$STATE_FILE" 2>/dev/null)"

PHASE_NUM=${PHASE_NUM:-0}

if [ "$PHASE_NUM" -lt 3 ] || [ "$PHASE_NUM" -gt 5 ]; then
  exit 0
fi

# 提醒主 Agent 验证子任务结果
CONTEXT="[SDLC 子任务完成检查] 阶段=${PHASE}。子任务已完成，请验证：(1) 修改的文件已追加到 modified_files (2) 代码符合 PRD 需求 (3) 无 PRD 范围外的代码。如有问题请修复后再推进。"

# TaskCompleted 不支持 hookSpecificOutput，用 stopReason 注入提醒
printf '{"stopReason":"%s"}' "$CONTEXT"
