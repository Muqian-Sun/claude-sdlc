#!/bin/bash
# SessionEnd — 会话结束时归档状态摘要
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(sed -n 's/^task_description:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

REVIEWS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/reviews"
if [ -d "$REVIEWS_DIR" ] && [ -n "$PHASE" ] && [ "$PHASE" != "P0" ]; then
  {
    echo "# 会话结束摘要"
    echo ""
    echo "- **结束时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **阶段**: ${PHASE}"
    echo "- **任务**: ${TASK:-无}"
    echo ""
    echo "## 已修改文件"
    sed -n '/^modified_files:/,/^[a-z]/p' "$STATE_FILE" 2>/dev/null | grep '^\s*-' || echo "  （无）"
  } > "$REVIEWS_DIR/session-end-${TIMESTAMP}.md" 2>/dev/null
fi

exit 0
