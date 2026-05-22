---
applyTo: "ui/**"
---

# UI Instructions

- `ui/` 只承载流程界面和展示，不承载核心玩法状态。
- 暂停 GM 模式必须调用 `AbilityManager.select_ability()`。
- 游戏结束后重新开始必须先 `AbilityManager.reset_for_new_run()`，再重载主场景。
- UI 文案默认简体中文。
