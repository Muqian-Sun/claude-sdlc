#!/bin/bash
# SessionEnd — 会话结束时归档状态摘要
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 单次 awk 提取阶段、任务和已修改文件
eval "$(awk '
  /^current_phase:/ { gsub(/[^A-Za-z0-9]/,"",$2); phase=$2 }
  /^task_description:/ { gsub(/^task_description:[[:space:]]*"?|"?[[:space:]]*$/,"",$0); task=$0 }
  /^modified_files:/,/^[a-z]/ { if(/^\s*-\s/) { gsub(/^\s*-\s*/,"",$0); files=files "\n  - " $0 } }
  END { printf "PHASE=%s\nTASK=\"%s\"\nMOD_FILES=\"%s\"\n", phase, task, files }
' "$STATE_FILE" 2>/dev/null)"

REVIEWS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/reviews"
if [ -d "$REVIEWS_DIR" ] && [ -n "$PHASE" ] && [ "$PHASE" != "P0" ]; then
  TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
  {
    echo "# 会话结束摘要"
    echo ""
    echo "- **结束时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **阶段**: ${PHASE}"
    echo "- **任务**: ${TASK:-无}"
    echo ""
    echo "## 已修改文件"
    if [ -n "$MOD_FILES" ]; then
      echo "$MOD_FILES"
    else
      echo "  （无）"
    fi
  } > "$REVIEWS_DIR/session-end-${TIMESTAMP}.md" 2>/dev/null
fi

exit 0
