# gameplay/progression/experience — AI 指令

这里负责 XP、等级和升级触发。

- `experience_config.json` 定义经验阈值和奖励参数。
- `experience.gd` 管理 XP、等级和升级信号。
- 升级时调用 `AbilityManager.on_player_level_up()`，不要直接打开能力 UI。
- `experience_ui.gd` 只负责展示。
- 改经验来源或阈值时验证升级三选一触发次数。
