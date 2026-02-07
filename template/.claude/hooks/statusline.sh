#!/bin/bash
input=$(cat)
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // .cwd')
STATE_FILE="${PROJECT_DIR}/.claude/project-state.md"

if [ ! -f "$STATE_FILE" ]; then
  echo "[SDLC] 未初始化"
  exit 0
fi

PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
TASK=$(sed -n 's/^task_description:[[:space:]]*"\(.*\)"/\1/p' "$STATE_FILE" 2>/dev/null | head -1)

# 阶段名称映射
case "$PHASE" in
  P0) NAME="等待任务" ;;
  P1) NAME="需求分析" ;;
  P2) NAME="系统设计" ;;
  P3) NAME="编码实现" ;;
  P4) NAME="测试验证" ;;
  P5) NAME="集成审查" ;;
  P6) NAME="部署交付" ;;
  *)  NAME="未知" ;;
esac

# 进度条
PHASE_NUM=$(echo "$PHASE" | sed 's/[^0-9]//g')
PHASE_NUM=${PHASE_NUM:-0}
FILLED=$((PHASE_NUM))
BAR=""
for i in 1 2 3 4 5 6; do
  if [ "$i" -le "$FILLED" ]; then
    BAR="${BAR}●"
  else
    BAR="${BAR}○"
  fi
done

# 颜色输出
if [ "$PHASE" = "P0" ]; then
  echo -e "\033[2m[SDLC ${PHASE}] ${NAME}\033[0m"
else
  TASK_SHORT=$(echo "$TASK" | cut -c1-30)
  echo -e "\033[36m[SDLC ${PHASE}]\033[0m ${NAME} ${BAR} \033[2m${TASK_SHORT}\033[0m"
fi
