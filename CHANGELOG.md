# Changelog

## [1.10.0] - 2026-02-11

### 🎯 重大改进
- **P1 流程优化**：增加需求澄清环节，避免基于假设开发
  - 新增多轮对话机制：系统性获取功能范围、优先级、技术约束、UI偏好
  - 流程重构：需求澄清 → 技术调研 → PRD 确认 → 架构设计 → 原型设计
  - 两个检查点：PRD 确认（第一检查点）+ 设计确认（第二检查点）
  - 新增 `requirements_clarification` 临时字段，确认后转化为 PRD

### ✨ 新增功能
- **需求澄清模板**：AskUserQuestion 系统性提问清单
  - 功能范围和优先级
  - 目标用户和使用场景
  - 技术约束和非功能需求
  - UI/UX 偏好（如涉及界面）
  - 数据和集成需求

### 🚀 流程改进
- **PRD 质量提升**：基于充分的需求澄清和调研，减少返工
- **架构合理性**：架构设计基于已确认的 PRD，不再偏离需求
- **原型准确性**：原型基于 PRD 和架构，设计与需求保持一致
- **顺序优化**：PRD 确认 → 架构设计 → 原型设计，每步基于前一步确认结果

### 📝 文档更新
- 更新 `01-lifecycle-phases.md`：详细的 P1 五步流程
- 更新 `CLAUDE.md`：强调需求澄清和两个检查点
- 更新 `project-state.md`：增加 requirements_clarification 字段
- 更新 `README.md`：新的工作流程图
- 新增 `CHANGELOG-v1.10.0.md`：完整的变更说明和使用示例

### 🎨 用户体验
- 减少因需求不明导致的返工
- 用户在 PRD 和设计阶段都有明确的确认点
- 开发过程更透明，用户更有掌控感

---

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

