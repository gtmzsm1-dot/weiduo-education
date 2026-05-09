# 开发环境注意事项

## NODE_OPTIONS 冲突导致 playwright-cli 启动失败

### 问题描述
在 macOS 上运行 `playwright-cli open` 时出现以下错误：
```
node: --use-system-ca is not allowed in NODE_OPTIONS
```

### 原因
系统环境变量 `NODE_OPTIONS=--use-system-ca` 与 playwright-cli 的 node 版本冲突。

### 解决方案
在 playwright-cli 命令前临时清空 NODE_OPTIONS：
```bash
NODE_OPTIONS= playwright-cli open <url>
```

注意：不要修改环境变量文件，只需在运行 playwright-cli 时临时设置即可。

### 适用范围
- 如果是用 managed node（`/Users/chenck/.workbuddy/binaries/node/versions/22.12.0/bin/node`）运行，也可能有此问题
- 如果在其他机器上复现，检查 `echo $NODE_OPTIONS` 是否有值

### 适用范围

## playwright-cli 调用方式(2026-05-09 更新)

从阶段 2 开始，**所有 UI 验证一律走 wrapper**，不要再直接 `playwright-cli ...` 也不要手动加 `NODE_OPTIONS=`。

### 标准调用方式

```bash
# 从 repo 根目录执行
./scripts/playwright-cli.sh open http://localhost:8123/deploy/index.html?admin=1
./scripts/playwright-cli.sh snapshot
./scripts/playwright-cli.sh click e15
./scripts/playwright-cli.sh fill e17 "weiduo2026"
./scripts/playwright-cli.sh localstorage-get ai_workshop_v1_questions
./scripts/playwright-cli.sh screenshot
./scripts/playwright-cli.sh close
```

### 原理

wrapper 自动完成以下操作：
1. 清空 `NODE_OPTIONS`（绕过 `--use-system-ca` 冲突）
2. 将 managed node 路径（`/Users/chenck/.workbuddy/binaries/node/versions/22.12.0/bin`）置入 `PATH` 首位
3. 透传所有参数给 `playwright-cli`
4. 如果 managed node 路径不存在，输出清晰错误提示

### 故障排查

如果 wrapper 报错 `managed node not found`，检查：
- `ls /Users/chenck/.workbuddy/binaries/node/versions/22.12.0/bin/` 是否存在
- 如果路径变了，更新 `scripts/playwright-cli.sh` 中的 `NODE_BIN_DIR`

## UI 操作的合规要求(2026-05-09 补充)

1. **永远不使用 eval、`document.getElementById().value=`、`evaluate` 类命令注入数据**——即使是为了"绕过编码问题"
2. **冒烟测试前必须在汇报里列"操作计划"**，每条计划项目格式：
   - wrapper 命令（`open` / `click <ref>` / `fill <ref>` / `localstorage-get` / 等）
   - 期望结果
   - 备注
3. **冒烟测试后必须附"实际执行命令清单"**，与计划对照
4. **如果遇到 UI 操作受阻**（编码、ref 失效、超时），立即停下汇报根因，**禁止使用任何形式的"绕过"**
