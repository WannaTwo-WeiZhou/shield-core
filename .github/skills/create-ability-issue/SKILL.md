---
name: create-ability-issue
description: Create or update a GitHub issue for a single ability using the repository's Ability Issue spec. Use when the user asks to create a 能力 issue, ability issue, or to turn the current discussion into a GitHub issue.
---

Use this skill when the user wants the current ability discussion turned into a GitHub issue.

## Goal

Produce a complete ability issue that follows the repository spec, then create the issue on GitHub when write access is available.

## Required behavior

1. Confirm the request is about exactly one `ability_id`.
2. Collect the current discussion and map it into the fixed sections below.
3. If any of these are still too vague to implement, ask focused follow-up questions before creating the issue:
   - `## 2.2 可表达范围与限制（Guardrails）`
   - `## 2.3 机制说明（Mechanics）`
   - `## 2.4 数值与公式（Numbers & Formula）`
   - `## 2.5 数据结构与配置（Config Schema）`
4. Generate a full issue body from `ability_issue_template.md`.
5. Generate or update the latest `## Execution Checklist (vN)` only after the issue is implementable.
6. If the environment can write to GitHub, create the issue with the script in this skill directory.
7. If GitHub creation is blocked, return the full Markdown body and the exact command needed to retry.

## Repository-specific rules

- Keep all issue prose in simplified Chinese unless a field is naturally English-only (such as `ability_id` or file paths).
- Use the repository's actual ability architecture when writing file paths or implementation notes:
  - Core definitions live in `ability/abilities_config.json`
  - Synergy definitions live in `ability/synergies_config.json`
  - Runtime ability orchestration is handled by the `AbilityManager` and `EventBus` autoload-driven flow
- Do not copy generic example paths from outside docs unless they truly exist in this repo.
- Prefer concrete, repo-realistic paths in `Files to add / modify`, such as:
  - `ability/abilities_config.json`
  - `ability/synergies_config.json`
  - `ability/<feature_name>.gd`
  - `player/player.gd`
  - `bullet/bullet.gd`

## Title rules

- New ability: `[Ability] <能力中文名> (<ability_id>)`
- Rework: `[Ability][Rework] <能力中文名> (<ability_id>)`
- Balance: `[Ability][Balance] <能力中文名> (<ability_id>)`

## Creation steps

1. Draft the issue body using `ability_issue_template.md`.
2. Save the generated body to a temporary Markdown file outside the repository or in another non-committed temp location.
3. If a custom MCP server in this repository exposes a `create_issue` tool, prefer calling that tool with the generated title/body/labels.
4. If MCP is unavailable, run this script from the repository root:

   ```powershell
   pwsh -File .github/skills/create-ability-issue/create_github_issue.ps1 -Title "<issue-title>" -BodyPath "<temp-body-path>"
   ```

5. Only pass `-Labels` if you know those labels already exist in the repository.

## Failure handling

- If `GH_TOKEN` or `GITHUB_TOKEN` is missing, stop before the POST request and tell the user to set one of them.
- If MCP tool invocation fails, surface the exact failure, then retry with the local script only if the environment clearly supports it.
- If repository owner/repo cannot be inferred from `origin`, ask for them explicitly or rerun the script with `-Owner` and `-Repo`.
- If issue creation fails, show the exact error and return the generated Markdown body so the user can still paste it manually.
