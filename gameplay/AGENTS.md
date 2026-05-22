# gameplay — AI 指令

`gameplay/` 存放实际玩法逻辑，按 feature 组织，不按脚本、场景、资源类型拆散。

## 目录职责

- `gameplay/abilities/`：能力配置、运行时实例、效果管线、联动、三选一和获得反馈。
- `gameplay/player/`：玩家移动、护盾、格挡、反弹和能力消费。
- `gameplay/combat/`：弹幕波次、子弹和 B 弹清屏。
- `gameplay/progression/`：生命、经验、升级触发和相关 UI。

## 修改规则

- 玩法变更优先落在所属 feature；只有跨 feature 的状态和事件才放到 `core/`。
- 能力效果分为属性管线型和行为型；不要把行为分支硬塞进配置解析层。
- 资源与场景放在对应 feature 目录，移动时同步所有 Godot 引用。
- 修改玩法后至少运行 Godot headless 启动检查。
