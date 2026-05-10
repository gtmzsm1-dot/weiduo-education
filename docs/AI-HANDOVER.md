# 维多教育 · 学员成长档案系统 — AI Agent 项目交接快照

> **编写日期**: 2026-05-10 09:38 CST  
> **编写者**: WorkBuddy AI 助手  
> **目标读者**: 后续接手本项目的 AI Agent  
> **用途**: 让新的 AI 阅读后能独立理解项目全貌、当前状态、及所有上下文

---

## 1. 项目基础信息

| 字段 | 值 |
|------|-----|
| 项目名 | 维多教育 · 学员成长档案系统 |
| 机构 | 西安维多教育（曲江校区），K12 教培 |
| 仓库 | `https://github.com/gtmzsm1-dot/weiduo-education` |
| 本地路径 | `/Users/chenck/WorkBuddy/repos/weiduo-education` |
| 部署方式 | GitHub Pages（push main → 自动部署） |
| 线上地址 | `https://gtmzsm1-dot.github.io/weiduo-education/deploy/index.html` |
| 当前分支 | `main` |
| 最新 tag | `v2.0-stage6`（commit `54639fc`） |
| 文件结构 | 单文件 `index.html`（~197KB，~5300 行），`deploy/index.html` 为部署副本 |

**owner**: 西安维多教育负责人，唯一实际用户。所有产品决策需 owner 最终拍板。  
**代决策人**: 我（用户 ID: chenck），腾讯产品经理，在 owner 委托的范围内代决策。

---

## 2. 技术架构（重要事实，必须准确理解）

### 2.1 架构定性

```
纯前端单页应用 + 浏览器 localStorage
零后端服务器
零 API 端点（除 CDN 资源加载）
零用户身份系统
零数据同步机制
```

### 2.2 关键约束

- **所有数据只存在于当前浏览器**：localStorage 不跨设备、不跨浏览器共享
- **hardcoded 默认数据**：`loadData()` 在 localStorage 为空时，从代码中硬编码的两个默认学员（朱栖言 `WD20250901`、刘尚林 `WD20251008`）初始化
- **每个新浏览器会话看到的都是默认数据**：所有 setItem 仅影响当前浏览器
- **不是多用户系统**：产品定位为「单机工具，仅在 owner 一台电脑使用」

### 2.3 技术栈

- 纯 HTML + CSS + JavaScript（零依赖、零构建工具）
- 所有代码在单个 `index.html` 中
- 外部 CDN 资源：qrcode-generator（jsdelivr）、xlsx（jsdelivr）
- 测试工具：`playwright-cli` 0.1.9 + wrapper `scripts/playwright-cli.sh`
- 本地测试：`python3 -m http.server 8123`

### 2.4 两大模块

| 模块 | 核心功能 | 数据 key |
|------|---------|----------|
| 学员成长档案系统 | 学员管理、档案编辑、成绩趋势、家长查询 | `weiduo_students` |
| AI提分工坊 V1 | 小测管理、题目录入、批改评分、统计报告 | `ai_workshop_v1_*` |

---

## 3. Git 历史与已完成阶段

### 3.1 提交历史一览

```
54639fc (HEAD -> main, tag: v2.0-stage6, origin/main) merge: stage 3+4+6
96ce973 chore(stage-6): re-verify parent view with migrated archiveCode + add test data state awareness rule
bd35028 perf(stage-6): defer workshop code execution on parent path
2adb350 feat(stage-6): add print trigger button on quiz preview page
fd18449 fix(stage-4): inject NODE_OPTIONS in pre-commit hook for compatibility
0ac3866 feat(stage-3): hash admin password with SHA-256 (anti-F12 only)
ce08b12 merge: stage-2 data safety hardening (19 commits)
```

### 3.2 阶段完成状态

| 阶段 | 内容 | 状态 | 说明 |
|------|------|------|------|
| 阶段 1 | 初始版本开发（AI 工坊 + 主系统） | ✅ 已完成（首次部署） | 项目启动阶段 |
| 阶段 2 | localStorage 数据安全加固 | ✅ **已上线 main** | safeSetItem、配额处理、回滚、19 commits |
| 阶段 3 | SHA-256 密码加固 | ✅ **已上线 main** | 明文密码→ SHA-256 hash，anti-F12 |
| 阶段 4 最小版 | pre-commit hook（SYNC + 语法检查） | ✅ **已上线 main** | NODE_OPTIONS 兼容已修复 |
| 阶段 6 关键子集 | 打印按钮 + 工坊延迟加载 | ✅ **已上线 main** | 详见下方 3.3 |
| 阶段 5 | 合规与隐私 | ⏸ 等待 owner 深度参与 | — |
| 阶段 7 | 架构评估 | ⏸ 评估报告（非上线物） | — |
| 阶段 4 完整版 | GitHub Actions + 回滚 SOP | 📋 backlog | — |

