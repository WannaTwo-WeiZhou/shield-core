---
applyTo: "gameplay/**"
---

# Gameplay Instructions

- `gameplay/` 按 feature 组织玩法，不按资源类型拆分。
- 玩法状态优先留在所属 feature；跨场景生命周期状态才放到 `core/`。
- 能力效果分为属性管线型和行为型，消费方按职责读取。
- 移动 Godot 资源时同步 `.tscn`、`.import`、`.uid` 和 `res://` 引用。
