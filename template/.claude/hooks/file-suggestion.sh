#!/bin/bash
# fileSuggestion — @ 文件补全，优先 SDLC 文件
# 接收 stdin JSON: {"query": "..."}
# 输出：每行一个文件路径（最多 15 行）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# SDLC 核心文件（始终优先显示）
SDLC_FILES=(
  ".claude/project-state.md"
  "CLAUDE.md"
  ".claude/settings.json"
)

for f in "${SDLC_FILES[@]}"; do
  [ -f "$PROJECT_DIR/$f" ] && echo "$f"
done

# SDLC 规则和审查文件
for f in "$PROJECT_DIR"/.claude/rules/*.md; do
  [ -f "$f" ] && echo ".claude/rules/$(basename "$f")"
done

for f in "$PROJECT_DIR"/.claude/reviews/*.md; do
  [ -f "$f" ] && echo ".claude/reviews/$(basename "$f")"
done | tail -5
