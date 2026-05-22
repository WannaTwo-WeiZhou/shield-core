# ui — AI 指令

`ui/` 存放流程界面，不承载核心玩法状态。

## 目录职责

- `ui/start/`：背景、提示和版本标签。
- `ui/pause/`：暂停界面和 GM 调试入口。
- `ui/game_over/`：游戏结束流程和重新开始。

## 修改规则

- 暂停 GM 模式必须调用 `AbilityManager.select_ability()`，走正常能力获取、管线重建和反馈流程。
- 游戏结束后重新开始必须先调用 `AbilityManager.reset_for_new_run()`，再重载主场景。
- UI 文案默认简体中文；避免在流程 UI 中写玩法核心状态。
- UI 只编排场景流程和展示，不直接解析 gameplay 配置。
