# gameplay/combat — AI 指令

`gameplay/combat/` 存放弹幕压力和 B 弹清屏。

## bullets

- `gameplay/combat/bullets/wave_config.json` 驱动波次节奏、持续时间、发射间隔、速度和 pattern。
- `wave_director.gd` 负责编排波次生命周期，并通过 `EventBus` 广播 prep / start / end。
- `bullet_spawner.gd` 负责生成子弹，`bullet.gd` 负责单个子弹行为。

## bomb

- `bomb_system.gd` 是场景节点，不是 Autoload。
- B 弹容量和冷却通过 `AbilityManager.pipeline` 读取 `bomb_capacity_bonus`、`bomb_recharge_seconds_bonus`。
- B 弹使用后通过 `EventBus.on_bomb_used` 通知其他系统。

## 修改规则

- 新增波次 pattern 时同步配置、生成逻辑和 headless 启动检查。
- 不让 B 弹系统直接管理玩家输入状态；需要跨模块反馈时发事件。
- 改子弹碰撞层时同步检查玩家核心、护盾、反弹子弹的 layer / mask。
