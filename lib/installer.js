'use strict';

const fs = require('fs');
const path = require('path');

// ── 颜色 & 样式 ──────────────────────────────────────
const RESET   = '\x1b[0m';
const BOLD    = '\x1b[1m';
const DIM     = '\x1b[2m';
const RED     = '\x1b[31m';
const GREEN   = '\x1b[32m';
const YELLOW  = '\x1b[33m';
const BLUE    = '\x1b[34m';
const MAGENTA = '\x1b[35m';
const CYAN    = '\x1b[36m';
const WHITE   = '\x1b[37m';
const BG_GREEN = '\x1b[42m';
const BG_RED   = '\x1b[41m';

// ── 符号 ──────────────────────────────────────────────
const SYM = {
  check:  `${GREEN}✔${RESET}`,
  cross:  `${RED}✘${RESET}`,
  warn:   `${YELLOW}⚠${RESET}`,
  arrow:  `${CYAN}▸${RESET}`,
  dot:    `${DIM}·${RESET}`,
  bar:    `${DIM}│${RESET}`,
  corner: `${DIM}└─${RESET}`,
  tee:    `${DIM}├─${RESET}`,
};

// ── 输出函数 ──────────────────────────────────────────
function step(num, total, msg) {
  console.log(`  ${DIM}[${num}/${total}]${RESET} ${msg}`);
}

function fileLog(symbol, filePath) {
  console.log(`        ${symbol} ${filePath}`);
}

function blank() { console.log(''); }

function asciiLogo(mode = 'install') {
  const ver = require('../package.json').version;
  const c1 = CYAN, c2 = BLUE, c3 = MAGENTA, c4 = GREEN;
  const accent = mode === 'install' ? CYAN : RED;
  blank();
  console.log(`    ${c1}┌─────┐${RESET}`);
  console.log(`   ${c1}┌┘${RESET} ${DIM}P1→P2${RESET} ${c1}└┐${RESET}    ${accent}${BOLD}claude-sdlc${RESET} ${DIM}v${ver}${RESET}`);
  console.log(`   ${c3}│${RESET} ${DIM}↑${RESET} ${c4}✔${RESET}  ${DIM}↓${RESET} ${c2}│${RESET}    ${DIM}SDLC Enforcer for Claude Code${RESET}`);
  console.log(`   ${c3}│${RESET} ${DIM}P6  P3${RESET} ${c2}│${RESET}    ${DIM}by 沐谦${RESET}`);
  console.log(`   ${c3}└┐${RESET} ${DIM}P5←P4${RESET} ${c2}┌┘${RESET}`);
  console.log(`    ${c2}└──▽──┘${RESET}`);
  blank();
}

function banner(title, color = CYAN) {
  const line = '─'.repeat(44);
  blank();
  console.log(`  ${color}${BOLD}┌${line}┐${RESET}`);
  console.log(`  ${color}${BOLD}│${RESET}  ${color}${BOLD}${title.padEnd(42)}${RESET}${color}${BOLD}│${RESET}`);
  console.log(`  ${color}${BOLD}└${line}┘${RESET}`);
  blank();
}

function resultBanner(text, ok = true) {
  const color = ok ? GREEN : RED;
  const bg = ok ? BG_GREEN : BG_RED;
  const icon = ok ? ' ✔ ' : ' ✘ ';
  blank();
  console.log(`  ${bg}${BOLD}${WHITE}${icon}${text} ${RESET}`);
  blank();
}

// ── 工具函数 ──────────────────────────────────────────

/**
 * 获取 hook 组的 matcher 标识（用于按 matcher 匹配升级，而非按内容去重）
 */
function hookMatcherKey(group) {
  return group.matcher || '';
}

