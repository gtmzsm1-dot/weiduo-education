# 维多教育 · 学员成长档案系统 AI运维交接文档

> **本文档原名《AI运维交接文档》，2026-05-09 归档进 git 时改名为 HANDOVER.md**

> **版本**: 2026-05-09 V1
> **关联文档**:
> - 技术细节:本文档(HANDOVER.md)
> - 开发环境:`docs/dev-env-notes.md`
> - 变更历史:`docs/changelog.md`
> - **产品方向决策:`docs/PRODUCT_PRINCIPLES.md`**(新功能设计前必读)
> **编写者**: WorkBuddy AI 助手
> **目标读者**: 接替本项目的 AI Agent

---

## 一、项目全貌

### 1.1 项目是什么

维多教育（西安教培机构）的 **K12 学员成长档案系统**，面向数学学科的个性化教学管理平台。部署于 GitHub Pages，纯前端单页应用，无后端服务器。

系统由两大模块组成：

| 模块 | 英文名 | 定位 |
|------|--------|------|
| **学员成长档案系统** | Student Growth Profile System | 核心系统，管理学员档案、成绩趋势、家长查询 |
| **AI提分工坊 V1** | AI Workshop V1 | 教学工具，用于小测管理、题目录入、批改、统计 |

### 1.2 技术架构

```
仓库：https://github.com/gtmzsm1-dot/weiduo-education
本地路径：/Users/chenck/WorkBuddy/repos/weiduo-education

├── index.html          ← 源文件（3160行，与deploy完全相同）
├── deploy/
│   └── index.html      ← GitHub Pages 部署入口
└── README.md

部署方式：GitHub Pages（push main → 自动部署）
访问方式：https://gtmzsm1-dot.github.io/weiduo-education/deploy/index.html
```

**技术栈**：纯 HTML + CSS + JavaScript，零依赖，零构建工具。所有逻辑、样式、标记在单个 `index.html` 中。数据存储于浏览器 `localStorage`。

### 1.3 代码结构概览

`index.html` 内部结构（按行号大致范围）：

| 行号范围 | 内容 |
|----------|------|
| 1–200 | CSS 样式（含响应式、打印样式） |
| 208 | `/* ===== AI提分工坊样式 ===== */` |
| 200–385 | HTML 结构（登录页、管理页、侧边栏、模态框等） |
| 386 | `<!-- ===== AI提分工坊页面 ===== -->` |
| 390–420 | JavaScript 常量与配置 |
| 420–2015 | 学员成长档案系统 JS 逻辑（~70个函数） |
| 2016–3160 | AI提分工坊 V1 JS 逻辑（~60个函数） |

---

## 二、系统功能详解

### 2.1 学员成长档案系统

**核心能力**：
- 学员建档：姓名、年级、科目、成绩趋势、目标分
- 成绩快照：按日期记录各科成绩，绘制趋势图
- 消耗台账：课程消耗记录（一对一、班课、晚托、全托等）
- 家长查询：家长通过档案码查看学生档案（只读）
- 管理后台：搜索、筛选、新增、编辑、删除学员
- Excel 导入导出：成绩快照和消耗记录支持 Excel 批量操作
- 数据备份：JSON 格式导出/导入全部数据

**数据模型**（localStorage）：
- 学员数据由主系统自行管理（非 AI Workshop 的数据）
- 每个学员含：基础信息、成绩快照数组、消耗记录数组、成长记录、沟通记录、荣誉记录

**关键函数**：
- `doAdminLogin()` / `doLogin()` — 登录
- `loadData()` / `saveData()` — 数据读写
- `showDashboard()` — 驾驶舱
- `renderParentProfile()` — 家长视图
- `exportData()` / `handleImport()` — 数据导入导出

**主系统 data-testid 一览**（2026-05-09 新增,覆盖批次 2 冒烟范围）：

| data-testid | 按钮文字 | 功能 | 行号(index.html) |
|---|---|---|---|
| `main-btn-backup` | 💿 手动备份 | 触发 backupData() | 326 |
| `main-btn-add-student` | ＋ 新增学生 | 打开新增学员弹窗 | 370 |
| `main-btn-edit-student` | ✏️ 编辑 | 打开编辑学员弹窗 | 1115 |
| `main-btn-save-student` | 确认添加 | 保存新增学员 | 1712 |
| `main-btn-delete-student` | 🗑️ 删除学生 | 删除学员(连续 2 次 confirm) | 1829 |
| `main-btn-save-edit` | 保存修改 | 保存编辑后的学员 | 1831 |

