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

# === Step 1: 安装 CLAUDE.md ===
if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
  # 已存在，检查是否需要更新
  if diff -q "$TARGET_DIR/CLAUDE.md" "$TEMPLATE_DIR/CLAUDE.md" >/dev/null 2>&1; then
    # 内容相同，跳过
    info "CLAUDE.md 已是最新版本"
  else
    # 内容不同，直接覆盖
    cp "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
    success "已更新 CLAUDE.md"
  fi
else
  # 首次安装
  cp "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
  success "已安装 CLAUDE.md"
fi

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

# === Step 3b: 安装 project-state.md ===
TARGET_STATE="$TARGET_DIR/.claude/project-state.md"
if [ -f "$TARGET_STATE" ]; then
  info "project-state.md 已存在，保留不覆盖"
else
  cp "$TEMPLATE_DIR/.claude/project-state.md" "$TARGET_STATE"
  success "已安装 project-state.md"
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
  if command -v jq &>/dev/null; then
    # 使用 jq 智能合并（hooks 覆盖，其他配置保留）
    MERGED=$(jq -s '
      .[0] as $existing | .[1] as $new |
      ($new.hooks // {}) as $nh |
      ($existing | del(.hooks)) * ($new | del(.hooks)) * {
        hooks: (reduce ($nh | keys[]) as $type (
          ($existing.hooks // {});
          . + {($type): ($nh[$type] // [])}
        ))
      }
    ' "$TARGET_SETTINGS" "$SOURCE_SETTINGS" 2>/dev/null) || {
      # 合并失败，直接覆盖
      cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
      warn "settings.json 合并失败，已覆盖为最新版本"
      MERGED=""
    }

    if [ -n "$MERGED" ]; then
      echo "$MERGED" > "$TARGET_SETTINGS"
      success "已智能合并 settings.json"
    fi
  else
    # 没有 jq，直接覆盖
    cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
    warn "未安装 jq，已覆盖 settings.json（建议安装 jq 以启用智能合并）"
  fi
else
  # 首次安装
  cp "$SOURCE_SETTINGS" "$TARGET_SETTINGS"
  success "已安装 settings.json"
fi

# === Step 9: 自动安装 UI/UX Pro Max Skill（依赖） ===
echo ""
info "正在检查 UI/UX Pro Max Skill..."

if [ -d "$TARGET_DIR/.claude/skills/ui-ux-pro-max" ]; then
  success "UI/UX Pro Max Skill 已安装"
else
  info "UI/UX Pro Max Skill 未安装，开始自动安装..."

  # 检查是否安装了 npm
  if command -v npm &>/dev/null; then
    # 安装 uipro-cli（如果未安装）
    if ! command -v uipro &>/dev/null; then
      info "正在全局安装 uipro-cli..."
      npm install -g uipro-cli >/dev/null 2>&1 || {
        warn "uipro-cli 安装失败，请手动安装 UI/UX Pro Max Skill："
        echo "    npm install -g uipro-cli"
        echo "    cd $TARGET_DIR"
        echo "    uipro init --ai claude"
      }
    fi

    # 运行 uipro init
    if command -v uipro &>/dev/null; then
      info "正在安装 UI/UX Pro Max Skill 到项目..."
      cd "$TARGET_DIR" && uipro init --ai claude >/dev/null 2>&1 && {
        success "✨ UI/UX Pro Max Skill 已自动安装"
      } || {
        warn "自动安装失败，请手动运行：cd $TARGET_DIR && uipro init --ai claude"
      }
    fi
  else
    warn "未检测到 npm，跳过 UI/UX Pro Max Skill 自动安装"
    echo "    请手动安装："
    echo "    1. npm install -g uipro-cli"
    echo "    2. cd $TARGET_DIR"
    echo "    3. uipro init --ai claude"
  fi
fi

# === Step 10: 安装完成 ===
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
echo "      ├── rules/                   (10 个规则文件，含 UI/UX 规范)"
echo "      ├── hooks/                   (14 个 Hook 脚本，运行时拦截)"
echo "      ├── skills/"
echo "      │   ├── phase/status/checkpoint/review  (4 个 SDLC Skills)"
echo "      │   └── ui-ux-pro-max/       (✨ UI/UX 设计智能)"
echo "      ├── agents/                  (3 个自定义 Agent: coder/tester/reviewer)"
echo "      └── reviews/                 (审查报告持久化)"
echo ""
echo "✨ UI/UX Pro Max Skill 特性："
echo "  - 67 种现代 UI 风格（glassmorphism、minimalism、brutalism 等）"
echo "  - 96 个行业专属配色方案（SaaS、电商、医疗、金融等）"
echo "  - 57 种精选字体配对（标题 + 正文）"
echo "  - 99 条 UX 最佳实践指南"
echo "  - 25 种数据可视化图表推荐"
echo ""
echo "使用方法："
echo "  1. cd $TARGET_DIR"
echo "  2. 启动 claude 即可自动加载 SDLC 规范 + UI/UX 规范"
echo "  3. 说\"帮我设计一个登录页面\"→ 自动使用 UI/UX Pro Max"
echo "  4. 使用 /phase 查看当前阶段"
echo "  5. 使用 /status 查看项目状态"
echo ""
echo "强制 UI/UX 规范："
echo "  ✅ P1 阶段自动使用 ui-ux-pro-max skill 调研和设计"
echo "  ✅ 从 67 风格 + 96 配色 + 57 字体中选择（禁止随意配色）"
echo "  ✅ 使用现代组件库（shadcn/ui、Radix、Ant Design 5+）"
echo "  ❌ 禁止过时技术（Bootstrap 3/4、jQuery UI、90年代表格）"
echo "  🔍 P4 自动审查：Lighthouse + axe-core + 响应式"
echo ""
echo "注意："
echo "  - Hook 脚本在无 jq 时会自动降级为 sed 解析（仍然可用）"
echo "  - 建议安装 jq 以获得更可靠的 JSON 解析和 settings.json 智能合并："
echo "    macOS:  brew install jq"
echo "    Ubuntu: sudo apt-get install jq"
echo ""
