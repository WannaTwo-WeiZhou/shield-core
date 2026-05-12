# ShieldCore — 项目上下文

Godot 4.6.2 2D 竖屏格挡游戏。

## 项目信息

- **引擎**: Godot 4.6.2（GL Compatibility 渲染）
- **屏幕**: 640×960 portrait，`canvas_items` 拉伸模式
- **GitHub**: `github.com/WannaTwo-WeiZhou/shield-core`
- **主分支**: `main`
- **部署**: push 到 `main` 后 CI 自动构建 Web 包并发布到 `gh-pages` 分支

## 项目结构

| 目录 | 用途 |
|------|------|
| `ability/` | 能力系统核心（定义、实例、管理器、管线、联动、事件总线） |
| `player/` | 玩家逻辑（移动、格挡、能力消费层） |
| `bullet/` | 子弹系统 |
| `bomb/` | 炸弹系统 |
| `health/` | 生命值组件 |
| `experience/` | 经验值 / 升级系统 |
| `game_over/` | 游戏结束逻辑 |
| `start/` | 开始菜单 |
| `assets/` | 字体等资源 |

## Autoload

- **EventBus** (`ability/event_bus.gd`) — 战斗事件与能力系统事件总线
- **AbilityManager** (`ability/ability_manager.gd`) — 能力系统入口

## 核心架构

```
能力定义 (ability_definition.gd) → 静态元数据
能力实例 (ability_instance.gd) → 运行时持有与叠加
能力管理器 (ability_manager.gd) → 加载、升级三选一、重建管线
效果管线 (modifier_pipeline.gd) → 属性加成 + 标签效果 + 事件修饰器
联动解析器 (synergy_resolver.gd) → 按 required_abilities 激活联动
玩家 (player/player.gd) → 格挡/反弹流程中消费管线数据
```

## 编码规范

- **语言**: GDScript（中文注释）
- **缩进**: Tab
- **命名**:
  - 常量: `UPPER_CASE`（如 `BASE_SPEED: float = 400.0`）
  - 私有成员: 前导下划线 `_private_var`
  - 成员变量: `snake_case`
  - 场景节点引用: `@onready var node_name := $path/to/node`
- **类**: 使用 `class_name` 注册全局类型
- **工厂方法**: `static func from_dict(data: Dictionary) -> ClassName`
- **引用**: `preload("res://path")` 和 `get_node("/root/main/...")` 混用
- **类型**: 默认使用类型推断 `:=`，显式类型 `: Type` 用于重要变量

## 能力配置

- `ability/abilities_config.json` — 能力定义
- `ability/synergies_config.json` — 联动定义
- 新能力按「先配置、后接线、再验证」流程
- 能力效果属性键白名单在 `AbilityManager._apply_instance_to_pipeline()`

## 物理层

```
layer_1: player_core
layer_2: player_shield
layer_3: enemy_bullet
layer_4: player_bullet
```

## 关键命令

```bash
# 语法与启动检查
godot --headless --path . --quit

# 本地运行（需要 Godot 编辑器）
# 直接用 Godot 打开 project.godot
```

## 工作流（当前频道 #shield-core）

- Hermes 只负责协调、PR 管理、汇报
- 代码修改委托给 Claude Code CLI（`claude -p` 模式）
- 严格走 feature branch → PR → CI → merge 流程
- ⚠️ 大型变更（>5 文件或架构决策）必须先写 Plan → 用户确认后可执行

## 当前里程碑

1. **内循环爽感打磨**（6 个 open issues）— 视觉效果 + 新能力
2. **叙事规划 + 整合玩法**（1 个 open issue）— 叙事框架

详见 GitHub Issues: https://github.com/WannaTwo-WeiZhou/shield-core/issues
