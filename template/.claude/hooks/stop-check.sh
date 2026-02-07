#!/bin/bash
# Stop — 回复后轻量自检
INPUT=$(cat)

# 检查 stop_hook_active 防止无限循环（官方要求）
if command -v jq &>/dev/null; then
  ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
else
  ACTIVE=$(echo "$INPUT" | grep -o '"stop_hook_active"[[:space:]]*:[[:space:]]*true' 2>/dev/null)
fi
if [ "$ACTIVE" = "true" ] || [ -n "$ACTIVE" ]; then exit 0; fi

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
[ ! -f "$STATE_FILE" ] && exit 0

# 单次 awk 提取所有字段
eval "$(awk '
  /^current_phase:/ { gsub(/[^0-9]/,"",$2); phase=$2; pname=$1" "$2 }
  /^task_description:/ { sub(/^task_description:[[:space:]]*"?/,""); sub(/"$/,""); task=$0 }
  /^modified_files:/,/^[a-z]/ { if(/^\s*-\s/) fc++ }
  /^last_updated:/ { has_lu=1 }
  END {
    gsub(/["\\]/,"",task)
    printf "PHASE_NUM=%s\nFILES_COUNT=%d\nHAS_LU=%d\n", phase, fc, has_lu
  }
' "$STATE_FILE" 2>/dev/null)"

PHASE_NUM="${PHASE_NUM:-0}"
[ "$PHASE_NUM" = "0" ] && exit 0

# 构建检查提醒
CHECKS=""
if [ "$PHASE_NUM" -ge 1 ] && [ "$PHASE_NUM" -le 2 ]; then
  CHECKS="阶段P${PHASE_NUM}：展示产出物后等待用户确认，不要自问自答。"
elif [ "$PHASE_NUM" -ge 3 ] && [ "$PHASE_NUM" -le 5 ]; then
  CHECKS="自动驱动阶段(P${PHASE_NUM})：(1) 当前阶段工作是否完成？(2) modified_files 是否最新？(3) 完成后执行 /review 审查再推进。"
elif [ "$PHASE_NUM" -eq 6 ]; then
  CHECKS="P6 交付阶段：确认已输出交付摘要（PRD 完成率、修改文件、测试结果、Git 提交信息）。"
fi

[ "${HAS_LU:-0}" -eq 0 ] && CHECKS="${CHECKS} 注意：last_updated 未设置，请更新 project-state.md。"
[ -z "$CHECKS" ] && exit 0

CONTEXT="[SDLC 自检] 阶段=P${PHASE_NUM}，已修改${FILES_COUNT:-0}个文件。${CHECKS}"
printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' "$CONTEXT"
