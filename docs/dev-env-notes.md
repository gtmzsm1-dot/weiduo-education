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

## Git Hooks

仓库预提交(pre-commit)hook 执行以下检查：
1. **SYNC 检查**：`index.html` 和 `deploy/index.html` 必须同步
2. **语法检查**：用 `node --check` 验证 `<script>` 块中 JS 语法

### 安装

```bash
bash scripts/install-hooks.sh
```

### NODE_OPTIONS 兼容

hook 内部已注入 `NODE_OPTIONS=""` 绕过本机 node 配置冲突（`--use-system-ca`）。
见上方 NODE_OPTIONS 冲突章节。

### 手动验证（在已安装 hook 的仓库中）

```bash
# 验证 SYNC 拦截
echo "modified" > /tmp/test-sync && cp /tmp/test-sync index.html
.git/hooks/pre-commit  # 应报 SYNC 错误

# 验证语法拦截
cp index.html deploy/index.html
python3 -c "
text = open('index.html').read()
text = text.replace('<script>', '<script>\\nconst __test_INVALID__ = ;', 1)
open('index.html','w').write(text)
"
.git/hooks/pre-commit  # 应报 JS syntax error

# 正常提交通过
git checkout -- index.html deploy/index.html  # 恢复
.git/hooks/pre-commit  # 应 exit 0
```

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

## AI 工坊删除操作的对话框序列(2026-05-09 记录)

### 删除学生

点击 `aiw-btn-delete-student` 后,系统会**连续弹出 2 个 confirm 对话框**:

- 第 1 个:"确定删除学生「__test_补冒烟B1__」？"
- 第 2 个:"请再次确认删除，删除后其小测草稿也会删除且不可恢复。"

playwright-cli 自动化必须连续 `dialog-accept` 两次。

### 删除小测/题目(待确认)

[暂未验证,使用时通过 UI 探索后补充]

## playwright-cli snapshot 的属性可见性(2026-05-09 验证)

### 结论

snapshot YAML 输出**不包含**HTML 属性。任何 `data-*`、`data-testid`、`data-student-id`、`href`、`class`、`id` 等属性在 snapshot 中均不可见。

### 验证细节

- 验证元素:管理员登录页的按钮、AI 工坊页面的按钮(已知有 data-testid)、学生列表(已知有 data-student-id)
- snapshot 输出中是否能看到 testid:否
- snapshot 输出中是否能看到其他 data-* 属性:否
- 验证范围:3 个不同页面的 snapshot,0 个 data- 匹配

### 影响

- 验证元素是否有特定 data-* 属性时,**需要诊断 eval**(只读)
- 后续合规规则补充:先 snapshot 再决定是否需要 eval 这一原则仍然有效,但需注意 **snapshot 主要用于查看元素树结构和文本内容,不能用于属性查询**

### 在什么场景下应该用诊断 eval

当需要确认元素的 data-* 属性是否存在/具体值时,snapshot 不够,**直接报备诊断 eval**。

## 主系统新增学员后的视图切换(2026-05-09 记录)

### 行为

新增学员保存后,主系统**自动切换到该学员的"新生档案"简化视图**——这个视图**不显示编辑按钮**(设计如此,见 docs/HANDOVER.md 第 2.1 节)。

### 影响

如果需要立即编辑该新学员,必须**先 click 侧边栏的学员卡片**,切换到完整档案视图,编辑按钮才会出现。

### 自动化测试模式

```bash
# 新增学员
click '[data-testid="main-btn-add-student"]'
# ...填写表单...
click '[data-testid="main-btn-save-student"]'

# 切换到完整档案视图(必须步骤)
snapshot  # 取侧边栏学员卡片 ref
click <ref of student card>

# 现在可以编辑
click '[data-testid="main-btn-edit-student"]'
```

### 第三类 eval:环境配置(2026-05-09 v4 补充)

除"操作型(禁)"和"诊断型(限)"外,新增第三类:

#### 环境配置型 eval

用于**模拟测试条件**,不操作业务数据、不绕过业务流程。

**典型场景**:
- 注入大体积占位字符串到 `__test_*__` 前缀 key(模拟 localStorage 爆满)
- 设置/清除元数据 key 的值(模拟"7 天未备份"等时间相关条件)
- 清理测试残留(`removeItem('__test_*__')`)

**允许范围**:
- key 前缀必须是 `__test_*__` 或 `weiduo_*`(元数据)/ `ai_workshop_v1_*meta`
- **绝对不允许**操作业务数据 key(`weiduo_students`、`ai_workshop_v1_students` 等)

**报备要求**:
- 首次使用某个 key 时必须报备
- 报备格式:列出 key 名 + 操作 + 用途
- owner 一次批准后,同 key 同操作可重复使用

**清理要求**:
- 测试结束必须清理(removeItem)
- 不允许"留到下次复用"

### 严禁滥用警告

第三类 eval 是**最容易被滥用的灰色地带**。以下边界必须严守:

- ❌ **不能借"测试环境"名义触碰任何业务数据 key**——即使你认为"只是清空一下"
- ❌ **不能在生产环境(线上 GitHub Pages)使用**——只允许在本地 `localhost:8123` 测试
- ❌ **不能用于"加快开发"**(比如直接预填登录密码、跳过弹窗)——这种场景应该改 UI 流程,不是绕过
- ✅ **每次新增允许的 key 模式都需要 owner 显式批准**——不允许"既然 weiduo_ 前缀允许,我推断 ai_workshop_v1_ 前缀也允许"

## 测试环境数据状态意识(2026-05-10 补充)

### 教训背景

阶段 6.2 性能优化冒烟时,使用了 hardcoded 默认 archiveCode `WD20251008` 测试家长视图——但生产环境该 archiveCode 已被 migrateLegacyArchiveCodes 改写。测试在本地 pass 不代表生产 pass。

### 必须遵守

每次涉及"localStorage 中数据值"的冒烟测试,**必须先确认测试时本地 localStorage 实际状态**:

- **空 localStorage**(playwright-cli 每次 open 都是空的)→ loadData 会加载 hardcoded 默认数据,而非生产数据
- **已通过管理员登录触发迁移**→ 数据已变为新格式

### 标准做法

涉及 archiveCode、studentId 等"会被业务逻辑修改"的字段时:

1. **先用 wrapper 走一次管理员登录**(触发可能的 loadData / migration)
2. **localstorage-get 取实际值**(不要用 hardcoded 假设值)
3. **基于实际值做后续测试**

### 反模式

❌ 直接从 index.html 源码或文档中复制 hardcoded 字段值用于测试
❌ 假设"生产环境的字段值 = 默认数据值"
✅ 测试前用 wrapper 取一次实际值,再传给后续步骤

如对某次测试的"数据状态是否匹配生产环境"存疑,**默认验证后再测试**,而不是假设"反正不影响代码路径"。
