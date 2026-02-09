# Changelog

## [1.9.0] - 2026-02-10

### ✨ 新增功能
- **UI/UX Pro Max Skill 自动集成**：安装时自动安装 UI/UX Pro Max Skill
  - 67 种现代 UI 风格（glassmorphism、minimalism、brutalism 等）
  - 96 个行业专属配色方案（SaaS、电商、医疗、金融等）
  - 57 种精选字体配对
  - 99 条 UX 最佳实践指南
  - 25 种数据可视化图表推荐
- **新增 10-ui-ux-standards.md**：完整的 UI/UX 设计规范
  - P1 阶段强制使用 ui-ux-pro-max skill
  - 禁止过时技术（Bootstrap 3/4、jQuery UI、90年代表格）
  - P4 自动审查（Lighthouse + axe-core）

### 🚀 改进
- **文件瘦身**：10-ui-ux-standards.md 精简 37%（355 行 → 224 行）
- **安装优化**：去掉备份文件，直接智能替换/合并
  - CLAUDE.md：直接替换，始终使用最新版本
  - settings.json：智能合并，保留用户配置
  - project-state.md：保留不覆盖，保护用户数据
- **输出清晰**：更明确的安装/升级提示信息
- **无备份污染**：不再创建 .bak 文件

### 🔧 优化
- 简化 project-state.md 处理逻辑
- 改进 CLAUDE.md 智能检测（diff 对比）
- 优化安装脚本执行流程

### 📝 文档
- 更新 README.md：添加 UI/UX Pro Max 特性说明
- 更新 install.sh 输出信息

---

## [1.8.0] - 2026-02-09

### ✨ 新增功能
- 记忆精简管理（09-memory-management.md）
- Archive 技能（/archive 命令）
- 完整的 compaction 保护机制

### 🚀 改进
- PRD 精简格式（≤150 行）
- completed_tasks 自动归档（≥5 个时）
- phase_history 压缩（≥10 条时）

---

## [1.3.0] - 2026-01-15

### ✨ 新增功能
- 初始版本发布
- 6 阶段 SDLC 流程
- 14 个 Hooks
- 4 个 Skills
- 3 个自定义 Agent

