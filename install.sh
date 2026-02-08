#!/usr/bin/env bash
# install.sh — SDLC Enforcer 一键安装脚本
# 用法：./install.sh /path/to/your-project
#
# 功能：
# 1. 将 template/ 下的 SDLC 规范文件安装到目标项目
# 2. 自动备份已有的 CLAUDE.md
# 3. 智能合并 .claude/settings.json（不覆盖已有配置）
# 4. 设置 hook 脚本的执行权限

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录（支持符号链接）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/template"

# 打印带颜色的消息
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示使用说明
usage() {
  cat <<EOF
SDLC Enforcer 安装脚本

用法：
  ./install.sh <目标项目路径>

示例：
  ./install.sh /path/to/your-project
  ./install.sh .                        # 安装到当前目录
  ./install.sh ~/projects/my-app

说明：
  将 SDLC 开发规范安装到指定的项目目录中。
  安装后在该项目中启动 Claude Code 即可自动加载规范。
EOF
  exit 1
}

# 检查参数
if [ $# -eq 0 ]; then
  usage
fi

TARGET_DIR="$1"

# 解析目标目录的绝对路径
if [ "$TARGET_DIR" = "." ]; then
  TARGET_DIR="$(pwd)"
elif [[ "$TARGET_DIR" != /* ]]; then
  TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    error "目标目录不存在：$1"
    exit 1
  }
fi

# 检查目标目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
  error "目标目录不存在：$TARGET_DIR"
  exit 1
fi

# 检查 template 目录是否存在
if [ ! -d "$TEMPLATE_DIR" ]; then
  error "找不到 template 目录：$TEMPLATE_DIR"
  error "请确保在 sdlc-enforcer 目录中运行此脚本"
  exit 1
fi

echo ""
echo "========================================"
echo "  SDLC Enforcer 安装程序"
echo "========================================"
echo ""
info "模板目录：$TEMPLATE_DIR"
info "目标项目：$TARGET_DIR"
echo ""

# === Step 1: 备份已有的 CLAUDE.md ===
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  BACKUP_FILE="$TARGET_DIR/CLAUDE.md.bak.$(date +%Y%m%d%H%M%S)"
  warn "目标项目已有 CLAUDE.md，备份为：$(basename "$BACKUP_FILE")"
  cp "$TARGET_DIR/CLAUDE.md" "$BACKUP_FILE"
  success "已备份 CLAUDE.md"
fi

# === Step 2: 复制 CLAUDE.md ===
cp "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
success "已安装 CLAUDE.md"

# === Step 3: 创建 .claude 目录结构 ===
mkdir -p "$TARGET_DIR/.claude/rules"
mkdir -p "$TARGET_DIR/.claude/hooks"
mkdir -p "$TARGET_DIR/.claude/skills"
mkdir -p "$TARGET_DIR/.claude/agents"
mkdir -p "$TARGET_DIR/.claude/reviews"
success "已创建 .claude/ 目录结构"

# 升级清理：删除旧版 commands/ 目录（已被 skills/ 取代）
if [ -d "$TARGET_DIR/.claude/commands" ]; then
  rm -rf "$TARGET_DIR/.claude/commands"
  success "已清理旧版 .claude/commands/（已被 skills/ 取代）"
fi

# === Step 4: 复制 rules 文件 ===
for rule_file in "$TEMPLATE_DIR/.claude/rules"/*.md; do
  if [ -f "$rule_file" ]; then
    cp "$rule_file" "$TARGET_DIR/.claude/rules/"
    success "已安装规则：$(basename "$rule_file")"
  fi
done

# === Step 5: 复制 hooks 脚本 ===
for hook_file in "$TEMPLATE_DIR/.claude/hooks"/*.sh; do
  if [ -f "$hook_file" ]; then
    cp "$hook_file" "$TARGET_DIR/.claude/hooks/"
    chmod +x "$TARGET_DIR/.claude/hooks/$(basename "$hook_file")"
    success "已安装 Hook：$(basename "$hook_file")"
  fi
done

# === Step 6: 复制 skills ===
if [ -d "$TEMPLATE_DIR/.claude/skills" ]; then
  for skill_dir in "$TEMPLATE_DIR/.claude/skills"/*/; do
    if [ -d "$skill_dir" ]; then
      skill_name=$(basename "$skill_dir")
      mkdir -p "$TARGET_DIR/.claude/skills/$skill_name"
      if [ -f "$skill_dir/SKILL.md" ]; then
        cp "$skill_dir/SKILL.md" "$TARGET_DIR/.claude/skills/$skill_name/"
        success "已安装 Skill：$skill_name"
      fi
    fi
  done
fi

# === Step 7: 复制 agents ===
for agent_file in "$TEMPLATE_DIR/.claude/agents"/*.md; do
  if [ -f "$agent_file" ]; then
    cp "$agent_file" "$TARGET_DIR/.claude/agents/"
    success "已安装 Agent：$(basename "$agent_file")"
  fi
done

# === Step 8: 智能合并 settings.json ===
TARGET_SETTINGS="$TARGET_DIR/.claude/settings.json"
SOURCE_SETTINGS="$TEMPLATE_DIR/.claude/settings.json"

if [ -f "$TARGET_SETTINGS" ]; then
  # 目标项目已有 settings.json，尝试智能合并
  warn "目标项目已有 .claude/settings.json"

  # 检查是否安装了 jq
  if command -v jq &>/dev/null; then
    # 使用 jq 合并 hooks 配置
    BACKUP_SETTINGS="$TARGET_SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
    cp "$TARGET_SETTINGS" "$BACKUP_SETTINGS"
    warn "已备份原 settings.json 为：$(basename "$BACKUP_SETTINGS")"

    # 合并策略：将 SDLC hooks 添加到现有 hooks 中（不覆盖其他配置）
    # 按 matcher 去重合并所有 12 种 hook 类型
    MERGED=$(jq -s '
      def dedup_hooks: group_by(.hooks | map(.command // .prompt) | join("|")) | map(.[0]);
      .[0] as $existing |
      .[1] as $new |
      $existing * {
        hooks: {
          PreToolUse: (($existing.hooks.PreToolUse // []) + ($new.hooks.PreToolUse // []) | dedup_hooks),
          PostToolUse: (($existing.hooks.PostToolUse // []) + ($new.hooks.PostToolUse // []) | dedup_hooks),
          PostToolUseFailure: (($existing.hooks.PostToolUseFailure // []) + ($new.hooks.PostToolUseFailure // []) | dedup_hooks),
          Stop: (($existing.hooks.Stop // []) + ($new.hooks.Stop // []) | dedup_hooks),
          PreCompact: (($existing.hooks.PreCompact // []) + ($new.hooks.PreCompact // []) | dedup_hooks),
          SessionStart: (($existing.hooks.SessionStart // []) + ($new.hooks.SessionStart // []) | dedup_hooks),
          SessionEnd: (($existing.hooks.SessionEnd // []) + ($new.hooks.SessionEnd // []) | dedup_hooks),
          UserPromptSubmit: (($existing.hooks.UserPromptSubmit // []) + ($new.hooks.UserPromptSubmit // []) | dedup_hooks),
          SubagentStart: (($existing.hooks.SubagentStart // []) + ($new.hooks.SubagentStart // []) | dedup_hooks),
          SubagentStop: (($existing.hooks.SubagentStop // []) + ($new.hooks.SubagentStop // []) | dedup_hooks),
          TaskCompleted: (($existing.hooks.TaskCompleted // []) + ($new.hooks.TaskCompleted // []) | dedup_hooks),
          PermissionRequest: (($existing.hooks.PermissionRequest // []) + ($new.hooks.PermissionRequest // []) | dedup_hooks)
        }
      }
    ' "$TARGET_SETTINGS" "$SOURCE_SETTINGS" 2>/dev/null) || {
      warn "自动合并失败，将覆盖安装 settings.json"
      cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
      success "已安装 settings.json（覆盖）"
      MERGED=""
    }

    if [ -n "$MERGED" ]; then
      echo "$MERGED" > "$TARGET_SETTINGS"
      success "已智能合并 settings.json（保留原有配置）"
    fi
  else
    # 没有 jq，备份后覆盖
    BACKUP_SETTINGS="$TARGET_SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
    cp "$TARGET_SETTINGS" "$BACKUP_SETTINGS"
    warn "未安装 jq，无法智能合并。已备份原文件为：$(basename "$BACKUP_SETTINGS")"
    cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
    success "已安装 settings.json（覆盖）"
  fi
else
  # 目标项目没有 settings.json，直接复制
  cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
  success "已安装 settings.json"
fi

# === Step 9: 安装完成 ===
echo ""
echo "========================================"
echo -e "  ${GREEN}安装完成！${NC}"
echo "========================================"
echo ""
echo "已安装的文件："
echo "  $TARGET_DIR/"
echo "  ├── CLAUDE.md                    (核心控制文件，自动加载)"
echo "  └── .claude/"
echo "      ├── project-state.md         (项目状态，升级时保留)"
echo "      ├── settings.json            (Hooks + Permissions 配置)"
echo "      ├── rules/                   (8 个规则文件，自动加载)"
echo "      ├── hooks/                   (14 个 Hook 脚本，运行时拦截)"
echo "      ├── skills/                  (4 个 Skills: /phase /status /checkpoint /review)"
echo "      ├── agents/                  (3 个自定义 Agent: coder/tester/reviewer)"
echo "      └── reviews/                 (审查报告持久化)"
echo ""
echo "使用方法："
echo "  1. cd $TARGET_DIR"
echo "  2. 启动 claude 即可自动加载 SDLC 规范"
echo "  3. 使用 /phase 查看当前阶段"
echo "  4. 使用 /status 查看项目状态"
echo ""
echo "注意："
echo "  - Hook 脚本在无 jq 时会自动降级为 sed 解析（仍然可用）"
echo "  - 建议安装 jq 以获得更可靠的 JSON 解析和 settings.json 智能合并："
echo "    macOS:  brew install jq"
echo "    Ubuntu: sudo apt-get install jq"
echo ""