**注意**:主系统按钮的 data-testid 前缀为 `main-`，与 AI 工坊的 `aiw-` 前缀区分。

### 2.2 AI提分工坊 V1

**核心能力**：
- 学生管理：新建、编辑、删除（独立于主系统学员数据）
- 小测管理：按学生创建小测，设置知识模块
- 题目录入：支持填空/选择/解答题，设置分值
- 作答批改：录入学生答案、批改结果（正确/错误/半对）、评分、评语
- 统计报告：汇总得分率、正确/错误/半对数量
- 打印预览：学生卷/教师卷两种模式
- 数据备份：JSON 导出/导入/检查

**数据模型**（localStorage，与主系统隔离）：

| Key | 内容 | 数据结构 |
|-----|------|----------|
| `ai_workshop_v1_meta` | 版本信息 | `{version, updatedAt}` |
| `ai_workshop_v1_students` | 学生列表 | `[{id, name, grade, currentScore, targetScore, level, ...}]` |
| `ai_workshop_v1_quizzes` | 小测列表 | `[{id, studentId, title, module, createdAt, ...}]` |
| `ai_workshop_v1_questions` | 题目列表 | `[{id, quizId, type, content, score, answer, analysis, ...}]` |
| `ai_workshop_v1_answers` | 作答记录 | `[{id, questionId, studentAnswerText, result, score, comment, ...}]` |

**关系**：`quizzes.studentId → students.id`，`questions.quizId → quizzes.id`，`answers.questionId → questions.id`

**所有 data-testid 选择器**（验收/自动化测试用）：

| data-testid | 功能 | 触发函数 |
|-------------|------|----------|
| `aiw-btn-add-student` | 新增学生 | `aiWorkshopShowStudentModal()` |
| `aiw-btn-export` | 导出数据 | `aiWorkshopExportBackup()` |
| `aiw-btn-import` | 导入数据 | `aiWorkshopShowImportModal()` |
| `aiw-btn-check-data` | 检查数据 | `aiWorkshopRunDataCheck()` |
| `aiw-btn-open-student` | 查看学生 | `renderAiWorkshopStudentDetail()` |
| `aiw-btn-edit-student` | 编辑学生 | `aiWorkshopShowStudentModal()` |
| `aiw-btn-delete-student` | 删除学生 | `aiWorkshopDeleteStudent()` |
| `aiw-btn-save-student` | 保存学生 | `createAiWorkshopStudent()` |
| `aiw-btn-add-quiz` | 新增小测 | `aiWorkshopShowQuizModal()` |
| `aiw-btn-open-quiz` | 查看题目 | `renderAiWorkshopQuizQuestions()` |
| `aiw-btn-copy-quiz` | 复制小测 | `aiWorkshopShowCopyQuizModal()` |
| `aiw-btn-edit-quiz` | 编辑小测 | `aiWorkshopShowQuizModal()` |
| `aiw-btn-delete-quiz` | 删除小测 | `aiWorkshopDeleteQuiz()` |
| `aiw-btn-save-quiz` | 保存小测 | `createAiWorkshopQuiz()` |
| `aiw-btn-grade-quiz` | 作答批改 | `renderAiWorkshopQuizGradingPage()` |
| `aiw-btn-print-quiz` | 打印预览 | `renderAiWorkshopQuizPrintPreview()` |
| `aiw-btn-complete-quiz` | 完成小测 | `aiWorkshopMarkQuizCompleted()` |
| `aiw-btn-add-question` | 新增题目 | `aiWorkshopShowQuestionModal()` |
| `aiw-btn-question-up/down` | 题目排序 | `aiWorkshopMoveQuestion()` |
| `aiw-btn-edit-question` | 编辑题目 | `aiWorkshopShowQuestionModal()` |
| `aiw-btn-delete-question` | 删除题目 | `aiWorkshopDeleteQuestion()` |
| `aiw-btn-save-question` | 保存题目 | `createAiWorkshopQuestion()` |
| `aiw-btn-save-answer` | 保存作答 | `aiWorkshopSaveAnswer()` |
| `aiw-btn-confirm-copy-quiz` | 确认复制 | `aiWorkshopCopyQuizToStudent()` |
| `aiw-answer-text` | 学生答案输入 | — |
| `aiw-answer-image` | 答案图片上传 | — |
| `aiw-answer-result` | 批改结果选择 | — |
| `aiw-answer-score` | 得分输入 | — |
| `aiw-answer-comment` | 评语输入 | — |
| `aiw-copy-target-student` | 复制目标学生选择 | — |