function mergeSettings(existing, template) {
  const hookTypes = ['PreToolUse', 'PostToolUse', 'PostToolUseFailure',
                     'Stop', 'PreCompact',
                     'SessionStart', 'SessionEnd', 'UserPromptSubmit',
                     'SubagentStart', 'SubagentStop', 'TaskCompleted',
                     'PermissionRequest'];
  const result = JSON.parse(JSON.stringify(existing));

  // 合并 $schema
  if (template.$schema && !result.$schema) {
    result.$schema = template.$schema;
  }

  for (const type of hookTypes) {
    const existingHooks = result.hooks?.[type] || [];
    const templateHooks = template.hooks?.[type] || [];

    // 按 matcher 建立模板 hook 索引
    const templateByMatcher = new Map();
    for (const hook of templateHooks) {
      templateByMatcher.set(hookMatcherKey(hook), hook);
    }

    const merged = [];
    const processedMatchers = new Set();

    // 遍历已有 hooks：模板有同 matcher → 替换为模板版本；模板没有 → 保留（用户自定义）
    for (const hook of existingHooks) {
      const mk = hookMatcherKey(hook);
      if (processedMatchers.has(mk)) continue;
      processedMatchers.add(mk);

      if (templateByMatcher.has(mk)) {
        merged.push(JSON.parse(JSON.stringify(templateByMatcher.get(mk))));
      } else {
        merged.push(hook);
      }
    }

    // 追加模板中新增的 hooks（已有中没有的 matcher）
    for (const hook of templateHooks) {
      const mk = hookMatcherKey(hook);
      if (!processedMatchers.has(mk)) {
        processedMatchers.add(mk);
        merged.push(JSON.parse(JSON.stringify(hook)));
      }
    }

    if (!result.hooks) result.hooks = {};
    result.hooks[type] = merged;
  }

  // 合并 statusLine：模板有 statusLine 且用户没有 → 添加
  if (template.statusLine && !result.statusLine) {
    result.statusLine = JSON.parse(JSON.stringify(template.statusLine));
  }

  // 合并 permissions：模板的 allow/deny/ask 规则追加到用户已有列表（去重）
  if (template.permissions) {
    if (!result.permissions) result.permissions = {};
    for (const key of ['allow', 'deny', 'ask']) {
      const templateRules = template.permissions[key] || [];
      const existingRules = result.permissions[key] || [];
      const merged = [...new Set([...existingRules, ...templateRules])];
      if (merged.length > 0) {
        result.permissions[key] = merged;
      }
    }
    // 合并 permissions.defaultMode
    if (template.permissions.defaultMode && !result.permissions.defaultMode) {
      result.permissions.defaultMode = template.permissions.defaultMode;
    }
  }

  // 合并新增标量字段（模板有、用户没有 → 复制）
  const newFields = ['sandbox', 'env', 'attribution', 'fileSuggestion', 'spinnerVerbs', 'language'];
  for (const field of newFields) {
    if (template[field] !== undefined && result[field] === undefined) {
      result[field] = JSON.parse(JSON.stringify(template[field]));
    }
  }

  return result;
}

function copyFilesQuiet(srcDir, destDir, ext) {
  if (!fs.existsSync(srcDir)) return [];
  const files = fs.readdirSync(srcDir).filter(f => f.endsWith(ext));
  for (const file of files) {
    fs.copyFileSync(path.join(srcDir, file), path.join(destDir, file));
  }
  return files;
}

// ── 安装 ──────────────────────────────────────────────

