# gameplay/abilities/pick_ui — AI 指令

这里是升级三选一 UI。

- `ability_pick_ui.gd` 只负责展示候选和提交选择。
- `ability_card.gd` 只负责单张能力卡片展示。
- 选择能力必须调用 `AbilityManager.select_ability()`，不要绕过能力管理器。
- UI 文案来自能力定义，缺失时优雅降级为能力 ID。
