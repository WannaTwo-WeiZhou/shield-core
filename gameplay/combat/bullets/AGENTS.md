# gameplay/combat/bullets — AI 指令

这里负责弹幕实体、生成和波次编排。

- `wave_config.json` 是波次数据源。
- `wave_director.gd` 读取配置并广播波次生命周期事件。
- `bullet_spawner.gd` 负责按 pattern 生成子弹。
- `bullet.gd` 负责单个子弹移动、碰撞和反弹后的状态。
- 新增 pattern 时同步配置、生成逻辑和 Godot 启动检查。
