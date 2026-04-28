---
name: brainstorm-ability
description: 用于头脑风暴 ShieldCore 的新增能力或修改现有能力。先复盘现有能力清单，提出多个候选方案，再精简成一份可落地的总结；若用户确认，则交接给 create-ability-issue 创建 GitHub issue。
---

当用户希望“头脑风暴新能力 / 修改能力 / brainstorm ability / 想点子 / 给几个能力建议”等开放式构想时使用此 Skill。它是 `create-ability-issue` 的上游：先发散讨论，再收敛成可被 issue 化的单一能力。

## 目标

帮助用户在 ShieldCore 现有能力体系内，快速产出多个可比较的能力候选，并最终精简成一份足够具体、可直接落入 `ability/abilities_config.json` 与 `ability/synergies_config.json` 的总结。

## 输入与边界

- 输入可以非常模糊（“想加点反击系的东西”），也可以是明确的修改请求（“调整 shield_reflect 的反弹概率”）。
- 输出**不直接**修改任何代码或配置文件，只产出讨论纪要与候选方案。
- 一次会话允许讨论多个候选，但**最终只能精简成 1 条**作为下游 issue 的素材（`create-ability-issue` 要求单一 `ability_id`）。
- 用中文与用户对话；`ability_id`、字段名、文件路径保持英文/`snake_case`。

## 仓库事实（仅使用本仓库真实信息）

- 能力定义：`ability/abilities_config.json`
- 协同定义：`ability/synergies_config.json`
- 运行时编排：`ability/ability_manager.gd` + `ability/event_bus.gd`
- 常见消费者：`player/player.gd`、`bullet/bullet.gd`、`health/health.gd`、`experience/experience.gd`
- 协同匹配规则：仅按 `required_abilities`（精确 `ability_id` 匹配），**不要**引入 `tags / required_tags / affects_tags`。
- 能力字段以现有条目为准（如 `id / name / description / rarity / weight / max_level / repeatable / per_level`）；不要凭空新增字段族。

## 执行流程

按以下 4 步执行，每一步都要在回复中明确分节展示，方便用户对照确认。

### Step 1 — 总结现有能力（Recap）

读取 `ability/abilities_config.json` 与 `ability/synergies_config.json`，输出一张紧凑表格，至少包含：

- `id`（英文）
- 中文名
- 稀有度 / 权重
- 一句话机制摘要
- 该能力当前参与的协同（若有）

如果用户已经指定了改造目标（例如 `shield_reflect`），额外用一段 2–4 行文字说明该能力当前的：触发条件、关键数值、与其他能力的耦合点。

### Step 2 — 给出多个建议（Ideate）

针对用户意图，给出 **3–5 个**候选方案。每个候选必须具备最小可比性，建议字段：

- 候选编号与候选名（中文）
- 建议 `ability_id`（`snake_case`）
- 类别：`新增` / `重做(rework)` / `数值调整(balance)`
- 触发与机制一句话说明
- 关键数值草案（概率、数值、CD、持续时间等，给具体数字而非“适当”这种模糊词）
- 与现有能力的协同点或冲突点（引用现有 `id`）
- 风险 / 失衡担忧（一句话）

要求：

- 候选之间在风格、风险、复杂度上拉开差异，避免“同一思路换皮”。
- 每个候选都必须能被现有 `AbilityManager` + `EventBus` 体系实现，不要依赖未实现的子系统。
- 若有候选会破坏现有协同规则（例如试图引入 tag 匹配），明确标注“需先扩展系统”。

### Step 3 — 精简总结（Converge）

引导用户从 Step 2 中选定 1 个方向（如果用户未明确，主动推荐 1 个并说明理由），然后输出一份**精简总结块**，字段固定如下，便于直接喂给 `create-ability-issue`：

```
ability_id: <snake_case>
title_type: 新增 | Rework | Balance
中文名: <name>
一句话定位: <one-liner>
触发与机制: <2-4 句>
关键数值: <列点，给出具体数字>
配置字段建议: <per_level 字段列表与含义>
与现有能力协同/冲突: <引用具体 id；若涉及 synergy，给出 required_abilities 数组>
预期风险: <1-2 条>
开放问题: <仍需用户确认的点；若没有写“无”>
```

精简块出现后，本 Skill 的发散阶段结束。

### Step 4 — 询问是否创建 issue（Handoff）

检查 `.cursor/skills/create-ability-issue/SKILL.md` 是否存在（或顶层 skills 列表中是否包含 `create-ability-issue`）：

- **存在**：在回复末尾用一句话明确询问，例如：
  > 是否需要基于上面的精简总结，调用 `create-ability-issue` 创建 GitHub issue？回复“确认 / 创建 issue / yes”即开始。
- **不存在**：仅提示“当前仓库未提供 `create-ability-issue` Skill，可手动复制上面精简总结去建 issue”，不要伪造创建动作。

收到用户的肯定回复后：

1. **不要**重新发散；直接以 Step 3 的精简总结作为输入。
2. 按 `create-ability-issue/SKILL.md` 的要求补全模板缺口（特别是 2.2 / 2.3 / 2.4 / 2.5 节）。如有缺口，**先**回到用户做最少必要追问，再进入 issue 草稿。
3. 按 `create-ability-issue` 的 “Creation steps” 创建 issue（草稿写入 `/tmp/<ability_id>-issue.md`，再用 `pwsh -File .github/skills/create-ability-issue/create_github_issue.ps1` 调用）。
4. 若 GitHub 写权限不可用，按 `create-ability-issue` 的失败处理路径返回完整 Markdown 与重试命令。

如果用户回复否定或暂不创建：保留精简总结，结束流程，不做任何文件改动。

## 严禁事项

- 不要在 Step 1–3 期间修改 `ability/*.json` 或任何代码文件。
- 不要在用户**显式确认**前调用 `create-ability-issue` 或执行创建脚本。
- 不要把多个能力打包进同一个 issue（下游 Skill 强约束：单一 `ability_id`）。
- 不要重新引入 `tags / required_tags / affects_tags` 之类已被废弃的字段。
- 不要在 issue 验收（`## 2.7` / `### 3) Validation`）里加入需要人工试玩的步骤；保持 AI 可独立执行（编译/导入/Web 导出）。

## 输出风格

- 中文为主；字段名、`ability_id`、文件路径保持英文。
- 优先使用列表与小表格，避免长段落。
- 数值一律给具体值（如 `0.25`、`1.5s`、`+10 HP`），不要写“适当”“略微”这类模糊措辞。
- 在每一步开头加上明确的小标题（例如 `## Step 2 — 候选方案`），方便用户回看。

## Changelog

- 2026-04-28: 初始化 brainstorm-ability Skill（覆盖 recap → ideate → converge → handoff 流程，并与 create-ability-issue 对齐）。
