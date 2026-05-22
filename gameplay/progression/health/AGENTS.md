# gameplay/progression/health — AI 指令

这里负责生命状态和分段血条。

- `health.gd` 管理当前生命、最大生命、受击和治疗。
- `health_ui.gd` 根据 `CELL_HP=10` 管理分段显示。
- `health_segment.gd` 管理单格填充和动画反馈。
- 能力反馈通过 `EventBus.on_pick_feedback` 接入，例如扩容扫光、恢复绿闪。
- 改最大生命或治疗逻辑时同步检查 UI 分段和重开局状态。
