---
applyTo: "gameplay/progression/**"
---

# Progression Instructions

- `gameplay/progression/health/` 管生命、最大生命、分段血条和按能力 UI 反馈。
- `gameplay/progression/experience/` 管 XP、等级、阈值和升级触发。
- 升级进入能力候选流程时调用 `AbilityManager.on_player_level_up()`。
- 改生命或经验逻辑时同步验证 UI、能力反馈和重开局状态。
