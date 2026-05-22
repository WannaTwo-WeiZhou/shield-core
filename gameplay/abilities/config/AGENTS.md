# gameplay/abilities/config — AI 指令

这里存放能力和联动数据。

- `abilities_config.json`：能力定义，能力 ID 使用 `snake_case`。
- `synergies_config.json`：联动定义，只使用 `required_abilities`。
- 不新增 `tags`、`required_tags`、`affects_tags`、`responds_to_tags`。
- 新字段必须有明确消费方；否则不要只在配置里添加孤立字段。
- 改配置后验证 AbilityManager 加载、三选一候选和联动触发。
