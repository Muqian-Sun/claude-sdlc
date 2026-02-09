# npm 发布指南

## 📋 发布前检查清单

### ✅ 已完成
- [x] package.json 版本号更新（1.8.0）
- [x] Git 代码已推送
- [x] Git Tag 已创建（v1.8.0）
- [x] 发布文档已准备
- [x] 质量测试通过（98/100）
- [x] 兼容性测试通过（100/100）
- [x] package.json 配置完善

### ⬜ 待完成
- [x] npm 登录
- [x] npm 发布
- [x] 发布验证

**发布成功**：claude-sdlc@1.8.0 已成功发布到 npm！
- npm 页面：https://www.npmjs.com/package/claude-sdlc
- 发布时间：2025-02-09
- 状态：✅ 公开可用

---

## 🚀 发布步骤

### 步骤 1：登录 npm

```bash
cd /Users/muqian/Downloads/projects/插件/Claude\ code\ 软件工程开发规范/sdlc-enforcer

# 登录 npm（如果还没有账号，会自动引导注册）
npm login
```

**交互提示**：
1. Username: 输入您的 npm 用户名
2. Password: 输入密码
3. Email: 输入邮箱（公开）
4. OTP (可选): 如果启用了双因素认证，输入验证码

**验证登录**：
```bash
npm whoami
```

应该显示您的 npm 用户名。

---

### 步骤 2：预检查（重要）

#### 2.1 检查包名是否可用

```bash
npm view claude-sdlc
```

**预期结果**：
- 如果包不存在：`npm error code E404` - ✅ 可以发布
- 如果包已存在：显示包信息 - ⚠️ 需要检查是否是您的包

#### 2.2 检查将要发布的文件

```bash
npm pack --dry-run
```

这会显示将要包含在包中的所有文件。

**预期包含**：
- ✅ bin/
- ✅ lib/
- ✅ template/
- ✅ plugin.json
- ✅ README.md
- ✅ LICENSE
- ✅ package.json

**不应包含**：
- ❌ node_modules/
- ❌ .git/
- ❌ tests/
- ❌ *.log

---

### 步骤 3：发布到 npm

#### 3.1 首次发布（公开包）

```bash
npm publish --access public
```

**注意**：
- `--access public` 确保包是公开的（免费账号必需）
- 发布过程需要几秒到几分钟

#### 3.2 如果包名已被占用

如果 `claude-sdlc` 已被占用，可以选择：

**方案 A：使用作用域包名**
```bash
# 修改 package.json 中的 name 为 @your-username/claude-sdlc
npm publish --access public
```

**方案 B：使用其他包名**
```bash
# 修改 package.json 中的 name 为 claude-sdlc-enforcer
npm publish --access public
```

---

### 步骤 4：发布验证

#### 4.1 查看发布的包

```bash
npm view claude-sdlc
```

应该显示：
- ✅ version: 1.8.0
- ✅ description: 让 Claude Code 严格按 SDLC 规范开发
- ✅ repository, keywords, etc.

#### 4.2 测试安装

```bash
# 在临时目录测试安装
cd /tmp
npm install -g claude-sdlc@1.8.0

# 验证命令可用
claude-sdlc --version

# 清理（可选）
npm uninstall -g claude-sdlc
```

---

## 📊 发布后操作

### 1. 更新 README.md

在项目 README 中添加 npm 徽章：

```markdown
[![npm version](https://badge.fury.io/js/claude-sdlc.svg)](https://www.npmjs.com/package/claude-sdlc)
[![npm downloads](https://img.shields.io/npm/dm/claude-sdlc.svg)](https://www.npmjs.com/package/claude-sdlc)
```

### 2. 更新安装说明

```markdown
## 安装

### npm 安装（推荐）
\`\`\`bash
npm install -g claude-sdlc@1.8.0
\`\`\`

### GitHub 安装
\`\`\`bash
npm install -g https://github.com/Muqian-Sun/claude-sdlc.git#v1.8.0
\`\`\`
```

### 3. 创建 GitHub Release

1. 访问：https://github.com/Muqian-Sun/claude-sdlc/releases/new
2. Tag: v1.8.0
3. Title: v1.8.0 - 保质减负，高效开发
4. Description: 复制 RELEASE-v1.8.0.md 的内容
5. 发布

### 4. 通知用户

- 发布公告到社交媒体
- 通知现有用户升级
- 更新文档链接

---

## ⚠️ 常见问题

### 问题 1：npm 登录失败

**症状**：`npm error code ENEEDAUTH`

**解决方案**：
```bash
npm logout
npm login
```

### 问题 2：包名已被占用

**症状**：`npm error code E403 (Forbidden)`

**解决方案**：
- 检查是否是您的包：`npm view claude-sdlc`
- 如果不是，使用作用域包名：`@your-username/claude-sdlc`
- 或使用其他包名：`claude-sdlc-enforcer`

### 问题 3：版本号冲突

**症状**：`npm error code E403 (cannot publish over existing version)`

**解决方案**：
```bash
# 1. 检查当前版本
npm view claude-sdlc versions

# 2. 更新版本号
npm version patch  # 1.8.0 -> 1.8.1
# 或
npm version minor  # 1.8.0 -> 1.9.0
# 或
npm version major  # 1.8.0 -> 2.0.0

# 3. 重新发布
npm publish --access public
```

### 问题 4：发布后无法安装

**症状**：`npm error code E404`

**解决方案**：
```bash
# 等待 npm registry 同步（通常 1-5 分钟）
# 然后重试
npm install -g claude-sdlc@1.8.0
```

### 问题 5：文件缺失

**症状**：安装后缺少文件

**解决方案**：
```bash
# 1. 检查 package.json 的 files 字段
# 2. 使用 npm pack --dry-run 预览
# 3. 更新 files 字段
# 4. 提升版本号并重新发布
```

---

## 🔒 安全注意事项

### 发布前检查

1. ✅ 确保没有包含敏感信息
   - 无 .env 文件
   - 无私钥
   - 无 API 密钥

2. ✅ 检查 .npmignore 或 package.json files 字段
   - 排除测试文件
   - 排除开发配置

3. ✅ 启用双因素认证（2FA）
   ```bash
   npm profile enable-2fa auth-and-writes
   ```

### 发布后监控

1. 定期检查包的下载量
2. 关注 security alerts
3. 及时更新依赖

---

## 📈 包统计

发布后，可以在以下位置查看统计：

- **npm 页面**：https://www.npmjs.com/package/claude-sdlc
- **GitHub 统计**：https://github.com/Muqian-Sun/claude-sdlc
- **npm trends**：https://npmtrends.com/claude-sdlc

---

## 🎯 成功标志

发布成功后，您应该能够：

1. ✅ 在 npm 搜索到包：https://www.npmjs.com/package/claude-sdlc
2. ✅ 全局安装：`npm install -g claude-sdlc@1.8.0`
3. ✅ 运行命令：`claude-sdlc --version`
4. ✅ 查看信息：`npm view claude-sdlc`

---

## 📞 需要帮助？

如果遇到问题：
1. 查看 npm 文档：https://docs.npmjs.com/
2. 提交 Issue：https://github.com/Muqian-Sun/claude-sdlc/issues
3. 联系 npm 支持：https://www.npmjs.com/support

---

**准备好了吗？开始发布吧！** 🚀

```bash
cd /Users/muqian/Downloads/projects/插件/Claude\ code\ 软件工程开发规范/sdlc-enforcer
npm login
npm publish --access public
```
