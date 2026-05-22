# ShieldCore

ShieldCore 是一款 Godot 4.6.2 制作的 2D 竖屏格挡生存游戏。玩家移动核心、借助旋转护盾格挡压力轨迹，在不断增强的弹幕波次中尽可能延缓被空白吞噬。

## 游戏玩法

- **核心目标**：维持“清醒残余”的存续时间。核心被命中会损失生命，生命耗尽后本轮结束。
- **移动与格挡**：玩家控制核心移动，护盾围绕核心旋转；用护盾挡住弹幕可获得经验。
- **波次生存**：弹幕由波次配置驱动，节奏、密度、速度和形态会随时间变化。
- **经验升级**：格挡和摧毁威胁会积累经验；升级时进入能力三选一。
- **能力与联动**：能力可改变移动、护盾、生命、经验、B 弹等行为；特定能力组合会触发联动效果。
- **B 弹清屏**：玩家可消耗充能清理当前压力轨迹，作为高压阶段的容错手段。
- **调试入口**：暂停菜单包含 GM 模式，可直接选择能力验证构筑和反馈。

## CI 与发布

- **主站部署**：push 到 `main` 后，`.github/workflows/deploy-pages.yml` 构建 Web 包并发布到 `gh-pages` 根目录。
- **PR 预览**：PR opened / synchronize / reopened 时，`.github/workflows/pr-preview.yml` 构建 PR 版本并发布到 `pr-preview/pr-<number>/`，同时评论预览链接。
- **预览清理**：PR closed 时清理对应预览目录，并更新该 PR 下所有带 `<!-- shield-core-pr-preview -->` 标记的评论。
- **Fork PR**：无仓库写权限的 fork PR 会跳过预览构建与清理。
- **构建环境**：CI 使用 Godot 4.6.2-stable、Web 导出模板和 composite action `.github/actions/build-godot-web/`。

常用本地检查命令：

```bash
godot --headless --path . --quit
godot --headless --import
godot --headless --export-release "Web" build/web/index.html
```

## 世界观简述

游戏主体发生在一位阿尔兹海默症老人发作时的妄想层。现实中的照护、声音、关系压力和病症波动，被翻译成不断变形的场景、弹幕轨迹、护盾边界和空白侵蚀。玩家维持的不只是血量，而是一段仍能被称作“自我”的时间。

儿子一家是现实锚点，护盾是这份照护在妄想层中的形态；弹幕是外界刺激与内在恐惧被威胁化后的压力轨迹；升级和能力选择则代表短暂的认知稳定窗口。

完整设定见 [世界观设定.md](世界观设定.md)。
