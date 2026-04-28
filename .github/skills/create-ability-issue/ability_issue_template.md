# [Ability] 能力中文名 (ability_id)

> 一个 Issue 只讨论一个 `ability_id`。未确定的内容填写 `TBD`，不要删除固定章节标题。

## 2.1 概览（Overview）
- 能力中文名：TBD
- ability_id（snake_case）：TBD
- 类型：TBD
- 稀有度/权重：TBD
- 设计意图（1 句话）：TBD
- 一句话 UI 文案：TBD

## 2.2 可表达范围与限制（Guardrails）
- 允许触发事件：TBD
- 允许修改属性：TBD
- 禁止事项：
  - TBD

## 2.3 机制说明（Mechanics）
- 触发条件：TBD
- 效果：TBD
- 叠加/升级规则：TBD
- 互斥/联动：TBD
- 失败/边界情况：TBD

## 2.4 数值与公式（Numbers & Formula）
- 核心公式：TBD
- 参数表：TBD
- 数值边界：TBD

## 2.5 数据结构与配置（Config Schema）
- 配置文件路径（预期）：TBD（优先对齐本仓库真实路径，如 `ability/abilities_config.json`、`ability/synergies_config.json` 或新增的 feature 目录）
- 必填字段：TBD
- 可选字段：TBD
- 默认值：TBD
- 注意：能力定义不再包含 `tags / affects_tags / responds_to_tags` 字段；联动条件统一通过 `required_abilities`（能力 ID 精确匹配）声明，禁止使用 `required_tags`。

## 2.6 实现方案（Implementation Plan）
- 代码入口/挂载方式：TBD
- 依赖的系统：TBD
- 事件订阅/派发点：TBD
- 性能注意事项：TBD
- 兼容性注意事项：TBD

## 2.7 测试与验收（Test & Acceptance）
- AI 侧交付检查：
  - 代码创建/修改：TBD
  - 编译 / 构建 / 导出通过：TBD
- 预期结果：TBD
- 失败时的排查点：TBD

## 2.8 变更记录（Changelog within Issue）
- YYYY-MM-DD：创建或更新 Issue。

---

## Execution Checklist (v1)

### 1) Files to add / modify
- [ ] TBD

### 2) Implementation steps
- [ ] TBD

### 3) Validation
- [ ] AI：代码创建/修改完成
- [ ] AI：编译 / 构建 / 导出通过

### 4) Rollback / Safety
- [ ] TBD
