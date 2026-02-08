#!/bin/bash
# SessionStart hook — 注入 SDLC 阶段上下文
INPUT=$(cat)

# 读取 source 字段（startup|resume|compact）
SOURCE="startup"
if command -v jq &>/dev/null; then
  SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"' 2>/dev/null)
else
  SOURCE=$(echo "$INPUT" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
  SOURCE="${SOURCE:-startup}"
fi

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
[ ! -f "$STATE_FILE" ] && exit 0

# 单次 awk 提取所有字段
eval "$(awk '
  /^current_phase:/ { phase=$2 }
  /^task_description:/ { sub(/^task_description:[[:space:]]*"?/,""); sub(/"$/,""); task=$0 }
  /^modified_files:/,/^[a-z]/ { if(/^\s*-\s/) fc++ }
  /^key_context:/ { sub(/^key_context:[[:space:]]*"?/,""); sub(/"$/,""); kc=$0 }
  /^project_roadmap:/ { sub(/^project_roadmap:[[:space:]]*"?/,""); sub(/"$/,""); rm=$0 }
  /^completed_tasks:/,/^[a-z]/ { if(/^\s*-\s*task:/) ct++ }
  END {
    gsub(/["\\]/,"",task)
    gsub(/["\\]/,"",kc)
    gsub(/["\\]/,"",rm)
    printf "PHASE=%s\nTASK=%s\nFILES_COUNT=%d\nKEY_CTX=%s\nROADMAP=%s\nCOMPLETED=%d\n", phase, task, fc, kc, rm, ct
  }
' "$STATE_FILE" 2>/dev/null)"

# 构建持久化上下文提示
PERSIST=""
[ -n "$ROADMAP" ] && PERSIST="有长期规划（project_roadmap），"
[ "${COMPLETED:-0}" -gt 0 ] && PERSIST="${PERSIST}已完成${COMPLETED}个任务，"

# 构建上下文信息（根据 source 定制）
if [ "$PHASE" = "P0" ] || [ -z "$PHASE" ]; then
  CONTEXT="SDLC 状态：P0（等待新任务）。${PERSIST}用户提出开发请求后自动进入 P1。请先 Read .claude/project-state.md 了解已有规划和历史。"
elif [ "$SOURCE" = "compact" ]; then
  CONTEXT="SDLC 压缩恢复：阶段=${PHASE}，任务=${TASK}，已修改${FILES_COUNT:-0}个文件。${PERSIST}关键上下文=${KEY_CTX}。请用 Read 读取 .claude/project-state.md 获取完整状态（特别是 project_roadmap 和 completed_tasks），然后继续工作。注意：压缩前的对话已丢失，依赖 project-state.md 恢复。"
elif [ "$SOURCE" = "resume" ]; then
  CONTEXT="SDLC 会话恢复：阶段=${PHASE}，任务=${TASK}，已修改${FILES_COUNT:-0}个文件。${PERSIST}请用 Read 读取 .claude/project-state.md 确认状态后继续工作。"
else
  CONTEXT="SDLC 状态恢复：阶段=${PHASE}，任务=${TASK}，已修改${FILES_COUNT:-0}个文件。${PERSIST}请用 Read 读取 .claude/project-state.md 获取完整状态，然后继续工作。"
fi

# 通过 $CLAUDE_ENV_FILE 导出环境变量（仅 SessionStart 支持）
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "SDLC_PHASE=${PHASE:-P0}" >> "$CLAUDE_ENV_FILE"
  echo "SDLC_TASK=${TASK}" >> "$CLAUDE_ENV_FILE"
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$CONTEXT"
