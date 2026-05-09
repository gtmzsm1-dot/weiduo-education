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
