# UI/UX 设计规范

**强制要求**：所有涉及 UI 的项目必须使用 **ui-ux-pro-max** skill。

---

## 核心原则

| 原则 | 说明 |
|------|------|
| **现代优先** | ❌ Bootstrap 3/4、jQuery UI、90年代表格 &nbsp; ✅ shadcn/ui、Radix、Ant Design 5+ |
| **设计系统驱动** | 从 67 风格+96 配色+57 字体中选择（禁止随意配色） |
| **可访问性** | WCAG 2.1 AA（对比度≥4.5:1、键盘导航、ARIA） |
| **响应式** | 移动优先，测试 375px/768px/1440px |
| **性能** | Core Web Vitals（LCP<2.5s、CLS<0.1） |

---

## P1 — UI 调研与设计（强制流程）

### 1. 调研（使用 ui-ux-pro-max + WebSearch）

```
WebSearch: "{框架} modern UI 2026" + "{产品类型} best practices 2026"
自动激活: 说"设计XX"或"创建XX组件"时
```

**推荐组件库**：
- React: shadcn/ui、Radix UI、Ant Design 5、MUI 6
- Vue: Nuxt UI、Headless UI、PrimeVue 4
- Svelte: shadcn-svelte、Melt UI

### 2. 设计系统生成（基于 ui-ux-pro-max）

必须包含：
- 风格（67 选 1）：glassmorphism、minimalism、brutalism 等
- 配色（96 选 1）：具体方案名称，如 "SaaS-Blue-Professional"
- 字体（57 选 1）：标题+正文配对，如 "Poppins + Inter"
- 间距：4px/8px/16px/24px/32px/48px
- 组件库：shadcn/ui 等

### 3. 原型实现（Chrome 展示）

- ✅ Flexbox/Grid、CSS Variables、Modern 伪类
- ✅ 应用设计系统（配色+字体+间距）
- ✅ 包含 hover/focus/active 状态
- ✅ 测试响应式（375px/768px/1440px）
- ❌ float 布局、table 布局（数据表格除外）

### 4. PRD 必须包含

```yaml
ui_design:
  style: "glassmorphism"
  colors: "SaaS-Blue-Professional"
  fonts: {heading: "Poppins", body: "Inter"}
  components: "shadcn/ui"
  prototype: "/tmp/prototype-{timestamp}.html"
```

---

## P2 — 实现规范

### 强制要求

| 规范 | 说明 |
|------|------|
| 遵循原型 | 严格按 P1 原型，配色/字体/间距不得擅自修改 |
| 组件化 | 可复用元素提取为组件 |
| CSS 组织 | CSS Modules/Tailwind/Styled-components |
| 主题支持 | CSS Variables，支持浅色/深色模式 |
| SVG 图标 | Lucide/Heroicons/Phosphor（❌ emoji） |

### 禁止实现

| ❌ 禁止 | ✅ 替代 |
|--------|--------|
| 大量内联 `style={{}}` | CSS Modules/Tailwind |
| 固定像素 `width: 300px` | 响应式 `max-width: 100%` |
| `!important` | 合理 CSS 优先级 |
| 硬编码颜色 `#3b82f6` | `var(--color-primary)` |
| jQuery 操作 DOM | 框架状态管理 |

### 可访问性（强制）

- [ ] 交互元素 ≥44x44px
- [ ] 对比度 ≥4.5:1（文本）
- [ ] 键盘导航可用（Tab 顺序正确）
- [ ] 表单 `<label>` + `for`
- [ ] 图片 `alt`、图标按钮 `aria-label`
- [ ] 支持 `prefers-reduced-motion`

---

## P3 — 测试要求

| 测试类型 | 工具 | 要求 |
|---------|------|------|
| 视觉回归 | Playwright screenshot | 主要页面/组件 |
| 响应式 | 3 断点测试 | 375/768/1440px |
| 可访问性 | axe-core/Lighthouse | 0 critical 违规 |
| 交互 | Testing Library/Playwright | 所有用户流程 |
| 性能 | Lighthouse CI | LCP<2.5s, CLS<0.1 |

**示例测试**：
```typescript
// 可访问性（必须）
test('form is accessible', async () => {
  const { container } = render(<Form />)
  expect(await axe(container)).toHaveNoViolations()
})

// 响应式（必须）
test('responsive layout', async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 667 })
  await expect(page.locator('[data-mobile]')).toBeVisible()
})
```

---

## P4 — 审查清单

### 设计系统一致性
- [ ] 配色来自 PRD 定义，无随意颜色
- [ ] 字体使用 PRD 定义的配对
- [ ] 间距遵循 4px/8px 倍数
- [ ] 圆角/阴影统一

### 现代性检查
- [ ] 使用现代组件库（shadcn/ui、Radix、Ant Design 5+）
- [ ] 无 Bootstrap 3/jQuery UI/90 年代风格
- [ ] 有 hover/focus/active 状态
- [ ] 过渡动画 150-300ms

### 可访问性审查（工具）

```bash
# Lighthouse
npx lighthouse http://localhost:3000 --only-categories=accessibility

# axe-core
npx @axe-core/cli http://localhost:3000
```

**通过标准**：
- Lighthouse 可访问性 ≥90
- axe-core 0 个 critical/serious 违规

### 性能审查

```bash
npx lighthouse http://localhost:3000 --only-categories=performance
```

**通过标准**：
- LCP < 2.5s
- FID < 100ms
- CLS < 0.1

### 响应式审查

**必测断点**：375px、768px、1440px

**检查项**：
- [ ] 内容不溢出
- [ ] 触摸目标 ≥44px
- [ ] 移动端字体 ≥16px
- [ ] 图片响应式（srcset）

---

## 审查失败处理

| 级别 | 定义 | 处理 |
|------|------|------|
| 🔴 阻断 | 可访问性 critical、无响应式、性能<50 | 回退 P2 |
| 🟡 严重 | 风格不符、配色错误 | 修复后重审 |
| 🟢 建议 | 动画优化 | 记录 TODO |

**自动修复**：先修阻断问题 → 批量修复同类 → 重审（最多 3 次）

---

## 必装工具

```bash
npm install -D @axe-core/cli @axe-core/react lighthouse @playwright/test
```

---

## ui-ux-pro-max 数据库

- `styles.csv` - 67 种 UI 风格
- `colors.csv` - 96 个配色方案
- `typography.csv` - 57 种字体配对
- `ux-guidelines.csv` - 99 条 UX 指南
- `charts.csv` - 25 种图表类型

---

## 执行检查

### P1（设计）
- [ ] 使用 ui-ux-pro-max skill 调研
- [ ] PRD 包含 `ui_design` 字段
- [ ] 原型在 Chrome 展示
- [ ] 配色来自 96 方案之一

### P2（实现）
- [ ] 严格按原型实现
- [ ] 使用现代组件库
- [ ] 通过可访问性检查清单
- [ ] 无 Bootstrap 3/jQuery

### P4（审查）
- [ ] Lighthouse 可访问性 ≥90
- [ ] axe-core 0 违规
- [ ] 响应式测试通过
- [ ] Core Web Vitals 达标
- [ ] 设计系统一致性

