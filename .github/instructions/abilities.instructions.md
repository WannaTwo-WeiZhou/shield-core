---
applyTo: "gameplay/abilities/**,core/autoload/ability_manager.gd"
---

# Ability Instructions

- 能力配置在 `gameplay/abilities/config/abilities_config.json`，联动配置在 `gameplay/abilities/config/synergies_config.json`。
- 能力定义不使用 tags；联动只用 `required_abilities` 精确匹配能力 ID。
- 管线属性必须经过 `AbilityManager._apply_instance_to_pipeline()` 白名单。
- 行为型能力在玩家、B 弹等消费方按 `ability_id` 读取 `per_level`。
- 新增能力按“先配置、后接线、再验证”处理。