### 2.3 用户角色与权限

| 角色 | 入口方式 | 权限 |
|------|----------|------|
| **管理员** | URL 加 `?admin=1` → 输入密码 `weiduo2026` | 全部功能 + AI提分工坊 |
| **家长** | 直接打开 URL（无参数）→ 输入学生档案码 | 只读查看学生档案 |
| **家长二维码** | 扫码直接进入家长查询页面 | 同上 |

---

## 三、部署与运维

### 3.1 部署流程

```
修改代码 → node --check 语法检查 → git push origin main → GitHub Pages 自动部署（1-3分钟）
```

**关键约束**：
- `index.html` 和 `deploy/index.html` **必须保持完全一致**（`cmp` 比较结果须为 0）
- 部署入口是 `deploy/index.html`，GitHub Pages 配置指向 `deploy/` 目录
- 合并前必须做 `node --check` 语法检查

### 3.2 本地开发环境

```bash
# 启动本地服务
cd /Users/chenck/WorkBuddy/repos/weiduo-education
python3 -m http.server 8123
# 本地访问：http://localhost:8123/deploy/index.html?admin=1

# 语法检查
# 提取 <script> 内容到临时 JS 文件
python3 -c "
from pathlib import Path
text = Path('index.html').read_text(encoding='utf-8')
start = text.find('<script>')
end = text.rfind('</script>')
Path('/tmp/check.js').write_text(text[start+8:end], encoding='utf-8')
"
# 使用 managed node（系统 node 不可用）
/Users/chenck/.workbuddy/binaries/node/versions/22.12.0/bin/node --check /tmp/check.js
```

### 3.3 浏览器自动化（验收测试用）

```bash
# playwright-cli 基础使用
# 注意：如果遇到 "NODE_OPTIONS 冲突" 错误，在命令前加 NODE_OPTIONS=：
NODE_OPTIONS= playwright-cli open <url>
NODE_OPTIONS= playwright-cli snapshot
NODE_OPTIONS= playwright-cli click <ref>
NODE_OPTIONS= playwright-cli fill <ref> "text"

# 常用命令
playwright-cli open <url>           # 打开浏览器
playwright-cli snapshot             # 获取页面快照（YAML格式）
playwright-cli click <ref>          # 点击元素
playwright-cli fill <ref> "text"    # 填写表单
playwright-cli screenshot           # 截图
playwright-cli close                # 关闭浏览器
playwright-cli localstorage-get <key>  # 读取 localStorage

# 如有中文编码问题导致 click 未触发 onclick，改用 eval 直接调用函数：
playwright-cli eval "(() => { functionName(); return 'ok'; })()"
```

### 3.4 Git 分支说明

| 分支 | 用途 | 状态 |
|------|------|------|
| `main` | 生产分支，对应 GitHub Pages | 当前在此 |
| `ai-workshop-v1` | AI提分工坊开发分支（早期） | 历史 |
| `ai-workshop-v1-testable` | AI提分工坊可测试版本（已合并） | 已合并到 main |
| `backup/main-before-ai-workshop-v1` | 合并前 main 备份 | 安全回滚点 |

### 3.5 管理员密码

```
weiduo2026
```

代码中硬编码于 `const ADMIN_PASSWORD = 'weiduo2026';`（约第410行）。

---

## 四、已知问题（上线后修复项）

### 【已修复/经验证不复现】

经 2026-05-09 阶段 1 复现验证，当前 main（commit 734c3eb）以下问题已不复现：

| # | 问题 | 详细描述 | 验证说明 |
|---|------|----------|----------|
| P0-1 | 题目分值字段保存错误 | 表单中分值填 5，保存后 `question.score = 1` | 经 2026-05-09 阶段 1 复现验证，当前 main(commit 734c3eb)未复现此问题。分值输入 5，localStorage 存储值为 5。 |
| P0-2 | 题目表单字段映射错乱 | 标准答案被写入知识点模块字段；解析被写入分值字段 | 经 2026-05-09 阶段 1 复现验证，当前 main(commit 734c3eb)未复现此问题。所有字段映射正确。 |
| P1-1 | 统计报告得分率计算错误 | `aiWorkshopComputeQuizStats()` 中 `maxScore` 取的是默认值而非各题分值之和 | 经 2026-05-09 阶段 1 复现验证，当前 main(commit 734c3eb)未复现此问题。三题分值 5+10+15 累计满分为 30，批改后得分率 33.3% 正确。 |
| P2-2 | 题目列表"知识点"列显示标准答案 | 原描述字段映射混乱导致 | 经 2026-05-09 阶段 1 复现验证，当前 main(commit 734c3eb)未复现此问题。`knowledgePoint`（子知识点）与 `knowledgeModule`（知识模块）为两个独立字段，表头"知识点"对应前者，显示逻辑与设计一致。 |

