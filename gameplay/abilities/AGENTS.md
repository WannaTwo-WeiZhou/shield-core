# gameplay/abilities — AI 指令

能力系统由配置、运行时实例、效果管线、联动解析和 UI 反馈组成。

## 路径

- 配置：`gameplay/abilities/config/abilities_config.json`
- 联动：`gameplay/abilities/config/synergies_config.json`
- 核心脚本：`gameplay/abilities/core/`
- 三选一 UI：`gameplay/abilities/pick_ui/`
- 中央获得反馈：`gameplay/abilities/feedback/`
- 系统入口：`core/autoload/ability_manager.gd`

## 能力规则

- 能力定义不使用 tags；联动只用 `required_abilities` 精确匹配能力 ID。
- 管线属性由 `AbilityManager._apply_instance_to_pipeline()` 白名单聚合。
- 当前白名单：`speed_bonus`、`bullet_speed_bonus`、`damage_bonus`、`block_xp_bonus`、`max_health_bonus`、`bomb_capacity_bonus`、`bomb_recharge_seconds_bonus`。
- 行为型能力由消费方按 `ability_id` 读取 `per_level`，常见消费方是 `gameplay/player/player.gd` 和 `gameplay/combat/bomb/bomb_system.gd`。
- 可重复能力需要显式 `repeatable: true`，当前代表是 `max_health_up`。

## 新增或修改能力

1. 先改 `abilities_config.json` 或 `synergies_config.json`。
2. 如果是新属性键，扩展管线白名单并在消费方读取。
3. 如果是行为型能力，在对应消费方按 `ability_id` 接线。
4. 如果需要 UI 反馈，订阅 `EventBus.on_pick_feedback`，不要把按能力反馈写进通用中央浮字。
5. 验证三选一、管线重建、联动触发、重开局清空状态。
