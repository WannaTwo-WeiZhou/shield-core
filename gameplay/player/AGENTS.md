# gameplay/player — AI 指令

`gameplay/player/` 是玩家操作和战斗消费层。

## 职责

- 玩家移动、边界限制、触控摇杆和键盘输入。
- 护盾旋转、格挡、反弹和核心受击。
- 消费 `AbilityManager.pipeline` 的属性加成。
- 按 `ability_id` 消费行为型能力的 `per_level` 数据。
- 应用 `on_block`、`on_reflect` 等事件修饰器。

## 修改规则

- 不在玩家脚本中解析能力配置文件；只读取 `AbilityManager` 暴露的实例和管线。
- 新增事件修饰器 action 时，同步检查联动配置和实际触发上下文。
- 保持物理层语义：`player_core`、`player_shield`、`enemy_bullet`、`player_bullet`。
- 改护盾半径、旋转、反弹或碰撞时，验证核心受击、护盾格挡、反弹子弹和经验获取。
