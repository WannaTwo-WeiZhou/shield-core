# gameplay/combat/bomb — AI 指令

这里负责 B 弹清屏。

- `bomb_system.gd` 是主场景中的普通节点，不是 Autoload。
- `bomb_ui.gd` 只展示容量、冷却和可用状态。
- 容量和冷却加成从 `AbilityManager.pipeline` 读取。
- 使用 B 弹后通过 `EventBus.on_bomb_used` 通知其他模块。
