# ShieldCore — Copilot Instructions

> **始终使用中文回复用户。** 代码注释、提交信息可保持英文，但与用户的对话一律使用简体中文。

Godot **4.6.2-stable**（GL Compatibility）2D 竖屏游戏，含完整 GDScript 玩法实现，导出 **Web** 并通过 GitHub Actions 部署到 **GitHub Pages**。UI 文案使用简体中文；编辑或新增文案时保留 CJK 字符串原样。

能力系统、配置字段与新增能力流程的**详细说明见仓库根目录 [README.md](../README.md)**；本文件侧重仓库布局、构建/CI 与编码约定。

## Project layout

- `project.godot` — 主场景 `res://main.tscn`，视口 640×960，`stretch_mode=canvas_items`。
- `main.tscn` — 入口：实例化 `player`、`bullet_spawner`、`wave_director`、UI、B 弹、能力三选一等。
- **Feature 目录**（按功能划分，场景+脚本+专属资源放同目录）：
  - `start/` — 背景、提示、版本标签
  - `player/` — 玩家与护盾
  - `bullet/` — 弹幕、`bullet_spawner.gd`、`wave_director.gd`、`wave_config.json`
  - `bomb/` — B 弹清屏与 UI
  - `health/`、`experience/`、`game_over/`、`pause/`
  - `ability/` — 能力核心、`pick_ui/`、`feedback/`
- `assets/fonts/NotoSansSC.ttf` — **未提交**；CI 下载。本地可自 [Google Fonts](https://github.com/google/fonts/raw/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf) 放置，或临时清空 `project.godot` 中 `gui/theme/custom_font`。
- `version.gd` — `MAJOR_VERSION` / `BUILD_NUMBER`；CI 导出前 patch 构建号。
- `export_presets.cfg` — `Web` 预设 → `build/web/index.html`；`script_export_mode=2`，`thread_support=false`。
- **Autoload**（在 `project.godot` 注册，非 `autoload/` 目录）：`EventBus`、`AbilityManager`。
- `.godot/`、`build/`、`dist/`、`assets/fonts/NotoSansSC.ttf` 已 gitignore。

## 资源组织规范（feature-based + Godot 官方命名）

- **文件名/目录名 `snake_case`**；场景内节点名 `PascalCase`；`class_name` 用 `PascalCase`。
- **按 feature 分目录**，勿按资源类型扁平堆放。
- **跨 feature 共享** → `assets/<type>/`（如 `assets/fonts/`）。
- **入口**：`main.tscn`、`icon.svg` 在根目录；第三方插件 → `addons/<plugin_name>/`。
- **移动资源优先用 Godot 编辑器**，以同步 `.import` 与 UID；命令行移动需同步 `.import` 或重建 `.godot/`。
- **引用优先 `uid://`**，避免硬编码 `res://` 路径。

## GDScript 约定

- 中文注释；**缩进 Tab**。
- 常量 `UPPER_CASE`；私有成员 `_leading_underscore`；成员 `snake_case`。
- 场景节点：`@onready var node_name := $path/to/node`。
- 重要类型可显式 `: Type`，其余用 `:=` 推断。
- 配置数据：`static func from_dict` / 实例 `from_dict`；能力工厂见 `ability_definition.gd`。
- 节点查找：`preload("res://...")` 与 `get_node("/root/main/...")` 混用均可，与现有代码一致。

## Build, run, test

无单元测试/ linter；勿擅自引入新工具链。

- **编辑器**：Godot **4.6.2-stable**（与 CI `GODOT_VERSION` 一致）。
- **运行**：F5 或 `godot --path . res://main.tscn`。
- **Headless 导入**：`godot --headless --import`（增删资源后）。
- **语法检查**：`godot --headless --path . --quit`
- **Web 导出**（需 4.6.2 导出模板）：
  `godot --headless --export-release "Web" build/web/index.html`

## CI / deployment

Composite action：`.github/actions/build-godot-web/`。改引擎版本时同步更新 workflow 中 `GODOT_VERSION` / `GODOT_TEMPLATE_VERSION` 与 `project.godot` 的 `config/features`。

发布到 **`gh-pages`**（Pages 源：`Branch: gh-pages / root`）：

| Workflow | 触发 | 行为 |
|----------|------|------|
| `deploy-pages.yml` | push `main` | 构建 Web 到 gh-pages **根目录**，保留 `pr-preview/` |
| `pr-preview.yml` | PR opened / synchronize / reopened | 构建 PR head → `pr-preview/pr-<n>/`，**每条推送新建**带 marker 的预览评论 |
| `pr-preview.yml` | PR closed | 删除预览目录，**更新该 PR 上所有**带 `<!-- shield-core-pr-preview -->` 的评论为下线说明 |

Fork PR 无写权限时跳过预览。本仓库 PR 预览**不依赖** approving review。

## 能力系统（摘要）

- 配置：`ability/abilities_config.json`、`ability/synergies_config.json`。
- 无 tags；联动仅 `required_abilities`。
- 属性白名单在 `AbilityManager._apply_instance_to_pipeline()`；行为型能力在 `player/player.gd` 等按 `ability_id` 读取。
- 新能力流程：**先配置、后接线、再验证** — 详见 README。

## Conventions

- **场景是组合单元**：小型 `.tscn` 由 `main.tscn` 实例化。
- **GL Compatibility + Web 无线程**：避免 Forward+ 专属特性与 `Thread` 依赖。
- **分辨率**：640×960 竖屏，`canvas_items` + `keep` 比例。
- **物理层**：`player_core` / `player_shield` / `enemy_bullet` / `player_bullet`（layer 1–4）。

## Ability Issue workflow

- 用户要「创建能力 issue」时，优先使用 **`/create-ability-issue`**（或 `.github/skills/create-ability-issue/`）。
- 信息不足（`Guardrails`、`Mechanics` 等仍为 `TBD`）时先追问，勿直接建 issue。
- 一个 issue 只覆盖一个 `ability_id`；标题：
  - 新能力：`[Ability] <中文名> (<ability_id>)`
  - 重做：`[Ability][Rework] ...`
  - 平衡：`[Ability][Balance] ...`
- 正文须含 `## Execution Checklist (vN)` 及固定四节（Files / Steps / Validation / Rollback）。
- 路径对齐本仓库：`ability/abilities_config.json`、`ability/synergies_config.json`（勿引用不存在的 `abilities/registry.gd`）。
- 可写 GitHub 时用 `.github/skills/create-ability-issue/create_github_issue.ps1`（凭据或 `GH_TOKEN` / `GITHUB_TOKEN`）。
