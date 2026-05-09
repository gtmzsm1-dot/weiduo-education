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

## UI 操作的合规要求(2026-05-09 补充,2026-05-09 v2 细化)

### 严格禁止(操作型 eval)

任何形式的"用代码注入数据 / 触发业务逻辑"都禁止:

- ❌ `eval('aiWorkshopShowStudentModal()')` 然后 JS 改 input.value
- ❌ `eval('createAiWorkshopStudent(...)')`
- ❌ `eval('localStorage.setItem(...)')`
- ❌ `playwright-cli eval` 用于设置表单值、点击按钮、调用业务函数

理由:绕过表单校验、UI 状态机、用户路径,导致冒烟测试无效。

### 有限允许(诊断型 eval,需报备)

如果 UI 操作受阻,**可以**用 eval 做**只读诊断**,但必须遵守:

1. **诊断型 eval 仅限"读取页面状态"**:
   - ✅ 查询元素是否存在(`document.querySelector('[data-testid=...]')`)
   - ✅ 读取元素属性(`el.disabled`、`el.value`、`el.dataset`)
   - ✅ 读取 localStorage(只读)
2. **不允许改变任何状态**:
   - ❌ 不许 setItem、不许 click()、不许 dispatchEvent、不许改 value、不许调用业务函数
3. **执行前必须在汇报里写明**:
   - 我要 eval 什么命令
   - 我为什么需要这个诊断(无法用 snapshot 替代的理由)
   - 期望读到什么
4. **执行后立即在汇报里附实际命令和结果**

### 受阻时的标准动作

UI 操作失败 → 先用 `snapshot` 查页面状态 → 如 snapshot 不够,**汇报失败现象 + 列计划用什么诊断 eval** → 等用户批准 → 执行诊断 → 报告结论

绝对不允许:UI 失败 → 自己跳到操作型 eval 来"绕过"

### 认识论诚实(2026-05-09 v3 补充)

汇报中的事实陈述必须明确标注**信息来源 + 验证状态**:

- ✅ **已验证**:亲自验证过(看过代码片段、跑过命令、读过 snapshot 输出),需附行号或证据
- 🔍 **推测**:基于已知信息合理推断,但未实际验证。**必须明示"推测"二字**
- 📋 **来自文档**:从 docs/HANDOVER.md 或 dev-env-notes.md 引用,需注明出处

**禁止使用以下措辞**(包装推测为事实):

- ❌ "已知事实"(没说来源)
- ❌ "代码中确实"(没给行号)
- ❌ "应该是"(模糊语气掩盖推测)
- ❌ "显然"

**正确写法示例**:

- ✅ 验证过:"aiw-btn-open-student 有 data-student-id 属性(已验证,index.html 第 2476 行)"
- 🔍 推测:"aiw-btn-delete-student 推测也有 data-student-id 属性,因为在同一渲染函数中,但未验证"
- 📋 引用:"AI 工坊删除学生需 dialog-accept 两次(见 dev-env-notes.md)"

### 决策点的特殊要求

涉及**走哪条路径 / 是否需要诊断 eval / 哪个数据是否可靠**等决策时,所有作为决策依据的事实必须明确标注验证状态。**用户审查时会重点检查这一项**。

## playwright-cli click 操作的标准做法(2026-05-09 v3 补充)

### 背景

playwright-cli 0.1.9 的 `click <ref>` 命令默认走 getByRole 路径，在中文按钮场景下因终端编码导致 name 匹配失败，onclick 不触发。

### 标准做法：用 CSS 选择器 + data-testid

所有交互按钮项目内已有 data-testid 属性（见 docs/HANDOVER.md 第 2.2 节）。后续 UI 冒烟一律使用：

```bash
./scripts/playwright-cli.sh click '[data-testid="aiw-btn-save-student"]'
```

而**不是**：

```bash
./scripts/playwright-cli.sh click e180   # 中文按钮场景下不可靠
```

### 何时仍可用 ref

- 输入框 fill 操作：ref 方式可靠（已验证）
- 无 testid 的元素：用 ref（并在 snapshot 后立即用，避免 ref 失效）

### 何时必须用 testid + CSS 选择器

- 任何 click 中文按钮的场景（✅ 已验证 100% 可靠）
- 任何"保存/删除/确认"等关键业务动作

### 如果遇到没有 testid 的关键按钮

- **不要绕过、不要 eval**
- 在汇报里指出："按钮 X 缺少 data-testid，无法可靠点击"
- 由用户决定：是补 testid（代码改动）还是用其他定位方式
