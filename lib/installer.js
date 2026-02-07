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

function hookGroupKey(group) {
  if (group.hooks && Array.isArray(group.hooks)) {
    return group.hooks.map(h => h.command || h.prompt).join('|');
  }
  return group.command || group.prompt || JSON.stringify(group);
}

function mergeSettings(existing, template) {
  const hookTypes = ['PreToolUse', 'PostToolUse', 'Stop', 'PreCompact'];
  const result = JSON.parse(JSON.stringify(existing));

  for (const type of hookTypes) {
    const existingHooks = result.hooks?.[type] || [];
    const newHooks = template.hooks?.[type] || [];

    const merged = [...existingHooks];
    const existingKeys = new Set(existingHooks.map(hookGroupKey));

    for (const hook of newHooks) {
      const key = hookGroupKey(hook);
      if (!existingKeys.has(key)) {
        merged.push(hook);
        existingKeys.add(key);
      }
    }

    if (!result.hooks) result.hooks = {};
    result.hooks[type] = merged;
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
  const STEPS = 6;

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

  // Step 1: CLAUDE.md
  step(1, STEPS, '安装核心控制文件');
  fs.copyFileSync(
    path.join(templateDir, 'CLAUDE.md'),
    path.join(targetDir, 'CLAUDE.md')
  );
  fileLog(SYM.check, 'CLAUDE.md');

  // Step 2: 目录结构
  step(2, STEPS, '创建目录结构');
  const dirs = ['rules', 'hooks', 'commands', 'reviews'];
  for (const dir of dirs) {
    fs.mkdirSync(path.join(targetDir, '.claude', dir), { recursive: true });
    fileLog(SYM.check, `.claude/${dir}/`);
  }

  // Step 3: 规则文件
  step(3, STEPS, '安装规则文件');
  const rules = copyFilesQuiet(
    path.join(templateDir, '.claude', 'rules'),
    path.join(targetDir, '.claude', 'rules'),
    '.md'
  );
  fileLog(SYM.check, `${rules.length} 个规则文件`);

  // Step 4: Hook 脚本
  step(4, STEPS, '安装 Hook 脚本');
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

  // Step 5: 斜杠命令
  step(5, STEPS, '安装斜杠命令');
  const cmds = copyFilesQuiet(
    path.join(templateDir, '.claude', 'commands'),
    path.join(targetDir, '.claude', 'commands'),
    '.md'
  );
  fileLog(SYM.check, `${cmds.length} 个命令 — ${DIM}/phase /status /checkpoint /review${RESET}`);

  // Step 6: settings.json
  step(6, STEPS, '配置 Hooks');
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
  console.log(`  ${DIM}已安装 ${rules.length + hookCount + cmds.length + 2} 个文件：${RESET}`);
  blank();
  console.log(`  ${BOLD}${path.basename(targetDir)}/${RESET}`);
  console.log(`  ${SYM.tee} CLAUDE.md              ${DIM}核心控制文件${RESET}`);
  console.log(`  ${SYM.corner} ${BOLD}.claude/${RESET}`);
  console.log(`     ${SYM.tee} settings.json       ${DIM}Hooks 配置${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}rules/${RESET}              ${DIM}${rules.length} 个规则 (自动加载)${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}hooks/${RESET}              ${DIM}${hookCount} 个拦截脚本${RESET}`);
  console.log(`     ${SYM.tee} ${BOLD}commands/${RESET}           ${DIM}${cmds.length} 个斜杠命令${RESET}`);
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

  const removed = [];

  // CLAUDE.md
  const claudeMd = path.join(targetDir, 'CLAUDE.md');
  if (fs.existsSync(claudeMd)) {
    fs.unlinkSync(claudeMd);
    removed.push('CLAUDE.md');
    fileLog(SYM.check, `${DIM}删除${RESET} CLAUDE.md`);
  }

  // .claude 子目录
  const removeDirs = ['rules', 'hooks', 'commands', 'reviews'];
  for (const dir of removeDirs) {
    const dirPath = path.join(targetDir, '.claude', dir);
    if (fs.existsSync(dirPath)) {
      const count = fs.readdirSync(dirPath).length;
      fs.rmSync(dirPath, { recursive: true });
      removed.push(`.claude/${dir}/`);
      fileLog(SYM.check, `${DIM}删除${RESET} .claude/${dir}/ ${DIM}(${count} 个文件)${RESET}`);
    }
  }

  // settings.json
  const settingsPath = path.join(targetDir, '.claude', 'settings.json');
  if (fs.existsSync(settingsPath)) {
    try {
      const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf-8'));
      if (settings.hooks) {
        delete settings.hooks;
      }
      if (Object.keys(settings).length === 0) {
        fs.unlinkSync(settingsPath);
        removed.push('settings.json');
        fileLog(SYM.check, `${DIM}删除${RESET} .claude/settings.json`);
      } else {
        fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n', 'utf-8');
        removed.push('settings.json (hooks)');
        fileLog(SYM.check, `${DIM}清理${RESET} settings.json ${DIM}(仅移除 hooks，保留其他配置)${RESET}`);
      }
    } catch (_) {
      fs.unlinkSync(settingsPath);
      removed.push('settings.json');
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

  if (removed.length > 0) {
    resultBanner(`卸载完成 — 已清理 ${removed.length} 项`);
    console.log(`  ${DIM}重新安装：npx claude-sdlc${RESET}`);
  } else {
    blank();
    console.log(`  ${SYM.warn} 未找到 SDLC Enforcer 安装的文件`);
  }
  blank();
}

module.exports = { install, uninstall, mergeSettings };
