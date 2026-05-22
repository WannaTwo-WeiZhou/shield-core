# ShieldCore — GitHub Copilot Instructions

始终使用简体中文回复用户；代码、命令、日志、API 名称和路径保留原文。

ShieldCore 是 Godot 4.6.2 竖屏 2D 格挡生存游戏，入口场景是 `main.tscn`，Web 导出由 GitHub Actions 发布到 GitHub Pages。

## Project Architecture

- `core/`：Autoload 和全局基础设施。
- `gameplay/`：玩法实现，包含能力、玩家、战斗、成长。
- `ui/`：开始、暂停、游戏结束等流程界面。
- `assets/`：跨模块共享资源。
- `project.godot`：Godot 项目配置，主场景为 `res://main.tscn`。
- `export_presets.cfg`：Web 导出配置。

## Path-Specific Instructions

模块细节在 `.github/instructions/*.instructions.md` 中通过 `applyTo` 绑定路径：

- `core.instructions.md`
- `gameplay.instructions.md`
- `abilities.instructions.md`
- `player.instructions.md`
- `combat.instructions.md`
- `progression.instructions.md`
- `ui.instructions.md`
- `ci-docs.instructions.md`

根指令只保留架构约束；实现细节优先遵循命中路径的 instructions 文件。

## Global Rules

- Godot 资源移动必须同步 `.tscn`、`.import`、`.uid` 和 `res://` 引用。
- 保持现有节点名、Autoload 名、能力 ID 和配置字段稳定，除非任务明确要求修改。
- 不擅自引入新工具链、linter 或测试框架。
- PR 流程：feature branch → PR → preview checks，通过后再合并。
