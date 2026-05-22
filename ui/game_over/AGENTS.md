# ui/game_over — AI 指令

这里负责游戏结束和重新开始。

- 重新开始前必须调用 `AbilityManager.reset_for_new_run()`。
- 重置能力状态后再 `get_tree().reload_current_scene()`。
- 不在 game over UI 中直接重置玩家、生命、经验细节；这些由场景重建和各节点 `_ready()` 负责。
