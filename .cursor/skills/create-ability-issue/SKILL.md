---
name: create-ability-issue
description: Create a GitHub issue for exactly one ShieldCore ability using the repository's Ability Issue spec. Use when the user asks to create a 能力 issue, ability issue, or turn an ability discussion into an issue.
---

Use this skill when the user wants a single ability idea or discussion turned into a GitHub issue for this repository.

## Goal

Produce a complete, implementable ability issue in simplified Chinese, then create it on GitHub when write-capable credentials are available.

## Source of truth

Reuse the existing Copilot skill assets instead of inventing a second spec:

- Template: `.github/skills/create-ability-issue/ability_issue_template.md`
- Creation script: `.github/skills/create-ability-issue/create_github_issue.ps1`
- Reference skill: `.github/skills/create-ability-issue/SKILL.md`

## Required behavior

1. Confirm the request covers exactly one `ability_id`.
2. Map the discussion into the fixed template sections without deleting headings.
3. Ask focused follow-up questions before creating the issue if any of these sections are still too vague to implement:
   - `## 2.2 可表达范围与限制（Guardrails）`
   - `## 2.3 机制说明（Mechanics）`
   - `## 2.4 数值与公式（Numbers & Formula）`
   - `## 2.5 数据结构与配置（Config Schema）`
4. Generate the full issue body from `.github/skills/create-ability-issue/ability_issue_template.md`.
5. Generate or update the latest `## Execution Checklist (vN)` only after the issue is implementable.
6. If GitHub write access is available, create the issue with the repository script.
7. If creation is blocked, return the full Markdown body and the exact retry command.
8. Do not require runtime/manual gameplay validation in the issue. AI-owned validation should be limited to code changes and compile/build/export checks.

## Repository-specific rules

- Write issue prose in simplified Chinese unless a field is naturally English-only, such as `ability_id`, file paths, or config keys.
- Keep `ability_id` in `snake_case`.
- Use this repository's real ability architecture:
  - Ability definitions: `ability/abilities_config.json`
  - Synergy definitions: `ability/synergies_config.json`
  - Runtime orchestration: `AbilityManager` and `EventBus` autoload flow
  - Common consumers: `player/player.gd`, `bullet/bullet.gd`, `health/health.gd`, `experience/experience.gd`
- Do not copy generic paths from outside docs unless those files exist in this repo.
- In `## 2.7 测试与验收（Test & Acceptance）` and `### 3) Validation`, include only AI-owned checks such as code creation/modification and compile/build/export passing.

## Title rules

- New ability: `[Ability] <能力中文名> (<ability_id>)`
- Rework: `[Ability][Rework] <能力中文名> (<ability_id>)`
- Balance: `[Ability][Balance] <能力中文名> (<ability_id>)`

## Creation steps

1. Draft the body using `.github/skills/create-ability-issue/ability_issue_template.md`.
2. Save the generated body to a temporary Markdown file outside committed source, such as `/tmp/<ability_id>-issue.md`.
3. Create the issue from the repository root:

   ```powershell
   pwsh -File .github/skills/create-ability-issue/create_github_issue.ps1 -Title "<issue-title>" -BodyPath "<temp-body-path>"
   ```

4. Only pass `-Labels` when the labels are known to already exist in the repository.
5. In Cursor Cloud, do not use `gh issue create` for this repository because the `gh` CLI is read-only in this environment.

## Failure handling

- If GitHub credentials are missing, stop before the POST request and tell the user to provide GitHub HTTPS credentials through Git Credential Manager or set `GH_TOKEN` / `GITHUB_TOKEN`.
- If repository owner/repo cannot be inferred from `origin`, ask for them explicitly or rerun the script with `-Owner` and `-Repo`.
- If issue creation fails, show the exact error and return the full generated Markdown body so the user can paste it manually.