function install(targetDir) {
  const templateDir = path.join(__dirname, '..', 'template');
  const STEPS = 9;

  // 验证
  if (!fs.existsSync(targetDir)) {
    console.error(`\n  ${SYM.cross} 目标目录不存在：${targetDir}\n`);
    process.exit(1);
  }
  if (!fs.statSync(targetDir).isDirectory()) {
    console.error(`\n  ${SYM.cross} 目标路径不是目录：${targetDir}\n`);
    process.exit(1);
  }
  if (!fs.existsSync(templateDir)) {
    console.error(`\n  ${SYM.cross} 找不到 template 目录：${templateDir}\n`);
    process.exit(1);
  }

  asciiLogo('install');

  const installLine = '─'.repeat(44);
  console.log(`  ${CYAN}${BOLD}┌${installLine}┐${RESET}`);
  console.log(`  ${CYAN}${BOLD}│${RESET}  ${CYAN}${BOLD}${'安 装'.padEnd(41)}${RESET}${CYAN}${BOLD}│${RESET}`);
  console.log(`  ${CYAN}${BOLD}└${installLine}┘${RESET}`);
  blank();
  console.log(`  ${SYM.arrow} 目标  ${BOLD}${targetDir}${RESET}`);
  blank();

  // Step 1: CLAUDE.md（纯控制指令，升级时直接替换为最新版本）
  step(1, STEPS, '安装核心控制文件');
  const targetClaudeMd = path.join(targetDir, 'CLAUDE.md');
  const templateClaudeMd = path.join(templateDir, 'CLAUDE.md');
  const templateContent = fs.readFileSync(templateClaudeMd, 'utf-8');
  const isUpgrade = fs.existsSync(targetClaudeMd);

  // v1.0.6→v1.0.7 迁移：旧版状态内嵌在 CLAUDE.md 中，需要提取出来
  let migratedState = null;
  if (isUpgrade) {
    const oldContent = fs.readFileSync(targetClaudeMd, 'utf-8');
    const yamlMatch = oldContent.match(/```yaml\n# === SDLC 项目状态 ===\n([\s\S]*?)```/);
    if (yamlMatch) {
      // 检查是否有实际数据（非空白模板）
      const yamlBlock = yamlMatch[0];
      const hasData = /current_phase:\s*P[1-6]/.test(yamlBlock)
        || /task_description:\s*"[^"]+"/.test(yamlBlock)
        || /modified_files:\s*\n\s*-/.test(yamlBlock)
        || /prd:\s*\n\s*-\s*id:/.test(yamlBlock);
      if (hasData) {
        migratedState = yamlBlock;
      }
    }
  }

  fs.writeFileSync(targetClaudeMd, templateContent, 'utf-8');
  fileLog(SYM.check, isUpgrade
    ? `CLAUDE.md ${DIM}(已更新至最新版本)${RESET}`
    : 'CLAUDE.md');

  // Step 2: 目录结构
  step(2, STEPS, '创建目录结构');
  const dirs = ['rules', 'hooks', 'commands', 'skills', 'reviews', 'agents'];
  for (const dir of dirs) {
    fs.mkdirSync(path.join(targetDir, '.claude', dir), { recursive: true });
    fileLog(SYM.check, `.claude/${dir}/`);
  }

  // Step 3: project-state.md（项目状态文件 — 已有则跳过，保护用户数据）
  step(3, STEPS, '初始化项目状态文件');
  const targetState = path.join(targetDir, '.claude', 'project-state.md');
  const templateState = path.join(templateDir, '.claude', 'project-state.md');
  if (fs.existsSync(targetState)) {
    fileLog(SYM.check, `.claude/project-state.md ${DIM}(已有状态，跳过保护)${RESET}`);
  } else if (migratedState) {
    // v1.0.6→v1.0.7 迁移：将旧 CLAUDE.md 中的状态写入新的 project-state.md
    const stateTemplate = fs.readFileSync(templateState, 'utf-8');
    const emptyYaml = stateTemplate.match(/```yaml\n# === SDLC 项目状态 ===\n[\s\S]*?```/);
    if (emptyYaml) {
      const migrated = stateTemplate.replace(emptyYaml[0], migratedState);
      fs.writeFileSync(targetState, migrated, 'utf-8');
    } else {
      fs.writeFileSync(targetState, stateTemplate, 'utf-8');
    }
    fileLog(SYM.warn, `.claude/project-state.md ${DIM}(从旧版 CLAUDE.md 迁移状态)${RESET}`);
  } else {
    fs.copyFileSync(templateState, targetState);
    fileLog(SYM.check, '.claude/project-state.md');
  }

  // Step 4: 规则文件
  step(4, STEPS, '安装规则文件');
  const rules = copyFilesQuiet(
    path.join(templateDir, '.claude', 'rules'),
    path.join(targetDir, '.claude', 'rules'),
    '.md'
  );
  fileLog(SYM.check, `${rules.length} 个规则文件`);

  // Step 5: Hook 脚本
  step(5, STEPS, '安装 Hook 脚本');
  const hooksSrcDir = path.join(templateDir, '.claude', 'hooks');
  const hooksDestDir = path.join(targetDir, '.claude', 'hooks');
  let hookCount = 0;
  if (fs.existsSync(hooksSrcDir)) {
    const hookFiles = fs.readdirSync(hooksSrcDir).filter(f => f.endsWith('.sh'));
    for (const file of hookFiles) {
      const destPath = path.join(hooksDestDir, file);
      fs.copyFileSync(path.join(hooksSrcDir, file), destPath);
      try { fs.chmodSync(destPath, 0o755); } catch (_) {}
      hookCount++;
    }
  }
  fileLog(SYM.check, `${hookCount} 个 Hook 脚本`);

  // Step 6: 斜杠命令
  step(6, STEPS, '安装斜杠命令');
  const cmds = copyFilesQuiet(
    path.join(templateDir, '.claude', 'commands'),
    path.join(targetDir, '.claude', 'commands'),
    '.md'
  );
  fileLog(SYM.check, `${cmds.length} 个命令 — ${DIM}/phase /status /checkpoint /review${RESET}`);

  // Step 7: Skills
  step(7, STEPS, '安装 Skills');
  const skillsSrcDir = path.join(templateDir, '.claude', 'skills');
  const skillsDestDir = path.join(targetDir, '.claude', 'skills');
  let skillCount = 0;
  if (fs.existsSync(skillsSrcDir)) {
    const skillDirs = fs.readdirSync(skillsSrcDir).filter(d =>
      fs.statSync(path.join(skillsSrcDir, d)).isDirectory()
    );
    for (const dir of skillDirs) {
      const destDir = path.join(skillsDestDir, dir);
      fs.mkdirSync(destDir, { recursive: true });
      const skillFile = path.join(skillsSrcDir, dir, 'SKILL.md');
      if (fs.existsSync(skillFile)) {
        fs.copyFileSync(skillFile, path.join(destDir, 'SKILL.md'));
        skillCount++;
      }
    }
  }
  fileLog(SYM.check, `${skillCount} 个 Skills — ${DIM}/phase /status /checkpoint /review${RESET}`);

  // Step 8: 自定义 Agents
  step(8, STEPS, '安装自定义 Agents');
  const agentsSrcDir = path.join(templateDir, '.claude', 'agents');
  const agentsDestDir = path.join(targetDir, '.claude', 'agents');
  let agentCount = 0;
  if (fs.existsSync(agentsSrcDir)) {
    const agentFiles = fs.readdirSync(agentsSrcDir).filter(f => f.endsWith('.md'));
    for (const file of agentFiles) {
      fs.copyFileSync(path.join(agentsSrcDir, file), path.join(agentsDestDir, file));
      agentCount++;
    }
  }
  fileLog(SYM.check, `${agentCount} 个 Agents — ${DIM}sdlc-coder, sdlc-tester, sdlc-reviewer${RESET}`);

  // Step 9: settings.json
  step(9, STEPS, '配置 Hooks + Permissions + Settings');
  const targetSettings = path.join(targetDir, '.claude', 'settings.json');
  const sourceSettings = path.join(templateDir, '.claude', 'settings.json');

  if (fs.existsSync(targetSettings)) {
    try {
      const existing = JSON.parse(fs.readFileSync(targetSettings, 'utf-8'));
      const template = JSON.parse(fs.readFileSync(sourceSettings, 'utf-8'));
      const merged = mergeSettings(existing, template);
      fs.writeFileSync(targetSettings, JSON.stringify(merged, null, 2) + '\n', 'utf-8');
      fileLog(SYM.check, `settings.json ${DIM}(智能合并，保留原有配置)${RESET}`);
    } catch (e) {
      fs.copyFileSync(sourceSettings, targetSettings);
      fileLog(SYM.warn, `settings.json ${DIM}(合并失败，已覆盖安装)${RESET}`);
    }
  } else {
    fs.copyFileSync(sourceSettings, targetSettings);
    fileLog(SYM.check, 'settings.json');
  }

  // 完成
  resultBanner('安装完成');

  // 文件树
  console.log(`  ${DIM}已安装 ${rules.length + hookCount + cmds.length + skillCount + agentCount + 3} 个文件：${RESET}`);
  blank();
  console.log(`  ${BOLD}${path.basename(targetDir)}/${RESET}`);
  console.log(`  ${SYM.tee} CLAUDE.md              ${DIM}核心控制文件（升级时自动更新）${RESET}`);
  console.log(`  ${SYM.corner} ${BOLD}.claude/${RESET}`);
  console.log(`     ${SYM.tee} project-state.md    ${DIM}项目状态（升级时保留）${RESET}`);
  console.log(`     ${SYM.tee} settings.json       ${DIM}Hooks + Permissions 配置${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}rules/${RESET}              ${DIM}${rules.length} 个规则 (自动加载)${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}hooks/${RESET}              ${DIM}${hookCount} 个拦截脚本${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}skills/${RESET}             ${DIM}${skillCount} 个 Skills${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}commands/${RESET}           ${DIM}${cmds.length} 个斜杠命令 (fallback)${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}agents/${RESET}            ${DIM}${agentCount} 个自定义 Agents${RESET}`);
  console.log(`     ${SYM.corner} ${BOLD}reviews/${RESET}           ${DIM}审查报告${RESET}`);
  blank();

  // 使用提示
  const line = '─'.repeat(44);
  console.log(`  ${DIM}${line}${RESET}`);
  console.log(`  ${CYAN}使用方法${RESET}`);
  console.log(`  ${DIM}${line}${RESET}`);
  blank();
  console.log(`  ${BOLD}1.${RESET} cd ${CYAN}${targetDir}${RESET}`);
  console.log(`  ${BOLD}2.${RESET} 启动 ${CYAN}claude${RESET} 即可自动加载 SDLC 规范`);
  console.log(`  ${BOLD}3.${RESET} 使用 ${CYAN}/phase${RESET}  查看当前阶段`);
  console.log(`  ${BOLD}4.${RESET} 使用 ${CYAN}/status${RESET} 查看项目状态`);
  blank();
  console.log(`  ${DIM}卸载：npx claude-sdlc uninstall${RESET}`);
  blank();
}

