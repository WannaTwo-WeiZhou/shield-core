# ShieldCore — 项目上下文

Godot 4.6.2 2D 竖屏格挡生存游戏（移动格挡 + 经验升级 + 能力/联动 + 弹幕波次 + B 弹清屏）。

## 项目信息

- **引擎**: Godot 4.6.2（GL Compatibility 渲染）
- **屏幕**: 640×960 portrait，`canvas_items` 拉伸
- **GitHub**: `github.com/WannaTwo-WeiZhou/shield-core`
- **主分支**: `main`
- **部署**: push `main` → `deploy-pages.yml` → `gh-pages` 根目录
- **PR 预览**: `pr-preview.yml` — PR 每次推送构建 `pr-preview/pr-<n>/` 并评论链接；PR 关闭时清理目录并更新**全部**预览 marker 评论

## 项目结构

| 目录 | 用途 |
|------|------|
| `ability/` | 能力定义、实例、管理器、管线、联动、EventBus、三选一 UI、获得反馈 |
| `player/` | 移动、格挡/反弹、能力消费（属性 pipeline + 行为型 per_level） |
| `bullet/` | 弹幕、`bullet_spawner`、`wave_director`、`wave_config.json` |
| `bomb/` | B 弹清屏（`bomb_system.gd`，非 Autoload） |
| `health/` | `health.gd`、分段血条 `health_ui.gd` / `health_segment.gd`（`CELL_HP=10`） |
| `experience/` | 经验与升级 |
| `game_over/` | 游戏结束 |
| `start/` | 背景、提示、版本 |
| `pause/` | 暂停 UI + GM 模式（`pause_ui.gd`，调试直接 `select_ability`） |
| `assets/` | 共享字体等 |

## Autoload

- **EventBus** (`ability/event_bus.gd`) — 格挡、受伤、波次、B 弹、`on_ability_acquired`、`on_pick_feedback`、联动等
- **AbilityManager** (`ability/ability_manager.gd`) — 加载配置、三选一、管线重建；`ability_acquired` 供中央浮字

## 核心架构

```
能力定义 (ability_definition.gd) → 静态元数据 + per_level
能力实例 (ability_instance.gd) → 运行时持有与 repeatable 叠层
能力管理器 (ability_manager.gd) → 候选池、选择、重建管线
效果管线 (modifier_pipeline.gd) → 属性加成 + 运行时效果（event_modifier / runtime_flag）
联动解析器 (synergy_resolver.gd) → required_abilities 精确匹配
玩家 (player/player.gd) → pipeline 属性 + 按 ability_id 的行为逻辑 + 事件修饰器
B 弹 (bomb/bomb_system.gd) → pipeline 中 bomb_* 属性
波次 (bullet/wave_director.gd) → wave_config 驱动弹幕节奏
```

## 能力配置要点

- `ability/abilities_config.json` — 能力；可选 `narrative`；无 tags
- `ability/synergies_config.json` — 联动；仅 `required_abilities`
- **属性白名单**（`_apply_instance_to_pipeline`）：
  `speed_bonus`, `bullet_speed_bonus`, `damage_bonus`, `block_xp_bonus`, `max_health_bonus`, `bomb_capacity_bonus`, `bomb_recharge_seconds_bonus`
- **行为型**（示例）：`shield_reflect`, `counter_spiral`, `health_regen`, `crit_block`, `breathing_orbit` — 在 `player.gd` 用 `get_instance(id)` 读 `per_level`
- **可重复**：`max_health_up`（`repeatable: true`）
- **获得反馈**：中央浮字 ← `AbilityManager.ability_acquired`；按能力 UI ← `EventBus.on_pick_feedback`（如 `health_ui`：`max_health_up` 扫光、`health_regen` 绿闪）
- 流程：**先配置、后接线、再验证** — 详见 [README.md](README.md)

## 编码规范

- **语言**: GDScript（中文注释）
- **缩进**: Tab
- **命名**: 常量 `UPPER_CASE`；私有 `_prefix`；成员 `snake_case`；节点 `@onready`
- **类**: `class_name` 全局注册
- **引用**: `preload` + `get_node("/root/main/...")` 混用
- **类型**: 默认 `:=`，重要处显式 `: Type`

## 物理层

```
layer_1: player_core
layer_2: player_shield
layer_3: enemy_bullet
layer_4: player_bullet
```

## 关键命令

```bash
godot --headless --path . --quit
godot --headless --import
godot --headless --export-release "Web" build/web/index.html
```

## 工作流

- 大型变更（>5 文件或架构决策）先 Plan → 用户确认
- Feature branch → PR → CI → merge
- Copilot/Cursor 完整规范：`.github/copilot-instructions.md`

## 里程碑（概览）

内循环打磨（视觉/能力）与叙事整合 — 见 [GitHub Issues](https://github.com/WannaTwo-WeiZhou/shield-core/issues)
