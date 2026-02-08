#!/bin/bash
# PreCompact — 压缩前状态检查（轻量 command）
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
[ ! -f "$STATE_FILE" ] && exit 0

# 单次 awk 提取所有字段
eval "$(awk '
  /^current_phase:/ { phase=$2 }
  /^task_description:/ { sub(/^task_description:[[:space:]]*"?/,""); sub(/"$/,""); task=$0 }
  /^key_context:/ { sub(/^key_context:[[:space:]]*"?/,""); sub(/"$/,""); kc=$0 }
  /^last_updated:/ { has_lu=1 }
  /^modified_files:/,/^[a-z]/ { if(/^\s*-\s/) fc++ }
  /^\s*-\s*id:/ { prd++ }
  END {
    gsub(/["\\]/,"",task)
    gsub(/["\\]/,"",kc)
    printf "PHASE=%s\nTASK=%s\nKC=%s\nHAS_LU=%d\nFILES_COUNT=%d\nPRD_COUNT=%d\n", phase, task, kc, has_lu, fc, prd
  }
' "$STATE_FILE" 2>/dev/null)"

PHASE="${PHASE:-P0}"
WARNINGS=""
[ -z "$KC" ] && WARNINGS="key_context 为空！"
[ "${HAS_LU:-0}" -eq 0 ] && WARNINGS="${WARNINGS} last_updated 未设置。"

CONTEXT="[SDLC 压缩前紧急保存] 上下文即将被压缩！阶段=${PHASE}，任务=${TASK}，PRD ${PRD_COUNT:-0}条，已修改${FILES_COUNT:-0}个文件。${WARNINGS}请立即用 Edit 更新 project-state.md：(1) 确认 modified_files 列表完整 (2) 将当前工作摘要写入 key_context (3) 更新 last_updated (4) 确认 project_roadmap 和 global_architecture 已记录（如有长期规划）。压缩后早期对话将丢失，这是最后保存机会。"

# PreCompact 不支持 hookSpecificOutput，用 stopReason 注入提醒
printf '{"stopReason":"%s"}' "$CONTEXT"
