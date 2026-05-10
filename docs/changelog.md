# 变更记录

## 2026-05-09
- 阶段 1 完成：P0-1/P0-2/P1-1/P2-2 复现验证，均未复现，文档同步更新
- 分支：fix/p0-question-form-mapping
- 验证 commit：734c3eb
- docs/changelog.md：创建变更记录文件
- docs/dev-env-notes.md：创建开发环境注意事项（NODE_OPTIONS 冲突解决）

## 2026-05-10

### 重大产品方向决策

- **发现根本性架构限制**:阶段 6 上线后真实家长扫码验证暴露,纯前端 localStorage 架构不能跨设备共享数据。
- **决策**:采用"单机 + 云端只读同步 + 客户端加密"混合架构,作为阶段 8 启动。
- **方案文档**:`docs/STAGE_8_PLAN.md`
- **PRODUCT_PRINCIPLES.md 新增决策 #3**

### 当日上线工作汇总

- 阶段 3 SHA-256 密码加固 ✅ 上线
- 阶段 4 最小版 pre-commit hook ✅ 上线
- 阶段 6 关键子集(打印按钮 + 工坊延迟加载)✅ 上线
- v2.0-stage6 release tag ✅
- commit:54639fc

### 阶段 8 决策细节

owner 已确认:
- 扫码即看(无二级密码)
- 接受加密 JSON 公开存放
- 手动触发同步
