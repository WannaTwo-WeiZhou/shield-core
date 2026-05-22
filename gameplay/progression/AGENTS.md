# gameplay/progression — AI 指令

`gameplay/progression/` 存放生命、经验、升级触发和相关 UI。

## health

- `health.gd` 管理当前生命、最大生命和受击 / 治疗。
- `health_ui.gd` 管理分段血条，每格 `CELL_HP=10`。
- 能力选择反馈通过 `EventBus.on_pick_feedback` 接入，例如扩容扫光和恢复绿闪。

## experience

- `experience.gd` 根据 `experience_config.json` 管理 XP、等级和升级阈值。
- 升级时调用 `AbilityManager.on_player_level_up()`，进入能力候选流程。
- `experience_ui.gd` 只负责展示，不承载能力选择逻辑。

## 修改规则

- 改最大生命、治疗或经验奖励时，同步验证 UI 显示和能力反馈。
- 重开局后生命、经验和待选能力都应回到本局初始状态。
- 不在成长模块中直接决定能力效果；能力选择和管线由 `AbilityManager` 负责。
