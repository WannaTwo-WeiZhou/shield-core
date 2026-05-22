# core — AI 指令

`core/` 存放跨场景生命周期的基础设施。当前核心是 Godot Autoload。

## Autoload

- `core/autoload/event_bus.gd` 注册为 `EventBus`，负责跨模块事件广播。
- `core/autoload/ability_manager.gd` 注册为 `AbilityManager`，负责能力定义加载、候选生成、能力实例、管线重建和联动评估。
- Autoload 不会随 `get_tree().reload_current_scene()` 自动重置。

## 修改规则

- 改 `AbilityManager` 时同时考虑玩家、能力 UI、暂停 GM、游戏结束重开局。
- 重开局状态必须通过 `AbilityManager.reset_for_new_run()` 清理。
- 新增事件优先放在 `EventBus`，事件名保持语义明确，避免让 feature 直接互相查找。
- 不在 Autoload 中保存场景节点的长期强依赖；需要引用时由场景节点在 `_ready()` 注册，重开局时清空。
