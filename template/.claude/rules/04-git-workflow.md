# Git 工作流规范

## 分支命名

```
feature/<简短描述>    # 新功能
fix/<简短描述>        # Bug 修复
refactor/<简短描述>   # 重构
docs/<简短描述>       # 文档更新
test/<简短描述>       # 测试补充
```

从最新 main/master 创建，小写字母+连字符。

---

## Git 操作安全规则

| 类别 | 操作 | 说明 |
|------|------|------|
| ❌ 禁止 | `push --force`(main/master), `reset --hard`, `clean -f`, `branch -D` | 除非用户明确要求 |
| ⚠️ 需确认 | `push`(首次), `merge`(到main), `rebase` | 向用户确认后执行 |
| ✅ 安全 | `status`, `diff`, `log`, `branch`(查看), `stash` | 可自由执行 |

---

## 冲突解决

- 优先 `git merge`，保留完整历史
- 逐文件解决，保留双方有效改动，不丢弃他人工作
- 解决后运行测试验证无回归
- 复杂冲突向用户确认后再提交