### P1 影响真实使用

| # | 问题 | 详细描述 |
|---|------|----------|
| P1-2 | 打印预览按钮选择器曾错位 | 验收时发现"打印预览"按钮的 `data-testid` 为 `aiw-btn-print-quiz`，但列表中编辑按钮为 `aiw-btn-edit-question`，需确认当前渲染是否正确 |

### P2 体验优化

| # | 问题 | 建议 |
|---|------|------|
| P2-1 | 打印预览缺少打印按钮 | 添加 `window.print()` 触发按钮 |

**注意**：P0-1/P0-2/P1-1/P2-2 已在阶段 1 复现验证中确认不复现，相关 bug 可能存在于历史分支（`ai-workshop-v1-testable`），当前 main 代码逻辑正确。

---

## 五、如何执行任务（Agent 操作指南）

### 5.1 严格的边界规则

用户对 AI Agent 有明确的协作规范，**必须遵守**：

1. **不做新功能** — 只修复明确指定的 bug，不主动添加功能
2. **不提 PR** — 不创建 Pull Request，直接在分支上操作，由用户决定合并
3. **遇冲突即停** — git 合并冲突时立即停止并汇报
4. **不做验收时严禁修改代码** — 验收任务中只记录问题
5. **不做 git 操作（验收时）** — 验收时不允许 git add / commit / push
6. **禁止 eval/localStorage 写入测试数据** — 必须通过真实 UI 操作录入
7. **话题隔离** — 不同功能模块须在各自独立聊天中处理

### 5.2 标准开发流程

```
1. 切换到开发分支（非 main）
2. 修改代码
3. 本地语法检查（node --check）
4. 确认 index.html === deploy/index.html（cmp）
5. 本地启动服务冒烟测试
6. 汇报修改内容（不含 git push）
7. 等待用户确认后，用户自行决定合并和 push
```

### 5.3 标准验收流程

```
1. 确认分支和提交（不修改）
2. 启动本地服务
3. 逐项 UI 操作验收（用 playwright-cli）
4. 如实记录 pass/fail
5. 不修复问题，只记录
6. 输出结构化验收报告（表格形式）
```

### 5.4 上线流程

```
1. 确认工作区 clean
2. 切 main，pull latest
3. 备份 main（创建 backup 分支）
4. 合并开发分支（--no-ff）
5. 冲突检查 → 如有冲突立即停止
6. 后置检查（SYNC、语法、关键词）
7. push main
8. 等待 GitHub Pages 部署
9. 线上冒烟检查
10. 输出上线报告
```

---

## 六、当前系统状态（2026-05-09）

| 项目 | 状态 |
|------|------|
| 当前分支 | `main`（commit `734c3eb`） |
| 工作区 | clean |
| GitHub Pages | 已部署 |
| AI提分工坊 V1 | 已上线，P0/P1 经验证不复现 |
| 主系统 | 正常运行 |
| 已知线上学生 | 2 名（赵怡涵、韩知维等，详见主系统数据） |

---

## 七、配套工具与文件

| 文件 | 用途 |
|------|------|
| `docs/templates/monthly-data-template-v1.xlsx` | 月度数据采集模板（教务部门使用） |
| `docs/assets/parent-qrcode.png` | 家长扫码入口二维码 |
| `backup/main-before-ai-workshop-v1` | 合并前 main 备份分支 |

---

## 八、下一步待办（按优先级）

### 短期

1. 打印预览添加打印按钮
2. AI提分工坊功能完善（Phase 7 前端推进）

### 中期

6. 学员成长画像系统升级
7. 数据采集模板与系统导入打通

---

## 九、用户偏好速查

| 偏好项 | 规则 |
|--------|------|
| 回复语言 | 简体中文 |
| 输出格式 | 详细结构化，表格汇报 pass/fail |
| 任务简报 | 含明确步骤、边界与输出格式要求，定义禁止事项 |
| 代码操作 | 增量推进，每阶段更新文档 |
| 验收要求 | 如实报告，无法执行必须说明，禁止假装测试 |
| 话题隔离 | 不同功能模块须在各自独立聊天中讨论 |
| 冒烟测试报告 | 固定格式：结论 / 执行状态 / 检查项 / 已知问题 / 访问方式 |
