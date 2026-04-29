# ShieldCore — Copilot Instructions

> **始终使用中文回复用户。** 代码注释、提交信息可保持英文，但与用户的对话一律使用简体中文。

Small **Godot 4.6**(GL Compatibility renderer) 2D game exported to the **Web** and deployed to **GitHub Pages** via CI. The repo currently contains only scene files (`.tscn`) — no GDScript yet — so most contributions will create the first scripts and scenes.

UI 文案使用简体中文；编辑或新增文案时保留 CJK 字符串原样。具体玩法与场景资源仍在迭代中，本文件不固定玩法定义和资源清单，请以仓库当前内容为准。

## Project layout

- `project.godot` — main scene is `res://main.tscn`, viewport 640×960, stretch `canvas_items` / `keep`.
- `main.tscn` — 游戏入口场景，新增玩法节点应挂在此处或被它实例化。
- `start/` — 启动/开场相关 feature 目录（当前包含 `background.tscn`、`hint_label.tscn`）。
- `assets/fonts/NotoSansSC.ttf` — **not committed**; downloaded by CI. Project references it via `gui/theme/custom_font`. Locally, place the font at `assets/fonts/NotoSansSC.ttf` (download from https://github.com/google/fonts/raw/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf) or temporarily clear that setting before opening the editor, otherwise the editor will warn about a missing resource.
- `export_presets.cfg` — single `Web` preset writing to `build/web/index.html`. `script_export_mode=2` (binary tokens), `thread_support=false`.
- `.godot/`, `build/`, `dist/`, and `assets/fonts/NotoSansSC.ttf` are gitignored.

## 资源组织规范（feature-based + Godot 官方命名）

- **命名一律 `snake_case`**：所有文件名、目录名、`.tscn`/`.gd`/`.gdshader` 等都使用小写下划线，遵循 Godot 官方 GDScript Style Guide（节点名在场景里仍使用 `PascalCase`，类名使用 `PascalCase`）。
- **按 feature 分目录，而非按资源类型分目录**。每个功能（如 `start/`、未来的 `player/`、`enemies/zombie/`、`ui/main_menu/` 等）拥有独立目录，把该 feature 的场景、脚本、专属图片/音频放在一起，便于整体迁移与删除。
- **跨 feature 共享资源放 `assets/`**：字体、通用音效、全局图集、shader 等不属于单一 feature 的素材集中到 `assets/<type>/`（如 `assets/fonts/`、`assets/audio/sfx/`）。
- **入口与全局**：`main.tscn` 与 `icon.svg` 留在仓库根目录；未来的 autoload 单例统一放 `autoload/`；第三方插件必须放在 `addons/<plugin_name>/`（Godot 强制约定）。
- **移动/重命名资源用 Godot 编辑器操作**，让其同步更新 `.import` 元数据与 `uid_cache`；如果只能命令行操作，确保同名 `.import` 同步移动并删除 `.godot/` 让其重建。
- **引用资源优先使用 `uid://`**，不要硬编码 `res://` 路径，路径变化时不会断链。

## Build, run, test

There are no unit tests, linters, or formatters configured. Do not introduce new tooling unless asked.

- **Open in editor:** open the folder with Godot **4.6.2-stable** (matches `GODOT_VERSION` in CI). The first open triggers `--import` and populates `.godot/`.
- **Run the game:** F5 in the editor (main scene is `main.tscn`), or headless:
  `godot --path . res://main.tscn`
- **Headless reimport** (use after adding/removing assets, mirrors CI):
  `godot --headless --import`
- **Web export** (mirrors CI; requires the matching export templates installed for 4.6.2.stable):
  `godot --headless --export-release "Web" build/web/index.html`

## CI / deployment

The shared build steps live in the composite action `.github/actions/build-godot-web/`. It downloads Godot **4.6.2-stable** + export templates, fetches Noto Sans SC into `assets/fonts/`, runs `--import`, exports the `Web` preset to `build/web/`, and adds `.nojekyll`. When changing the engine version, bump both `GODOT_VERSION` (e.g. `4.6.2-stable`) and `GODOT_TEMPLATE_VERSION` (dot form, e.g. `4.6.2.stable`) in the workflow files, and update `config/features` in `project.godot`.

Two workflows publish to the **`gh-pages` branch** (Pages source must be set to `Branch: gh-pages / root` in the repo settings):

- `.github/workflows/deploy-pages.yml` — on every push to `main`, builds the Web export and replaces the gh-pages root, while preserving `pr-preview/` so open previews stay alive.
- `.github/workflows/pr-preview.yml` — when a PR receives an **approving review** (`pull_request_review` with `state == approved`), builds the PR head and publishes it to `gh-pages` under `pr-preview/pr-<number>/`, then comments the preview URL on the PR. When the PR is closed (merged or not), the same workflow removes that sub-directory. Forks are skipped because they do not have write access to the gh-pages branch.

## Conventions

- **Scenes are the unit of composition.** 以小型 `.tscn` 为构建单位，由 `main.tscn` 实例化或挂载，避免纯代码构建节点树。
- **Stable UIDs.** Each scene declares a `uid://…` and other scenes reference it by UID. When creating scenes, let Godot generate UIDs (don't hand-edit them) and reference scenes via `uid://` in `ext_resource` / `preload`, not raw paths, so renames don't break links.
- **Renderer constraints.** GL Compatibility + no thread support in the Web export — avoid features that require Forward+/Mobile renderers or `Thread`/threaded resource loading.
- **Resolution.** Design for 640×960 portrait with `stretch_mode=canvas_items, aspect=keep`. Position UI relative to that viewport.
- **EditorConfig.** UTF-8, no other rules; preserve existing line endings of files you edit.
- When adding GDScript, keep `script_export_mode=2` working — i.e. plain `.gd` files referenced from scenes; don't rely on editor-only tooling at runtime.

## Ability Issue workflow

- 当用户提到“创建能力 issue”“新建 ability issue”“根据讨论结果创建这个能力的 issue”等意图时，优先使用项目指令 **`/create-ability-issue`**。
- 创建前必须先检查信息是否达到可执行程度；如果 `Guardrails`、`Mechanics`、`Numbers & Formula`、`Config Schema` 仍有关键 `TBD`，先追问，不要直接创建 GitHub issue。
- 一个 ability issue 只允许覆盖一个 `ability_id`。标题遵循：
  - 新能力：`[Ability] <能力中文名> (<ability_id>)`
  - 重做：`[Ability][Rework] <能力中文名> (<ability_id>)`
  - 平衡：`[Ability][Balance] <能力中文名> (<ability_id>)`
- Issue 正文必须保留固定章节标题，并生成最新的 `## Execution Checklist (vN)`；其中 4 个小节顺序固定为：
  1. `Files to add / modify`
  2. `Implementation steps`
  3. `Validation`
  4. `Rollback / Safety`
- 模板中的默认路径要优先对齐本仓库真实结构：能力主配置位于 `ability/abilities_config.json`，联动配置位于 `ability/synergies_config.json`，不要套用不存在的 `abilities/registry.gd` 等示例路径。
- 当环境允许写入 GitHub issue 时，优先使用 `.github/skills/create-ability-issue/create_github_issue.ps1` 创建 issue；该脚本会优先复用本机 Git Credential Manager 中的 GitHub HTTPS 凭据，再回退到 `GH_TOKEN` / `GITHUB_TOKEN`。
- 如果缺少 GitHub HTTPS 凭据且也没有环境变量 token，则返回完整 Markdown 正文与重试命令，而不是只给片段摘要。
