#!/usr/bin/env node
'use strict';

const path = require('path');
const { install, uninstall } = require('../lib/installer');

const pkg = require('../package.json');

// 颜色
const C = '\x1b[36m', B = '\x1b[1m', D = '\x1b[2m', R = '\x1b[0m';
const M = '\x1b[35m', BL = '\x1b[34m', G = '\x1b[32m', RD = '\x1b[31m';

const HELP = `
    ${C}┌─────┐${R}
   ${C}┌┘${R} ${D}P1→P2${R} ${C}└┐${R}     ${C}${B}claude-sdlc${R} ${D}v${pkg.version}${R}
   ${M}│${R} ${D}↑${R} ${G}✔${R}  ${D}↓${R} ${BL}│${R}     ${D}SDLC Enforcer for Claude Code${R}
   ${M}│${R} ${D}P6  P3${R} ${BL}│${R}     ${D}by 沐谦${R}
   ${M}└┐${R} ${D}P5←P4${R} ${BL}┌┘${R}
    ${BL}└──▽──┘${R}

  ${B}用法${R}
    claude-sdlc ${D}[目标路径]${R}              安装到目标项目
    claude-sdlc uninstall ${D}[目标路径]${R}    卸载全部 SDLC 文件
    claude-sdlc --help                  显示帮助
    claude-sdlc --version               显示版本

  ${B}示例${R}
    ${C}$${R} npx claude-sdlc                     ${D}# 安装到当前目录${R}
    ${C}$${R} npx claude-sdlc ./myapp             ${D}# 安装到指定目录${R}
    ${C}$${R} npx claude-sdlc uninstall           ${D}# 从当前目录卸载${R}
    ${C}$${R} npx claude-sdlc uninstall ./myapp   ${D}# 从指定目录卸载${R}
`.trimEnd();

const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
  console.log(HELP);
  process.exit(0);
}

if (args.includes('--version') || args.includes('-v')) {
  console.log(pkg.version);
  process.exit(0);
}

if (args[0] === 'uninstall') {
  const targetArg = args[1] || '.';
  const targetDir = path.resolve(targetArg);
  uninstall(targetDir);
} else {
  const targetArg = args[0] || '.';
  const targetDir = path.resolve(targetArg);
  install(targetDir);
}