### 3.3 阶段 6 要内容

**6.1 打印按钮**（commit `2adb350`）：
- 在打印预览顶部加 `data-testid="aiw-btn-print-trigger"`，`onclick="window.print()"`
- 利用已有 `@media print .no-print` 规则隐藏

**6.2 工坊延迟加载**（commit `bd35028`）：
- 工坊代码（~1135 行，51 个函数）从主 `<script>` 移到 `<script type="text/template" id="workshop-code">`
- `doAdminLogin()` 中动态注入 + 调用 `aiWorkshopLoadData()`
- 家长路径完全不加载工坊代码（性能优化 ~10%）

### 3.4 其他分支

| 分支 | 用途 | 状态 |
|------|------|------|
| `main` | 线上运行版本 | ✅ 最新 |
| `feat/admin-auth-hardening` | 阶段 3-6 开发分支 | ✅ 已合并到 main |
| `feat/data-safety` | 阶段 2 开发分支 | ⏸ 已完成 |
| `ai-workshop-v1` | 工坊原始开发分支 | ⏸ 存档 |
| `ai-workshop-v1-testable` | 工坊测试分支 | ⏸ 存档 |

---

## 4. 管理员访问方式

| 操作 | 说明 |
|------|------|
| 入口 | URL 加 `?admin=1` 参数 |
| 密码 | `weiduo2026`（SHA-256 hash 存储在代码中，无明文） |
| 功能 | 学员管理 + AI 工坊（完整功能） |

---

## 5. 家长访问方式（⚠️ 已知问题）

### 5.1 当前机制

- 家长通过 `?code=XXXXXX` 访问（二维码或链接）
- `doLogin()` 查找 `allStudents` 中匹配 archiveCode 的学员
- 成功→显示家长视图；失败→"档案编号不存在"

### 5.2 已知问题（2026-05-10 发现）

`migrateLegacyArchiveCodes()` 在管理员登录时，将旧格式 `WD` 码（如 `WD20251008`）替换为 10 位随机码（如 `94TZ5UMAJK`）。但：

- **新码仅保存在当前浏览器 localStorage**
- **全新浏览器 → loadData() 加载默认 WD 码 → 新码找不到**

**影响**：家长首次访问（新浏览器）用迁移后 archiveCode 无法登录。这个 bug 自阶段 2.3 就已存在，至今未修复。

### 5.3 产品定位澄清（2026-05-10 owner 确认）

系统定位为「**单机工具，仅在 owner 一台电脑使用**」。因此：
- 多用户/跨设备场景不是设计目标
- 阶段 2-6 的所有工作对单机场景完全有效
- **不需要回滚任何已上线内容**

### 5.4 待 owner 决策的问题

家长扫码场景的下一步方向尚未确认（owner 正在沟通中）。

---

## 6. 开发环境与工具链

### 6.1 本地测试

```bash
# 启动本地服务器（从 repo 根目录）
python3 -m http.server 8123 --bind 127.0.0.1

# 访问
http://localhost:8123/deploy/index.html?admin=1  # 管理员
http://localhost:8123/deploy/index.html?code=WD20251008  # 家长
```

### 6.2 UI 自动化（playwright-cli）

```bash
# 使用 wrapper（已处理 NODE_OPTIONS 冲突）
./scripts/playwright-cli.sh open <url>
./scripts/playwright-cli.sh snapshot
./scripts/playwright-cli.sh click e15          # ref-based click
./scripts/playwright-cli.sh click '[data-testid="aiw-btn-X"]'  # testid-based
./scripts/playwright-cli.sh fill e17 "text"
./scripts/playwright-cli.sh eval "JS code"
./scripts/playwright-cli.sh localstorage-get <key>
./scripts/playwright-cli.sh screenshot
./scripts/playwright-cli.sh close
```

**重要**：
- 每次 `open` 创建全新浏览器，localStorage 为空
- `click` 的 ref 基于最近一次 `open`/`snapshot`，会过期
- 中文按钮场景下 `click` 需用 `[data-testid="X"]` CSS 选择器

