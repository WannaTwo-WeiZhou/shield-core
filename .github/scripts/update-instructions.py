#!/usr/bin/env python3
"""
Post-merge: sync AI instruction files based on PR changes using DeepSeek.

Triggered by GitHub Actions on PR merge to main.
- Fetches PR diff and changed file list
- Sends to DeepSeek with function calling
- DeepSeek reads relevant instruction files and proposes updates
- Applies changes, commits to a new branch, creates a PR for human review
"""

import os
import sys
import json
import logging
import subprocess
from pathlib import Path

import requests

# ── Config ──────────────────────────────────────────────────────────────────

REPO = os.environ["GITHUB_REPOSITORY"]
OWNER, REPO_NAME = REPO.split("/", 1)
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
DEEPSEEK_API_KEY = os.environ["DEEPSEEK_API_KEY"]
PR_NUMBER = os.environ.get("PR_NUMBER", os.environ.get("MERGE_PR_NUMBER", ""))
WORK_DIR = Path(os.environ.get("GITHUB_WORKSPACE", "."))
BRANCH_NAME = f"ai/sync-instructions-pr-{PR_NUMBER}" if PR_NUMBER else "ai/sync-instructions"

GITHUB_API = "https://api.github.com"
DEEPSEEK_API = "https://api.deepseek.com/v1/chat/completions"
MAX_TOOL_ROUNDS = 10  # safety valve

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ── Instruction file patterns ───────────────────────────────────────────────

INSTRUCTION_GLOBS = [
    "**/AGENTS.md",
    "**/CLAUDE.md",
    ".github/copilot-instructions.md",
    ".github/instructions/*.instructions.md",
]

SYSTEM_PROMPT = """你是 ShieldCore（Godot 2D 格挡生存游戏）的 AI 指令文件维护者。

## 你的任务

收到一个已合并的 PR 的 diff，分析变更内容，判断哪些 AI 指令文件需要更新以保持文档准确。

## 指令文件约定

项目有 3 类指令文件：

1. **AGENTS.md** — 模块级 AI 指令，描述架构、规则、约定。内容详细。
2. **CLAUDE.md** — Claude Code 入口，与同层 AGENTS.md 配对，格式固定：
   ```
   # <路径> — Claude Code

   @AGENTS.md
   ```
3. **.github/instructions/*.md** — GitHub Copilot 指令，有 frontmatter（applyTo 路径绑定）+ 规则列表。根 `copilot-instructions.md` 是总入口。

## 何时更新

**需要更新：**
- PR 新增了模块/目录 → 在父级 AGENTS.md 目录列表中补充
- PR 改变了架构模式 → 更新对应 AGENTS.md 的架构描述
- PR 引入了新的编码规则或约定 → 添加到对应 AGENTS.md 的规则区
- PR 新增/移除/重命名 Autoload、场景、配置文件 → 更新路径引用
- PR 修改了 frontmatter `applyTo` 的覆盖范围 → 更新 .instructions.md
- PR 新增了步骤流程（如"新增能力"的步骤）→ 在流程列表追加新步骤

**不需要更新：**
- 纯 bug 修复、变量重命名、代码格式化、注释调整
- 不改变约定的单文件修改
- Godot 资源文件的自动变更（.import, .uid）

## 工作流程

1. 分析 PR diff 中的文件变更和内容改动
2. 用 `read_instruction_file` 读取你认为可能受影响的指令文件
3. 用 `update_instruction_file` 更新需要修改的文件（传完整新内容）
4. 保持原有格式、语言风格（简体中文）和编码不变
5. 只更新确实过时的部分，不要改写无关内容

## 重要提醒

- **先读后改** — 绝对不要在不读取文件内容的情况下直接调用 update_instruction_file
- **最小改动** — 只修改 PR 影响到的部分，保留其余内容完全不变
- **CLAUDE.md 格式** — 保持 `@AGENTS.md` 导入模式，仅当同层 AGENTS.md 不存在或改名时才改 CLAUDE.md
- **frontmatter 格式** — .instructions.md 的 `applyTo` 字段保持原样，除非 PR 明确变更了模块边界
- 如果分析后认为无需更新任何文件，直接回复 "无需更新" 即可"""


