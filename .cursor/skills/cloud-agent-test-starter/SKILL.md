---
name: cloud-agent-test-starter
description: Cursor Cloud Agent 的最小测试启动 Skill，覆盖 shield-core 的运行、验证、配置开关与 CI 对齐流程。
---

在 `shield-core` 仓库中，当用户希望“快速让 Cloud Agent 上手并测试代码”时使用此 Skill。

## 目标

提供一套最小但可执行的测试运行手册，让 Cloud Agent 在不依赖人工试玩的前提下，完成改动后的基础验证。

## 仓库事实（仅使用本仓库真实信息）

- 引擎版本：Godot `4.6.2-stable`
- 类型：2D 竖屏 Web 游戏（640x960）
- 主场景：`main.tscn`
- CI 关键流程：`--import` + `Web` 导出（见 `.github/workflows/deploy-pages.yml`）
- 本仓库无账号登录流程、无远程 Feature Flag 服务（如 LaunchDarkly）  
  - 结论：`Not applicable in this repo`
  - 替代：使用 JSON 配置作为“行为开关”进行本地可控验证

## Cloud Agent 快速启动

1. 确认 Godot 与模板
   - 需要 Godot `4.6.2-stable`
   - 需要匹配的 Web export templates（`4.6.2.stable`）

2. 首次或资源变更后先导入
   - `godot --headless --import`

3. 运行主场景（非头less）
   - `godot --path . res://main.tscn`

4. CI 对齐的 Web 导出检查
   - `godot --headless --export-release "Web" build/web/index.html`

5. 字体依赖注意事项
   - 项目引用 `assets/fonts/NotoSansSC.ttf`
   - 若本地/临时环境缺失该文件，先补齐后再执行导入与导出检查，避免资源警告干扰测试结论

## 按代码区域组织的测试流程

### 1) `start/`（开场与启动）

- 主要触点
  - `start/background.tscn`
  - `start/hint_label.tscn`
- 变更后验证
  - 执行 `godot --headless --import`
  - 启动 `res://main.tscn`，确认场景可加载、无解析错误
- Agent 测试工作流（示例）
  - 修改开场场景节点或资源引用 -> 重新 `--import` -> 运行主场景 -> 检查无缺失资源/解析报错

### 2) `player/` 与 `bullet/`（核心循环）

- 主要触点
  - `player/player.tscn`
  - `player/player.gd`
  - `bullet/bullet.tscn`
  - `bullet/bullet.gd`
  - `bullet/bullet_spawner.gd`
- 变更后验证
  - `godot --headless --import`
  - `godot --path . res://main.tscn`
  - 若改动涉及导出可用性，再跑 Web 导出命令
- Agent 测试工作流（示例）
  - 修改移动/发射逻辑 -> 导入 -> 运行主场景检查脚本解析与场景装配 -> 导出 Web 确认可构建

### 3) `health/` 与 `experience/`（状态与 UI）

- 主要触点
  - `health/health.gd`
  - `health/health_ui.tscn`
  - `health/health_ui.gd`
  - `experience/experience.gd`
  - `experience/experience_ui.tscn`
  - `experience/experience_ui.gd`
  - `experience/experience_config.json`
- 变更后验证
  - 先 `--import`
  - 运行主场景确认 UI 相关场景与脚本加载正常
  - 需要发布一致性时执行 Web 导出
- Agent 测试工作流（示例）
  - 修改经验或血量 UI 绑定 -> 导入 -> 运行并检查无脚本/资源错误 -> 导出验证

### 4) `ability/`（能力系统）

- 主要触点
  - `ability/ability_manager.gd`
  - `ability/event_bus.gd`
  - `ability/ability_instance.gd`
  - `ability/ability_definition.gd`
  - `ability/modifier_pipeline.gd`
  - `ability/synergy_resolver.gd`
  - `ability/abilities_config.json`
  - `ability/synergies_config.json`
  - `ability/pick_ui/ability_pick_ui.tscn`
  - `ability/pick_ui/ability_card.tscn`
- 变更后验证
  - `godot --headless --import`
  - 运行主场景，检查能力配置加载与相关场景引用是否报错
  - 执行 Web 导出确保配置改动不会破坏构建
- Agent 测试工作流（示例）
  - 增加/修改 ability 配置 -> 导入 -> 运行检查配置读取与脚本解析 -> 导出验证

### 5) `game_over/`（结束流程）

- 主要触点
  - `game_over/game_over_ui.tscn`
  - `game_over/game_over_ui.gd`
- 变更后验证
  - `godot --headless --import`
  - 运行主场景确认 game over UI 资源引用正常
- Agent 测试工作流（示例）
  - 修改结束界面文案/节点 -> 导入 -> 运行检查解析与加载 -> 必要时导出验证

## “Feature Flag” 等价方案（本仓库）

本仓库不使用远程 Feature Flag 平台。请使用 JSON 配置做可控开关：

- `ability/abilities_config.json`
- `ability/synergies_config.json`
- `experience/experience_config.json`

安全 mock 策略：

1. 只做小范围、确定性配置改动（单字段或单条目）
2. 每次改动附带回滚说明（恢复原值或移除临时项）
3. 改动后固定执行：`--import` -> 主场景运行 -> Web 导出
4. 避免一次混入多个实验变量，保证失败时可快速定位

## CI 对齐最小验收清单（AI 可独立执行）

- 无资源引用断链（尤其 `.tscn` / `.gd` / `.json` 关联）
- `godot --headless --import` 成功
- `godot --headless --export-release "Web" build/web/index.html` 成功
- 变更涉及的场景/脚本可加载，无 parser errors

> 不要求在此 Skill 中执行人工试玩验收；以代码与构建可验证项为准。

## 发现新 runbook 后如何更新此 Skill

1. 新增经验记录位置
   - 将新命令、常见报错与修复步骤直接追加到本文件对应章节（优先“按代码区域”小节）
2. 何时升级为正式流程
   - 当某条临时修复在 2 次及以上改动中重复出现，即提升为标准步骤写入 Skill
3. 轻量版本记录约定
   - 在文件末尾维护简短 Changelog（`YYYY-MM-DD: one-line change`）
   - 仅记录“影响执行流程或验收标准”的更新

## Changelog

- 2026-04-28: 初始化 Cloud Agent 最小测试启动 Skill（按 shield-core 实际结构与 CI 流程定制）
