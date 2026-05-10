# 阶段 8 计划:云端只读同步 + 客户端加密

> 状态:**方案已定,待实施**
> 决策日期:2026-05-09
> 实施时间:待定(预估 2-3 天)

---

## 背景

阶段 2-6 完成后,系统在"单机工具(校长在自己电脑使用)"场景下完全有效。但阶段 6 上线验证时发现:

> **真实家长用自己手机扫码访问 → 浏览器 localStorage 为空 → 加载 hardcoded 默认数据 → 实际录入的学员档案码不在默认数据中 → 无法登录**

这暴露了项目从 day 1 就存在的架构特性:**纯前端 + localStorage 架构,数据无法跨设备共享**。

owner 在产品定位上确认:
- 自己**只在一台电脑录入和管理**(单机工具)
- 但希望**家长用自己手机扫码,任何地方都能查看孩子档案**(每周一次)
- 目的:作为机构服务的差异化宣传卖点

这两个诉求在当前架构下不能同时满足。

---

## 决策:云端只读同步 + 客户端加密(轻量版)

### 工作机制

```
owner 电脑(管理端)              GitHub repo                  家长手机(查看端)
├─ 录入学员                    ├─ data/students-encrypted   ├─ 扫码访问 URL
│                              │   .json                     │
├─ 加密导出                    │  (内容是密文)               ├─ 加载密文 JSON
│                              │                              │
├─ 手动同步按钮触发 push       ├─ GitHub Pages 自动部署       ├─ 用 archiveCode 解密
│                              │                              │
                                                              └─ 显示档案 ✅
```

### 核心设计

1. **数据存储**:`data/students-encrypted.json` 公开存放在 GitHub Pages 上
2. **加密机制**:每个学员档案用其 archiveCode 派生 AES-256 key 加密
3. **解密路径**:家长扫码 URL 携带 archiveCode → 浏览器用此 archiveCode 解密对应学员密文
4. **同步触发**:owner 主动点击"同步到云端"按钮,触发本地 git commit + push
5. **家长访问**:无需密码,扫码即看(archiveCode 同时充当访问凭证 + 解密钥匙)

### 关键安全特性

- 公开放在 GitHub 的 JSON 是**密文**,任何人 curl 下载只能拿到一堆乱码
- 必须有 archiveCode 才能解密对应学员数据
- archiveCode 空间 31^10 ≈ 8.2 × 10^14,理论上不可枚举
- 二维码 = 凭证 = 解密钥匙(三合一)
- ⚠️ **二维码需要家长妥善保管**——任何拿到二维码的人都能看到这个学员档案

### owner 已确认的产品决策

| # | 决策点 | 选择 |
|---|---|---|
| 1 | 扫码体验 | **扫码即看**(无二级密码) |
| 2 | 数据可见性 | **接受加密 JSON 公开存放** |
| 3 | 同步触发 | **手动触发**(明确按钮) |

---

## 实施计划(待启动)

### Step 8.1:加密导出机制
- 实现 `exportEncryptedData()` 函数
- 用 `crypto.subtle.deriveKey` + `crypto.subtle.encrypt` 加密每个学员
- 输出 `data/students-encrypted.json`

### Step 8.2:同步触发 UI
- 管理员视图加"同步到云端"按钮
- 点击后:导出 → 写入 data/ 目录 → 提示 owner 手动 commit + push
- (或自动化 git 命令,看 owner 偏好)

### Step 8.3:家长视图改造
- doLogin 改造:扫码后 fetch students-encrypted.json
- 用 archiveCode 派生 key 解密对应学员
- 渲染家长视图(渲染逻辑不变)

### Step 8.4:数据更新策略
- 加密 JSON 包含 `updatedAt` 时间戳
- 家长视图显示"数据更新于 X"
- 处理 GitHub Pages CDN 缓存(约 5-10 分钟延迟,可接受)

### Step 8.5:边缘情况处理
- archiveCode 不存在 → 显示"档案不存在"
- 解密失败 → 显示"档案码无效"
- 网络断开 → 显示"网络异常,请稍后再试"
- JSON 损坏 → 降级提示

### Step 8.6:真实手机端测试
- owner 用自己手机或同事手机
- 扫码访问真实 GitHub Pages 部署
- 验证完整链路

### 预估工作量

2-3 天(在 owner 当前节奏下)

---

## 不实施的事(明确范围)

- ❌ 不接入 Supabase / Firebase 等后端服务
- ❌ 不引入任何运行时依赖(crypto.subtle 是浏览器原生 API)
- ❌ 不做"双向同步"(家长不修改数据,只读)
- ❌ 不做用户账号系统(archiveCode 即凭证)

---

## 关联决策

- 阶段 2.3 档案码改造(高熵随机)→ 是阶段 8 的前置条件,如果档案码是顺序数字,加密无意义
- PRODUCT_PRINCIPLES.md 决策 #1 用户分级 → 在单 owner 场景下,只有 L1(校长)和 L4(家长)实际存在,L2/L3/L5 暂不需要
- backlog 中的 transaction-consistency bug cluster → 阶段 8 实施时一并考虑(导出加密 JSON 也涉及事务一致性)

---

## 风险评估

### 低风险
- 加密机制成熟(浏览器原生 API)
- archiveCode 已是高熵随机
- GitHub Pages 公开访问稳定

### 中等风险
- 家长手机浏览器兼容性(老旧手机可能不支持 crypto.subtle)
- GitHub Pages CDN 缓存导致家长偶尔看到旧数据(5-10 分钟)
- 加密 JSON 体积膨胀(每学员加密后约 1.3-1.5 倍原大小)

### 处理方案
- 浏览器兼容:实施时检测 crypto.subtle,不支持时给清晰提示
- CDN 缓存:在文件名加版本号或 query string 强制刷新(如 `students-encrypted.json?v=20260509`)
- 体积:学员数 < 100 时无影响

---

## 启动条件

owner 状态最佳时启动,不在连续工作疲惫期启动。
启动前:
- 重新通读本文档
- 确认决策仍然合适(产品诉求未变化)
- 给 WorkBuddy 一份完整的阶段 8 启动指令
