# ShieldCore — AI 指令根入口

默认使用简体中文回复用户；代码、命令、日志、API 名称和文件路径保留原文。

## 项目架构

ShieldCore 是 Godot 4.6.2 竖屏 2D 格挡生存游戏，入口场景是 `main.tscn`，导出目标是 Web。

- `core/`：全局基础设施，当前主要是 Autoload。
- `gameplay/`：玩法实现，包含能力、玩家、战斗、成长。
- `ui/`：流程界面，包含开始、暂停、游戏结束。
- `assets/`：跨模块共享资源。
- `.github/`：CI、PR preview、GitHub Copilot 指令。

## 分层指令

根路径只描述项目架构。进入子目录工作时，优先读取该目录及父目录的 `AGENTS.md`：

- `core/AGENTS.md`
- `gameplay/AGENTS.md`
- `gameplay/abilities/AGENTS.md`
- `gameplay/player/AGENTS.md`
- `gameplay/combat/AGENTS.md`
- `gameplay/progression/AGENTS.md`
- `ui/AGENTS.md`

Claude Code 读取同层 `CLAUDE.md`；GitHub Copilot 读取 `.github/copilot-instructions.md` 与 `.github/instructions/*.instructions.md`。

## 工程约定

- Godot 资源移动必须同步 `.tscn`、`.import`、`.uid` 和所有 `res://` 引用。
- 保持现有节点名、Autoload 名、能力 ID 和配置字段稳定，除非任务明确要求修改。
- 大型结构变更走 feature branch → PR → CI / preview checks。
- 修改既有文件前保持原编码与换行风格；新建 Markdown 默认 UTF-8 + LF。
