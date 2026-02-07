#!/usr/bin/env bash
# check-phase-test.sh — PreToolUse hook for Bash
# 拦截：(1) P4 前的测试命令 (2) P6 前的 git commit/push
set -euo pipefail

INPUT=$(cat)

# 提取命令 — jq 优先，sed 兜底
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi

[ -z "$COMMAND" ] && exit 0

# 读取阶段 — 单次 awk 提取
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
if [ -f "$STATE_FILE" ]; then
  PHASE_NUM=$(awk '/^current_phase:/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)
fi
PHASE_NUM="${PHASE_NUM:-${SDLC_PHASE:+$(echo "$SDLC_PHASE" | sed 's/[^0-9]//g')}}"
[ -z "$PHASE_NUM" ] && exit 0

CURRENT_PHASE="P${PHASE_NUM}"

# 检查 1：Git write 操作（P6 前拦截）
if echo "$COMMAND" | grep -qiE 'git[[:space:]]+(commit|push|tag|merge)[[:space:]]'; then
  if [ "$PHASE_NUM" -lt 6 ]; then
    REASON="当前阶段 ${CURRENT_PHASE} 不允许执行 Git 提交/推送操作（P6 起可用）"
    if command -v jq &>/dev/null; then
      jq -n --arg r "$REASON" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$r}}'
    else
      printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$REASON"
    fi
    exit 0
  fi
  exit 0
fi

# 检查 2：测试命令（P4 前拦截）— 单条合并正则
TEST_REGEX='(^|[;&|]\s*)(npm\s+(test|run\s+test)|npx\s+(jest|vitest|mocha)|yarn\s+test|pnpm\s+test|pytest|python\s+-m\s+(pytest|unittest)|go\s+test|cargo\s+test|mvn\s+test|gradle\s*test|gradlew\s+test|dotnet\s+test|rspec|bundle\s+exec\s+rspec|phpunit|swift\s+test|flutter\s+test|mix\s+test|jest|vitest|mocha)(\s|$|;|&|\|)'

if echo "$COMMAND" | grep -qiE "$TEST_REGEX"; then
  [ "$PHASE_NUM" -ge 4 ] && exit 0
  REASON="当前阶段 ${CURRENT_PHASE} 不允许执行测试命令（P4 起可用）"
  if command -v jq &>/dev/null; then
    jq -n --arg r "$REASON" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$r}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$REASON"
  fi
  exit 0
fi

exit 0
