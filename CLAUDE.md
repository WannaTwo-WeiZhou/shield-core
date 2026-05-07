# shield-core — 项目说明

> 基于 Godot 4.3 的独立游戏项目。
> 主题：阿尔兹海默症护盾弹幕游戏 — 记忆护盾守护系统。

## 项目结构

- `ability/` — 能力系统（abilities_config.json、synergies_config.json）
- `scenes/` — Godot 场景文件（.tscn）
- `scripts/` — GDScript 代码
- 项目根目录含 `世界观设定.md` 文档

## 编码规范

1. 代码、配置文件必须使用 **UTF-8 无 BOM** 编码保存
2. 不得改变原文件已有的换行符风格（LF / CRLF 保持原样）
3. JSON 配置文件保持缩进一致，修改后验证 JSON 合法性
