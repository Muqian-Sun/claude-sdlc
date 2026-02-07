#!/usr/bin/env bash
# check-phase-write.sh — PreToolUse hook for Write/Edit
# 在 P3（编码实现）之前拦截对代码文件的写入操作
# 文档类文件（.md, .txt, .json, .yaml, .yml 等）在任何阶段放行

set -euo pipefail

# 从 stdin 读取 JSON 输入
INPUT=$(cat)

# 提取文件路径（从 tool_input 中获取 file_path）
# 兼容 jq 不存在的情况
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  # 无 jq 时用 sed 粗略提取（容错）
  FILE_PATH=$(echo "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi

# 如果无法获取文件路径，默认放行
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 文档/配置类文件扩展名 — 任何阶段都允许写入
# 注意：.html 和 .css 是代码文件（Web 项目），不在白名单中
DOC_EXTENSIONS='\.(md|txt|json|yaml|yml|toml|ini|cfg|conf|gitignore|editorconfig|prettierrc|eslintrc|csv|xml|svg|lock|log|env|env\..*)$'

if echo "$FILE_PATH" | grep -qiE "$DOC_EXTENSIONS"; then
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

# 读取当前阶段 — 兼容 macOS (BSD grep) 和 Linux (GNU grep)
# 不使用 grep -oP（macOS 不支持 Perl 正则）
CURRENT_PHASE=$(sed -n 's/^current_phase:[[:space:]]*\([^[:space:]#]*\).*/\1/p' "$CLAUDE_MD" 2>/dev/null | head -1)

# 如果无法确定阶段，默认放行（容错）
if [ -z "$CURRENT_PHASE" ]; then
  exit 0
fi

# 提取阶段编号（P0→0, P1→1, ...）— 兼容 macOS
PHASE_NUM=$(echo "$CURRENT_PHASE" | sed 's/[^0-9]//g' 2>/dev/null)

if [ -z "$PHASE_NUM" ]; then
  exit 0
fi

# P3（编号 3）及以上允许写代码文件
if [ "$PHASE_NUM" -ge 3 ]; then
  exit 0
fi

# P0/P1/P2 阶段不允许写代码文件 — 输出拦截信息
cat <<EOF
⛔ SDLC 规范拦截：当前阶段 $CURRENT_PHASE 不允许修改代码文件。

- 当前阶段：$CURRENT_PHASE
- 尝试修改的文件：$FILE_PATH
- 代码文件写入最早允许在 P3（编码实现）阶段

请先完成当前阶段的退出条件，使用 /phase next 推进到 P3 后再编写代码。
如确需在当前阶段修改此文件，请告知用户并获得明确授权。
EOF

exit 2
