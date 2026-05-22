---
applyTo: "gameplay/player/**"
---

# Player Instructions

- 玩家层负责移动、护盾、核心受击、格挡、反弹和能力消费。
- 不在玩家脚本中解析能力配置文件；读取 `AbilityManager` 的实例和 pipeline。
- 新增事件修饰器 action 时同步检查联动配置和上下文。
- 改碰撞或反弹时验证 `player_core`、`player_shield`、`enemy_bullet`、`player_bullet` 的 layer / mask。