### 6.3 Pre-commit Hook

- 已安装（`scripts/install-hooks.sh`）
- 检查：SYNC（`index.html` 与 `deploy/index.html` 一致）+ JS 语法
- 内部已注入 `NODE_OPTIONS=""` 绕过本机配置冲突

---

## 7. 严格合规规则（接管项目前必须阅读）

> 全文在 `docs/dev-env-notes.md`，AI 必须遵守以下规则：

### 7.1 认识论诚实

汇报中的事实陈述必须标注来源：

| 标记 | 含义 |
|------|------|
| ✅ **已验证** | 亲自验证过（附行号或证据） |
| 🔍 **推测** | 基于已知信息合理推断，但未验证 |
| 📋 **来自文档** | 从 HANDOVER.md 等文档引用 |

**禁止**：包装推测为事实（"显然"、"应该是"、"代码中确实"）

### 7.2 Eval 分层规则

| 类型 | 允许 | 要求 |
|------|------|------|
| 操作型 eval | ❌ 严禁 | 任何数据写入、业务触发 |
| 诊断型 eval | ✅ 有限允许 | 只读，需报备 + 等批准 |
| 环境配置型 eval | ✅ 允许 | 限 `__test_*__` 和元数据 key，需清理 |

### 7.3 测试数据意识

- 涉及 localStorage 数据值的测试，必须先确认本地实际状态
- 不要用 hardcoded 假设值（如直接从源码复制 archiveCode）
- 走管理员登录 → localstorage-get 取实际值 → 基于实际值测试

---

## 8. 关键代码位置

| 功能 | 行号范围（当前版本） |
|------|-------------------|
| 登录页 HTML+CSS | 14-330 |
| 核心函数（loadData、doLogin、doAdminLogin、saveData） | 1823-1980 |
| 家长视图渲染（renderParentProfile） | ~2250-2300 |
| 学员管理（showDashboard、侧边栏、编辑） | ~2000-2250 |
| 默认硬编码学员数据 | 1833-1890 |
| page init（loadData → checkUrlParams） | ~3350-3360 |
| 工坊代码（template 块） | 外部 `<script type="text/template">` |
| migrateLegacyArchiveCodes | 1963-1975 |
| 预置密码 SHA-256 hash | ~390（常量 `ADMIN_PASSWORD_HASH`） |
| 打印按钮 testid | `aiw-btn-print-trigger`（在 renderAiWorkshopQuizPrintPreview 中） |

---

## 9. 当前待办事项

### 9.1 等待 owner 决策

- 家长扫码场景的下一步方向（如何在单机定位下处理家长访问）
- 阶段 5（合规与隐私）的启动时机
- 是否以及何时启动阶段 7 架构评估

### 9.2 未解决的技术问题

- `migrateLegacyArchiveCodes` 导致迁移后 archiveCode 在新浏览器中不可用（如要修复可参考：在 `doLogin()` 匹配失败时回退到默认数据查一次，或不做修复直接使用 WD 码）
- 工坊导入功能的端到端非空测试（backlog.md 中有记录）
- saveData 失败时的事务一致性问题（backlog.md 有记录）

### 9.3 Backlog 项

详见 `docs/backlog.md`，包含：
- 备份 key 使用 UTC 日期（低优先级）
- 工坊导入端到端测试（低优先级）
- saveData 事务一致性（中-高优先级）

---

## 10. 文档索引

| 文件 | 内容 |
|------|------|
| `docs/HANDOVER.md` | 原交接文档（2026-05-09，human 向） |
| `docs/AI-HANDOVER.md` | **本文档**（AI 向快照） |
| `docs/dev-env-notes.md` | 开发环境 + 合规规则（AI 必读） |
| `docs/PRODUCT_PRINCIPLES.md` | 产品方向原则（设计新功能前必读） |
| `docs/backlog.md` | 已知问题与待办 |
| `docs/changelog.md` | 变更历史 |

---

## 11. 紧急联系上下文

- 所有需 owner 拍板的问题，通过 `chenck`（腾讯产品经理）传递
- 严格遵守认识论诚实，不推断 owner 意图
- 核心工作原则：先计划后执行、先验证后结论、明确标记推测与事实
- 当前项目处于「等待 owner 对家长场景决策」的暂停状态

---

*本文档为 AI Agent 项目交接快照，下次接手时请先读取本文档 + `/Users/chenck/WorkBuddy/20260425082612/.workbuddy/memory/2026-05-10.md` 获取完整上下文。*
