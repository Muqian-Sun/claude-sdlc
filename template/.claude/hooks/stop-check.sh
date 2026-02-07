#!/bin/bash
# Stop — 回复后轻量自检（command 版，不消耗主会话上下文）
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(sed -n 's/^task_description:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(printf '%s' "$TASK" | sed 's/\\/\\\\/g; s/"/\\"/g')

if [ -z "$PHASE" ] || [ "$PHASE" = "P0" ]; then
  exit 0
fi

PHASE_NUM=$(echo "$PHASE" | sed 's/[^0-9]//g')
PHASE_NUM=${PHASE_NUM:-0}

# 统计已修改文件数
FILES_COUNT=$(sed -n '/^modified_files:/,/^[a-z]/p' "$STATE_FILE" 2>/dev/null | grep -c '^\s*-\s' 2>/dev/null || true)
FILES_COUNT="${FILES_COUNT:-0}"

# 检查 last_updated 是否存在
LAST_UPDATED=$(sed -n 's/^last_updated:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/p' "$STATE_FILE" 2>/dev/null | head -1)

# 构建检查提醒
CHECKS=""

# P1/P2：检查是否在等待用户确认
if [ "$PHASE_NUM" -le 2 ] && [ "$PHASE_NUM" -ge 1 ]; then
  CHECKS="阶段${PHASE}：展示产出物后等待用户确认，不要自问自答。"
fi

# P3-P5 自动驱动：提醒继续推进
if [ "$PHASE_NUM" -ge 3 ] && [ "$PHASE_NUM" -le 5 ]; then
  CHECKS="自动驱动阶段(${PHASE})：(1) 当前阶段工作是否完成？(2) modified_files 是否最新？(3) 完成后执行 /review 审查再推进。"
fi

# P6：检查是否已输出交付摘要
if [ "$PHASE_NUM" -eq 6 ]; then
  CHECKS="P6 交付阶段：确认已输出交付摘要（PRD 完成率、修改文件、测试结果、Git 提交信息）。"
fi

# last_updated 缺失提醒
if [ -z "$LAST_UPDATED" ]; then
  CHECKS="${CHECKS} 注意：last_updated 未设置，请更新 project-state.md。"
fi

if [ -z "$CHECKS" ]; then
  exit 0
fi

CONTEXT="[SDLC 自检] 阶段=${PHASE}，已修改${FILES_COUNT}个文件。${CHECKS}"

printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' "$CONTEXT"
