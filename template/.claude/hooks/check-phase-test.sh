#!/usr/bin/env bash
# check-phase-test.sh — PreToolUse hook for Bash
# 拦截两类操作：
# 1. P4（测试验证）之前的测试命令
# 2. P6（部署交付）之前的 git commit/push 操作

set -euo pipefail

# 从 stdin 读取 JSON 输入
INPUT=$(cat)

# 提取 Bash 命令 — 兼容 jq 不存在的情况
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi

# 如果无法获取命令，默认放行
if [ -z "$COMMAND" ]; then
  exit 0
fi

# ==============================
# 读取项目状态
# ==============================

# 读取当前阶段（文件优先，环境变量兜底）
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/project-state.md"
if [ -f "$STATE_FILE" ]; then
  CURRENT_PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
fi
CURRENT_PHASE="${CURRENT_PHASE:-$SDLC_PHASE}"

if [ -z "$CURRENT_PHASE" ]; then
  exit 0
fi

# 提取阶段编号 — 兼容 macOS
PHASE_NUM=$(echo "$CURRENT_PHASE" | sed 's/[^0-9]//g' 2>/dev/null)

if [ -z "$PHASE_NUM" ]; then
  exit 0
fi

# ==============================
# 检查 1：Git commit/push 拦截（P6 之前）
# ==============================

# 匹配 git commit, git push, git tag (不拦截 git status/diff/log/branch/stash)
GIT_WRITE_PATTERN='git[[:space:]]+(commit|push|tag|merge)[[:space:]]'

if echo "$COMMAND" | grep -qiE "$GIT_WRITE_PATTERN"; then
  if [ "$PHASE_NUM" -lt 6 ]; then
    cat <<EOF
⛔ SDLC 规范拦截：当前阶段 $CURRENT_PHASE 不允许执行 Git 提交/推送操作。

- 当前阶段：$CURRENT_PHASE
- 尝试执行的命令：$COMMAND
- Git commit/push/merge 操作最早允许在 P6（部署交付）阶段

Git 提交操作仅在 P6（部署交付）阶段允许。自动驱动模式下会在完成 P3→P4→P5 后自动进入 P6。
如确需在当前阶段执行此命令，请告知用户并获得明确授权。
EOF
    exit 2
  fi
  # P6 允许，放行
  exit 0
fi

# ==============================
# 检查 2：测试命令拦截（P4 之前）
# ==============================

# 测试命令模式列表
TEST_PATTERNS=(
  "npm test"
  "npm run test"
  "npx jest"
  "npx vitest"
  "npx mocha"
  "yarn test"
  "pnpm test"
  "pytest"
  "python -m pytest"
  "python -m unittest"
  "go test"
  "cargo test"
  "mvn test"
  "gradle test"
  "gradlew test"
  "dotnet test"
  "rspec"
  "bundle exec rspec"
  "phpunit"
  "swift test"
  "flutter test"
  "mix test"
)

# 检查命令是否匹配测试模式
IS_TEST=false
for pattern in "${TEST_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "(^|[;&|]\s*)$pattern"; then
    IS_TEST=true
    break
  fi
done

# 也匹配独立的 jest/vitest/mocha 调用
if [ "$IS_TEST" = false ]; then
  if echo "$COMMAND" | grep -qiE '(^|[;&|]\s*)(jest|vitest|mocha)(\s|$)'; then
    IS_TEST=true
  fi
fi

# 如果不是测试命令，放行
if [ "$IS_TEST" = false ]; then
  exit 0
fi

# P4（编号 4）及以上允许执行测试
if [ "$PHASE_NUM" -ge 4 ]; then
  exit 0
fi

# P0-P3 阶段不允许执行测试 — 输出拦截信息
cat <<EOF
⛔ SDLC 规范拦截：当前阶段 $CURRENT_PHASE 不允许执行测试命令。

- 当前阶段：$CURRENT_PHASE
- 尝试执行的命令：$COMMAND
- 测试执行最早允许在 P4（测试验证）阶段

测试执行最早允许在 P4（测试验证）阶段。自动驱动模式下 P3 编码审查通过后会自动进入 P4。
如确需在当前阶段执行此命令，请告知用户并获得明确授权。
EOF

exit 2
