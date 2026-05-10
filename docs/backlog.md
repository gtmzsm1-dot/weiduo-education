# 已知问题(暂缓)

## 备份 key 使用 UTC 日期

**现象**:`weiduo_backup_YYYY-MM-DD` 的日期来自 UTC,而非用户本地时区。
**影响**:在 UTC+8 时区,北京时间 8:00 之前操作备份,生成的 key 日期会比"今天"早一天。
**风险**:用户期望"今天的备份"找不到时,可能误以为系统出 bug。
**位置**:index.html backupData() 函数,约第 2055 行附近。
**优先级**:低(不影响核心功能,但应在某个迭代解决)。
**记录时间**:2026-05-09,批次 2 执行时发现。

## 工坊导入功能的端到端非空测试

**现象**:批次 3 冒烟使用纯学员数据(quizzes/questions/answers 为空数组),safeBatchSetItem 的"非空 entries 映射"未做端到端验证。
**风险**:低(代码路径与空数组完全相同,且 Step 2.1b 控制台测试已覆盖)。
**建议**:某次自然产生完整工坊数据时(学员 + 小测 + 题目 + 批改),顺便做一次导出 → 删除 → 导入的端到端验证。
**记录时间**:2026-05-09,批次 3 关闭时识别。

## saveData 失败时的事务一致性问题(bug cluster)

**串联现象**(Step 2.1d 故障注入测试发现):

1. **memCount ≠ persistedCount**:saveData 失败时,allStudents 已 push,localStorage 未更新
2. **失败弹窗被吞**:safeSetItem 弹的"存储空间已满"被随后的 hideModal 重渲染掩盖
3. **showToast 误导**:saveData 失败后仍显示"已添加学生「X」",用户看到假成功

**统一根因**:`addStudent()` 没有"事务"概念,顺序执行 push → saveData → hideModal → showToast,失败时无回滚、无分支。

**触发条件**:saveData 调用失败(localStorage 爆满 / safeSetItem 返回 false)

**生产概率**:低(localStorage 5MB 上限,当前数据量远未触及)
**生产影响**:高(触发后直接破坏用户信任——"系统说成功了但其实没成功")

**统一修复方案**:

```js
function addStudent(...) {
  const student = {...};
  allStudents.push(student);  // 乐观更新
  
  if (!saveData()) {
    allStudents.pop();  // 回滚内存
    return;  // 弹窗已由 safeSetItem 处理,这里什么都不做
  }
  
  hideModal();
  showToast('已添加学生');
}
```

**配套要求**:`saveData()` 必须改为返回 boolean(成功/失败)。

**影响面排查**:除 addStudent 外,以下函数同样需要事务化改造(初步推测,需 view 代码确认):

- editStudent / 编辑学员相关
- 添加成绩快照 / addScore 等
- 添加消耗记录 / addConsumption 等
- 添加成长 / 沟通 / 荣誉记录类函数
- 工坊侧的 createAiWorkshopStudent / createAiWorkshopQuiz / createAiWorkshopQuestion / aiWorkshopSaveAnswer

**优先级**:中→高(建议安排在阶段 2 收尾时统一修复,作为 Step 2.X 独立任务)

**记录时间**:2026-05-09,Step 2.1d 故障注入测试发现
**位置**:index.html addStudent() 及相关 save 类函数

### 二维码列表不会自动重渲染

**现象**:buildQRList 只在 showDashboard 时调用一次。如果 owner 在 dashboard 已渲染后改变了 allStudents(新增学员、archiveCode 变化等),二维码列表保持旧状态,需要 owner 退出重新登录才会刷新。

**当前业务影响**:小。当前流程下 archiveCode 在登录时一次性迁移完成,后续不变。

**建议修复方向**:
- 在 saveData 成功后触发 buildQRList 重渲染
- 或在新增/编辑学员的回调里显式调用
- 或改造为响应式渲染模式

**优先级**:中(不影响当前业务,但属于潜在埋藏问题)
**记录时间**:2026-05-10,阶段 8 真机测试诊断时识别
**位置**:index.html doAdminLogin / buildQRList 调用链
