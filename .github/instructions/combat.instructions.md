---
applyTo: "gameplay/combat/**"
---

# Combat Instructions

- `gameplay/combat/bullets/` 管波次、子弹生成和子弹行为；`wave_config.json` 是波次数据源。
- `gameplay/combat/bomb/` 管 B 弹清屏；`bomb_system.gd` 是场景节点，不是 Autoload。
- B 弹容量和冷却通过 `AbilityManager.pipeline` 读取。
- 跨模块反馈使用 `EventBus`，不要让战斗系统直接改 UI 或玩家输入状态。
