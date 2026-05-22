# gameplay/abilities/feedback — AI 指令

这里是通用能力获得反馈。

- `ability_feedback.gd` 监听 `AbilityManager.ability_acquired`，显示中央浮字。
- `speed_lines_feedback.gd` 监听 `EventBus.on_pick_feedback`，speed_boost 专属：3 秒全屏放射速度线动画。使用 `_draw()` + 三角形几何，非 shader，兼容 GL Compatibility。
- 按能力定制反馈不要写在这里；应由对应 feature 监听 `EventBus.on_pick_feedback`。
- 保持反馈非阻塞，不影响升级选择和游戏流程。