// ── 卸载 ──────────────────────────────────────────────

function uninstall(targetDir) {
  if (!fs.existsSync(targetDir)) {
    console.error(`\n  ${SYM.cross} 目标目录不存在：${targetDir}\n`);
    process.exit(1);
  }

  asciiLogo('uninstall');

  const uninstallLine = '─'.repeat(44);
  console.log(`  ${RED}${BOLD}┌${uninstallLine}┐${RESET}`);
  console.log(`  ${RED}${BOLD}│${RESET}  ${RED}${BOLD}${'卸 载'.padEnd(41)}${RESET}${RED}${BOLD}│${RESET}`);
  console.log(`  ${RED}${BOLD}└${uninstallLine}┘${RESET}`);
  blank();
  console.log(`  ${SYM.arrow} 目标  ${BOLD}${targetDir}${RESET}`);
  blank();

  let removed = 0;

  // CLAUDE.md
  const claudeMd = path.join(targetDir, 'CLAUDE.md');
  if (fs.existsSync(claudeMd)) {
    fs.unlinkSync(claudeMd);
    removed++;
    fileLog(SYM.check, `${DIM}删除${RESET} CLAUDE.md`);
  }

  // project-state.md
  const stateMd = path.join(targetDir, '.claude', 'project-state.md');
  if (fs.existsSync(stateMd)) {
    fs.unlinkSync(stateMd);
    removed++;
    fileLog(SYM.check, `${DIM}删除${RESET} .claude/project-state.md`);
  }

  // .claude 子目录（全部删除）
  const removeDirs = ['rules', 'hooks', 'commands', 'skills', 'reviews', 'agents'];
  for (const dir of removeDirs) {
    const dirPath = path.join(targetDir, '.claude', dir);
    if (fs.existsSync(dirPath)) {
      const count = fs.readdirSync(dirPath).length;
      fs.rmSync(dirPath, { recursive: true });
      removed++;
      fileLog(SYM.check, `${DIM}删除${RESET} .claude/${dir}/ ${DIM}(${count} 个文件)${RESET}`);
    }
  }

  // settings.json — 仅清理 SDLC hooks，保留用户其他配置
  const settingsPath = path.join(targetDir, '.claude', 'settings.json');
  if (fs.existsSync(settingsPath)) {
    try {
      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'));
      for (const key of ['hooks', 'statusLine', 'permissions', 'sandbox', 'env',
                          'attribution', 'fileSuggestion', 'spinnerVerbs', 'language']) {
        if (settings[key]) delete settings[key];
      }
      if (settings.$schema === 'https://json.schemastore.org/claude-code-settings.json') {
        delete settings.$schema;
      }
      if (Object.keys(settings).length === 0) {
        fs.unlinkSync(settingsPath);
        removed++;
        fileLog(SYM.check, `${DIM}删除${RESET} .claude/settings.json`);
      } else {
        fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n', 'utf-8');
        removed++;
        fileLog(SYM.check, `${DIM}清理${RESET} settings.json ${DIM}(仅移除 hooks，保留其他配置)${RESET}`);
      }
    } catch (_) {
      fs.unlinkSync(settingsPath);
      removed++;
      fileLog(SYM.check, `${DIM}删除${RESET} .claude/settings.json`);
    }
  }

  // 清理空 .claude 目录
  const claudeDir = path.join(targetDir, '.claude');
  if (fs.existsSync(claudeDir)) {
    const remaining = fs.readdirSync(claudeDir);
    if (remaining.length === 0) {
      fs.rmdirSync(claudeDir);
      fileLog(SYM.check, `${DIM}删除${RESET} .claude/ ${DIM}(空目录)${RESET}`);
    }
  }

  if (removed > 0) {
    resultBanner(`卸载完成 — 已清理 ${removed} 项`);
    console.log(`  ${DIM}重新安装：npx claude-sdlc${RESET}`);
  } else {
    blank();
    console.log(`  ${SYM.warn} 未找到 SDLC Enforcer 安装的文件`);
  }
  blank();
}

module.exports = { install, uninstall, mergeSettings };
