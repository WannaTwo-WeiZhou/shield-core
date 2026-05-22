# gameplay/abilities/core — AI 指令

这里是能力系统的纯逻辑层。

- `ability_definition.gd` 只负责静态定义解析。
- `ability_instance.gd` 只负责运行时持有能力和 repeatable 叠层。
- `modifier_pipeline.gd` 只负责聚合属性、事件修饰器和运行时标记。
- `synergy_resolver.gd` 只根据 `required_abilities` 评估联动。

不要在 core 脚本里写 UI 展示或玩家具体行为；行为由消费方读取能力实例后实现。