def github_api(path: str, method: str = "GET", data: dict | None = None) -> dict:
    """Call GitHub REST API."""
    url = f"{GITHUB_API}{path}"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
    }
    if method == "GET":
        resp = requests.get(url, headers=headers, timeout=30)
    elif method == "POST":
        resp = requests.post(url, headers=headers, json=data, timeout=30)
    else:
        raise ValueError(f"Unsupported method: {method}")
    if resp.status_code >= 400:
        log.error(f"GitHub API error {resp.status_code}: {resp.text[:500]}")
        raise RuntimeError(f"GitHub API error: {resp.status_code}")
    return resp.json()


def get_pr_info() -> dict:
    """Fetch PR metadata from GitHub."""
    if not PR_NUMBER:
        # Try to find the merge commit's PR
        merge_sha = os.environ.get("GITHUB_SHA", "")
        if merge_sha:
            commits = github_api(
                f"/repos/{REPO}/commits/{merge_sha}/pulls",
            )
            if commits:
                info = commits[0]
                log.info(f"Found PR #{info['number']} from merge commit {merge_sha[:7]}")
                return info
        raise RuntimeError("PR_NUMBER not set and could not infer from merge commit")

    return github_api(f"/repos/{REPO}/pulls/{PR_NUMBER}")


def get_pr_diff() -> str:
    """Fetch the PR diff from GitHub."""
    if not PR_NUMBER:
        raise RuntimeError("Cannot fetch diff without PR_NUMBER")
    url = f"{GITHUB_API}/repos/{REPO}/pulls/{PR_NUMBER}"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.diff",
    }
    resp = requests.get(url, headers=headers, timeout=60)
    if resp.status_code >= 400:
        log.error(f"GitHub API error {resp.status_code}: {resp.text[:500]}")
        raise RuntimeError(f"Failed to fetch PR diff: {resp.status_code}")
    return resp.text


def get_pr_files() -> list[str]:
    """Get list of changed files in the PR."""
    files = github_api(f"/repos/{REPO}/pulls/{PR_NUMBER}/files?per_page=100")
    return [f["filename"] for f in files]


def read_instruction_file(path: str) -> str:
    """Read an instruction file from the working directory."""
    full_path = WORK_DIR / path
    if not full_path.exists():
        return f"[文件不存在: {path}]"
    try:
        return full_path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return full_path.read_text(encoding="utf-8-sig")


def update_instruction_file(path: str, content: str) -> str:
    """Update an instruction file — store in memory for later commit."""
    full_path = WORK_DIR / path
    full_path.parent.mkdir(parents=True, exist_ok=True)
    full_path.write_text(content, encoding="utf-8")
    log.info(f"Updated: {path}")
    return f"已更新: {path}"


def find_existing_instruction_files() -> list[str]:
    """Find all existing instruction files in the workspace."""
    files = []
    for glob in INSTRUCTION_GLOBS:
        for f in WORK_DIR.glob(glob):
            rel = str(f.relative_to(WORK_DIR)).replace("\\", "/")
            files.append(rel)
    return sorted(files)


def build_initial_context(pr_info: dict, diff: str, changed_files: list[str]) -> str:
    """Build the initial user message for DeepSeek."""
    return f"""## PR 信息

- PR 编号: #{pr_info.get('number', 'N/A')}
- 标题: {pr_info.get('title', 'N/A')}
- 描述: {pr_info.get('body', '(无)') or '(无)'}

## 变更文件列表

{chr(10).join(f'- {f}' for f in changed_files)}

## PR Diff

```diff
{diff[:80000]}
```
"""


