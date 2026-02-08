#!/usr/bin/env bash
# check-phase-test.sh — PreToolUse hook for Bash
# 拦截：(1) P4 前的测试命令 (2) P6 前的 git commit/push
# 性能：bash 内置提取 + case 匹配，典型路径 1-2 个子进程
set -euo pipefail

INPUT=$(cat)

# 提取命令 — bash 内置字符串操作（零子进程）
_t="${INPUT#*\"command\"}"
[ "$_t" = "$INPUT" ] && exit 0
_t="${_t#*\"}"
COMMAND="${_t%%\"*}"
[ -z "$COMMAND" ] && exit 0

# 读取阶段 — 单次 awk
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
[ ! -f "$STATE_FILE" ] && exit 0
PHASE_NUM=$(awk '/^current_phase:/{gsub(/[^0-9]/,"",$2); print $2; exit}' "$STATE_FILE" 2>/dev/null)
[ -z "$PHASE_NUM" ] && exit 0

# P6+ 所有命令放行
[ "$PHASE_NUM" -ge 6 ] && exit 0

# Git write 操作（P6 前拦截）— bash case（零子进程）
case "$COMMAND" in
  git\ commit*|git\ push*|git\ tag*|git\ merge\ *)
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"当前阶段 P%s 不允许执行 Git 提交/推送操作（P6 起可用）"}}' "$PHASE_NUM"
    exit 0 ;;
esac

# P4+ 不需要测试检查
[ "$PHASE_NUM" -ge 4 ] && exit 0

# 测试命令（P4 前拦截）— grep + here-string（1 个子进程，仅 P1-P3 执行）
TEST_RE='(^|[;&|] *)(npm (test|run test)|npx (jest|vitest|mocha)|yarn test|pnpm test|pytest|python -m (pytest|unittest)|go test|cargo test|mvn test|gradle *test|gradlew test|dotnet test|rspec|bundle exec rspec|phpunit|swift test|flutter test|mix test|jest|vitest|mocha)( |$|;|&|\|)'
if grep -qE "$TEST_RE" <<< "$COMMAND"; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"当前阶段 P%s 不允许执行测试命令（P4 起可用）"}}' "$PHASE_NUM"
  exit 0
fi

exit 0
