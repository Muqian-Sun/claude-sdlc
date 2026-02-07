# 测试标准

本规范适用于 P4（测试验证）阶段的所有测试活动。

---

## 1. 测试原则

- **先写测试再修 bug**：修复 bug 前先写能复现该 bug 的测试
- **测试独立性**：每个测试用例必须独立，不依赖其他测试的执行顺序或结果
- **测试可重复性**：在任何环境下多次运行结果一致
- **测试可读性**：测试本身就是最好的文档

---

## 2. AAA 模式

所有测试用例必须遵循 Arrange-Act-Assert (AAA) 模式：

```
// Arrange — 准备测试数据和环境
const user = createTestUser({ name: "Alice", role: "admin" });

// Act — 执行被测试的操作
const result = await authService.login(user.email, user.password);

// Assert — 验证结果
expect(result.success).toBe(true);
expect(result.token).toBeDefined();
```

### AAA 规则
- 每个部分用空行分隔
- Assert 部分只验证一个逻辑概念（可以有多个 assert 语句）
- Arrange 部分使用工厂函数或 fixture，避免大量重复设置代码

---

## 3. 测试命名

### 格式
```
test("[被测对象] should [预期行为] when [条件]")
```

### 示例
```
test("UserService should return null when user not found")
test("calculateTotal should apply discount when order exceeds 100")
test("LoginForm should display error when password is empty")
```

### 原则
- 从测试名就能理解测试的目的
- 不使用 "test1", "test2" 这样无意义的名称
- 使用 should/when 句式保持一致性

---

## 4. 各阶段测试要求

### P4 必须完成的测试

| 测试类型 | 要求 | 说明 |
|---------|------|------|
| 单元测试 | 必须 | 覆盖所有新增/修改的公共函数 |
| 边界测试 | 必须 | 空值、极值、边界条件 |
| 错误路径测试 | 必须 | 异常输入、错误处理分支 |
| 集成测试 | 视情况 | 涉及多模块交互时需要 |
| E2E 测试 | 视情况 | 涉及用户交互流程时需要 |

### 覆盖率要求
- 新增代码行覆盖率 ≥ 80%
- 关键业务逻辑覆盖率 ≥ 90%
- 分支覆盖率 ≥ 70%

---

## 5. 测试代码规范

### 测试数据
- 使用有意义的测试数据，避免 "foo", "bar", "test123"
- 使用工厂函数或 builder 模式创建测试数据
- 敏感数据使用 faker/fixture 生成

### Mock 规范
- 只 mock 外部依赖（数据库、API、文件系统）
- 不 mock 被测模块的内部实现
- Mock 数据应尽可能接近真实数据的结构
- 测试结束后清理 mock 状态

### 测试文件组织
- 测试文件与源文件放在相同目录或 `__tests__/` 目录下
- 测试文件命名：`[源文件名].test.[ext]` 或 `[源文件名]_test.[ext]`
- 相关测试用例用 describe/context 分组

---

## 6. 测试执行检查清单

在 P4 阶段完成后，确认以下事项：

- [ ] 所有新增功能都有对应测试
- [ ] 所有测试通过（零失败）
- [ ] 测试覆盖了正常路径和错误路径
- [ ] 边界条件已覆盖
- [ ] 测试可独立运行、可重复执行
- [ ] 无被跳过(skip)的测试（除非有明确原因并记录）
- [ ] 测试执行时间合理（单元测试 < 30s）