# ── DeepSeek function calling loop ─────────────────────────────────────────

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "read_instruction_file",
            "description": "读取一个 AI 指令文件的当前内容。在修改任何指令文件之前必须先调用此函数读取。支持: AGENTS.md, CLAUDE.md, .github/instructions/*.md, .github/copilot-instructions.md",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "文件在仓库中的相对路径，如 gameplay/abilities/AGENTS.md"
                    }
                },
                "required": ["path"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "update_instruction_file",
            "description": "更新一个 AI 指令文件的完整内容。传入文件的完整新内容（不是 diff）。只有在先用 read_instruction_file 读取过该文件后才能调用。如果文件不存在则会创建。",
            "parameters": {
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "文件在仓库中的相对路径"
                    },
                    "content": {
                        "type": "string",
                        "description": "文件的完整新内容"
                    }
                },
                "required": ["path", "content"]
            }
        }
    }
]


def call_deepseek(messages: list[dict]) -> dict:
    """Single DeepSeek API call."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
    }
    payload = {
        "model": "deepseek-v4-pro",
        "messages": messages,
        "tools": TOOLS,
        "tool_choice": "auto",
        "temperature": 0.3,
    }
    resp = requests.post(DEEPSEEK_API, headers=headers, json=payload, timeout=120)
    if resp.status_code >= 400:
        log.error(f"DeepSeek API error {resp.status_code}: {resp.text[:500]}")
        raise RuntimeError(f"DeepSeek API error: {resp.status_code}")
    return resp.json()


def run_analysis(pr_info: dict, diff: str, changed_files: list[str]) -> bool:
    """
    Run the DeepSeek analysis loop.
    Returns True if any instruction files were modified.
    """
    existing = find_existing_instruction_files()
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": (
                build_initial_context(pr_info, diff, changed_files)
                + f"\n\n## 仓库中存在的指令文件清单\n\n{chr(10).join(f'- `{f}`' for f in existing)}"
                + "\n\n请先分析 PR diff 中哪些变更可能影响指令文件的准确性，"
                "然后用 read_instruction_file 读取需要检查的文件，"
                "最后用 update_instruction_file 更新确实需要修改的文件。"
            ),
        },
    ]

    files_modified = []

    for round_num in range(1, MAX_TOOL_ROUNDS + 1):
        log.info(f"DeepSeek round {round_num}...")
        response = call_deepseek(messages)

        assistant_msg = response["choices"][0]["message"]
        messages.append(assistant_msg)

        tool_calls = assistant_msg.get("tool_calls", [])

        if not tool_calls:
            log.info("DeepSeek finished analysis (no more tool calls)")
            content = assistant_msg.get("content", "")
            if content:
                log.info(f"DeepSeek final message: {content[:500]}")
            break

        # Execute tool calls
        for tc in tool_calls:
            func_name = tc["function"]["name"]
            try:
                args = json.loads(tc["function"]["arguments"])
            except json.JSONDecodeError as e:
                log.error(f"Failed to parse tool arguments: {e}")
                result = f"参数解析错误: {e}"
                messages.append({
                    "role": "tool",
                    "tool_call_id": tc["id"],
                    "content": result,
                })
                continue

            if func_name == "read_instruction_file":
                path = args.get("path", "")
                result = read_instruction_file(path)
                log.info(f"  read: {path} ({len(result)} chars)")

            elif func_name == "update_instruction_file":
                path = args.get("path", "")
                content = args.get("content", "")
                result = update_instruction_file(path, content)
                files_modified.append(path)

            else:
                result = f"未知函数: {func_name}"

            messages.append({
                "role": "tool",
                "tool_call_id": tc["id"],
                "content": result,
            })

    return len(files_modified) > 0


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    log.info(f"Repository: {REPO}")
    log.info(f"PR Number: {PR_NUMBER or '(auto-detect)'}")

    # 1. Fetch PR info
    pr_info = get_pr_info()
    actual_pr_number = pr_info["number"]
    global PR_NUMBER, BRANCH_NAME
    PR_NUMBER = str(actual_pr_number)
    BRANCH_NAME = f"ai/sync-instructions-pr-{actual_pr_number}"
    log.info(f"PR #{PR_NUMBER}: {pr_info.get('title', 'N/A')}")

    # 2. Fetch diff
    diff = get_pr_diff()
    changed_files = get_pr_files()
    log.info(f"PR diff: {len(diff)} chars, {len(changed_files)} files changed")

    if len(diff) == 0:
        log.info("Empty diff, nothing to analyze")
        return 0

    # 3. Run DeepSeek analysis
    try:
        modified = run_analysis(pr_info, diff, changed_files)
    except Exception as e:
        log.error(f"DeepSeek analysis failed: {e}")
        return 1

    if not modified:
        log.info("No instruction files modified, skipping commit")
        return 0

    # 4. Commit and create PR
    try:
        files_modified = find_modified_files()
        commit_and_create_pr(pr_info, files_modified)
    except Exception as e:
        log.error(f"Commit/PR creation failed: {e}")
        return 1

    log.info("Done! Instruction file sync PR created.")
    return 0


def safe_git(args: list[str], **kwargs) -> subprocess.CompletedProcess:
    """Run a git command; return CompletedProcess, non-zero is NOT fatal."""
    log.info(f"git {' '.join(args)}")
    return subprocess.run(["git"] + args, cwd=str(WORK_DIR), **kwargs)


def has_changes() -> bool:
    """Check if the working tree has modifications."""
    result = safe_git(["status", "--porcelain"], capture_output=True, text=True)
    return bool(result.stdout.strip())


def find_modified_files() -> list[str]:
    """Find which instruction files were modified between the working tree and HEAD."""
    result = safe_git(["diff", "--name-only", "HEAD"], capture_output=True, text=True)
    return [f for f in result.stdout.strip().split("\n") if f]


def commit_and_create_pr(pr_info: dict, files_modified: list[str]):
    """Commit changes, push, and create a PR."""
    if not BRANCH_NAME:
        log.warning("No branch name configured, skipping commit")
        return

    # Stage changes
    safe_git(["add", "-A"])

    if not has_changes():
        log.info("No changes to commit")
        return

    # Create or reuse branch
    existing = safe_git(["rev-parse", "--verify", BRANCH_NAME], capture_output=True)
    if existing.returncode == 0:
        safe_git(["checkout", BRANCH_NAME])
    else:
        safe_git(["checkout", "-b", BRANCH_NAME])

    commit_msg = (
        f"docs: sync AI instruction files after PR #{PR_NUMBER}\n\n"
        f"Updated based on changes from: {pr_info.get('title', 'N/A')}\n\n"
        f"Modified files:\n"
        + "\n".join(f"- {f}" for f in files_modified)
    )
    result = safe_git(["commit", "-m", commit_msg], capture_output=True)
    if result.returncode != 0:
        log.error(f"Commit failed: {result.stderr}")
        raise RuntimeError("Git commit failed")

    # Force-push to handle branch from a prior failed run
    safe_git(["push", "--force", "origin", BRANCH_NAME])

    # Create PR
    pr_body_lines = [
        "## 自动同步 AI 指令文件",
        "",
        f"根据 [#{PR_NUMBER}](https://github.com/{REPO}/pull/{PR_NUMBER}) "
        "的合并内容，自动更新了以下指令文件：",
        "",
    ] + [f"- `{f}`" for f in files_modified] + [
        "",
        "请人工审阅后合并。",
        "",
        "> Powered by DeepSeek via GitHub Actions",
    ]
    pr_body = "\n".join(pr_body_lines)

    env = os.environ.copy()
    env["GH_TOKEN"] = GITHUB_TOKEN
    result = subprocess.run(
        [
            "gh", "pr", "create",
            "--title", f"docs: sync AI instructions after merge of #{PR_NUMBER}",
            "--body", pr_body,
            "--base", "main",
            "--head", BRANCH_NAME,
            "--repo", REPO,
        ],
        capture_output=True, text=True, env=env, cwd=str(WORK_DIR),
    )
    if result.returncode != 0:
        log.error(f"gh pr create failed: {result.stderr}")
        raise RuntimeError("Failed to create PR")
    pr_url = result.stdout.strip()
    log.info(f"Created PR: {pr_url}")
    print(f"::notice title=PR Created::{pr_url}")


if __name__ == "__main__":
    sys.exit(main())
