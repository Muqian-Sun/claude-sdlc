#!/usr/bin/env bash
# check-phase-test.sh — PreToolUse hook for Bash
# 在 P4（测试验证）之前拦截测试命令的执行

set -euo pipefail

# 从 stdin 读取 JSON 输入
INPUT=$(cat)

# 提取 Bash 命令
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# 如果无法获取命令，默认放行
if [ -z "$COMMAND" ]; then
  exit 0
fi

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
  "dotnet test"
  "rspec"
  "bundle exec rspec"
  "phpunit"
  "jest "
  "jest$"
  "vitest "
  "vitest$"
  "mocha "
  "mocha$"
)

# 检查命令是否匹配测试模式
IS_TEST=false
for pattern in "${TEST_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "(^|[;&|]\s*)$pattern"; then
    IS_TEST=true
    break
  fi
done

# 如果不是测试命令，放行
if [ "$IS_TEST" = false ]; then
  exit 0
fi

# 查找项目根目录的 CLAUDE.md
find_claude_md() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/CLAUDE.md" ]; then
      echo "$dir/CLAUDE.md"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

CLAUDE_MD=$(find_claude_md 2>/dev/null) || true

# 如果找不到 CLAUDE.md，默认放行（容错）
if [ -z "$CLAUDE_MD" ]; then
  exit 0
fi

# 读取当前阶段
CURRENT_PHASE=$(grep -oP 'current_phase:\s*\K\S+' "$CLAUDE_MD" 2>/dev/null || echo "")

# 如果无法确定阶段，默认放行（容错）
if [ -z "$CURRENT_PHASE" ]; then
  exit 0
fi

# 提取阶段编号
PHASE_NUM=$(echo "$CURRENT_PHASE" | grep -oP '\d+' 2>/dev/null || echo "")

if [ -z "$PHASE_NUM" ]; then
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

请先完成编码实现（P3），使用 /phase next 推进到 P4 后再执行测试。
如确需在当前阶段执行此命令，请告知用户并获得明确授权。
EOF

exit 2
