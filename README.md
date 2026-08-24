# claude-code-essentials

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-5A45FF)](https://claude.com/claude-code)
[![Shell](https://img.shields.io/badge/install-bash-4EAA25?logo=gnu-bash&logoColor=white)](install.sh)

A curated, tested combination of Claude Code skills, MCP servers, and CLI
tools — installed with one script, explained with one README. Not an
exhaustive list of everything that exists. Every tool here was picked over
real alternatives, and the reasons are documented below, not just asserted.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/<you>/claude-code-essentials/main/install.sh | bash
```

Run it from inside the project you want MCP servers registered for. Restart
Claude Code afterward — skills, commands, and MCP servers load at session
start, not mid-session.

## Quick example

Before this stack, a typical session looks like:

```
> git status
[300+ lines of raw output flood the context]
> "what calls this function?"
[Claude reads 8 files manually to find out]
```

After:

```
> git status
[rtk compresses it to a summary before it reaches context]
> "what calls this function?"
[code-review-graph answers from its pre-built index — no file reads]
> [writing a new helper function]
[ponytail checks: does this need to exist, or is it one line of stdlib?]
```

Same conversation, same questions — fewer tokens spent getting there, and
code that defaults to minimal instead of defaulting to written-from-scratch.

## What gets installed, and why

| Tool | Role | Chosen over | Why |
|---|---|---|---|
| **ponytail** (+review/audit/debt) | Minimal-code discipline, always-on | writing from scratch each time | Enforces a YAGNI decision ladder before any code is written. Self-contained, no hooks, no background cost. |
| **superpowers** (13 skills) | TDD, systematic debugging, planning — explicit-call | `get-shit-done`-only workflows, `ruflo` | Anthropic-marketplace-accepted, mature. Its `using-superpowers` meta-skill is deliberately excluded — it forces every skill to auto-invoke on any 1%-relevant task, which fights explicit-call control. |
| **code-review-graph** | Local code index, MCP server | `graphify`, `sigmap` | Tree-sitter + SQLite, no LLM/embeddings needed. Claims ~65x token reduction on review questions. Narrower scope than graphify (code-only vs. code+docs+PDFs), which is exactly the fit for day-to-day review work. |
| **graphify** | Cross-format knowledge graph (code+docs+PDF+SQL), explicit-call only | keeping it always-on | Broader scope than code-review-graph, but that breadth means redundant indexing if run alongside it. Installed dormant — invoke by name only when a task is genuinely cross-format. |
| **markitdown** (Microsoft) | PDF/DOCX/PPTX → Markdown | building a custom converter | Official, low-risk, single-purpose. No overlap with anything else here. |
| **context-mode** | Sandboxes large tool output into summaries | `caveman`, `Paritok` | Broader hook surface (Bash/Read/Grep/WebFetch/Task) than any competitor in this niche. Installed as MCP tools only — hook-based auto-interception is opt-in, see note below. |
| **get-shit-done** (community fork) | Milestone/phase planning, 31 explicit `/gsd:*` commands | the original `get-shit-done-cc` npm package | The original is marked unsupported/abandoned on npm. This installs `conradvc/CC-get-shit-done`, an actively maintained fork — verify it still works before depending on it long-term. |
| **rtk** | Bash output compression | `Paritok`, `caveman`, `token-optimizer` | 77k+ GitHub stars, 16-tool integration, most battle-tested option in this category. See swap note below. |
| **claude-token-efficient rules** | Response verbosity rules in CLAUDE.md | writing custom rules | 6k+ stars, single-file, zero install risk, directly additive. |

## What's deliberately NOT installed

| Tool | Why skipped |
|---|---|
| `ruflo` | Multi-agent orchestration framework built for teams running always-on swarms — wrong shape for individual work, no clean "dormant until needed" mode. |
| `claude-mem` | Redundant with Claude Code's own native cross-session memory system — adds compression/injection token overhead for something already free. |
| `caveman`, `Paritok`, `token-reducer` (madhan230205) | Each overlaps an installed tool (context-mode or code-review-graph) with a smaller/less proven track record. |
| `sigmap` | Genuinely useful `verify` (anti-hallucination) feature, but its indexing overlaps code-review-graph. Worth adding only if you actually hit a hallucination problem — not preemptively. |
| Original `get-shit-done-cc` (npm) | Marked unsupported/abandoned by its own maintainer. |
| Anthropic `frontend-design`, `taste-skill` | Redundant if you already have any design-taste skill installed — check before adding either. |
| Paxel | Not a dev tool — a YC engagement/profiling product that uploads prompt data despite "local" claims. Out of scope entirely. |

## Swap options

Some choices here are close calls, not settled facts. Swap freely:

**rtk → token-optimizer.** token-optimizer covers rtk's bash-compression job
plus config/skill/memory bloat and compaction survival that rtk doesn't
touch. It's the broader tool — but its bigger savings numbers are
self-reported/unaudited, only a smaller subset is independently metered, and
on Windows it requires `/plugin` (not always available, e.g. inside
SDK-hosted app sessions rather than the standalone `claude` CLI). If you have
`/plugin` access:

```
/plugin marketplace add alexgreensh/token-optimizer
/plugin install token-optimizer@alexgreensh-token-optimizer
```

Then remove rtk's hook entry from `~/.claude/settings.json` so they don't
both intercept Bash at once.

**code-review-graph → sigmap.** Add sigmap alongside (not instead of)
code-review-graph only if you specifically want its `sigmap verify` command —
checking my answers against your actual code to catch hallucinated
files/symbols. Running both for the base indexing job is redundant.

## Important: the rtk hook may not auto-fire everywhere

rtk's automatic bash compression depends on Claude Code's `PreToolUse` hook
mechanism, which requires the standard `claude` CLI process reading
`~/.claude/settings.json`. Some hosted/SDK-based Claude Code environments
(certain desktop apps, cloud sessions) don't run that process and won't honor
the hook even though `rtk init -g` reports success. If a verbose command
comes back uncompressed after installing, this is why — the fix is either
running from an actual `claude` CLI terminal, or invoking `rtk <command>`
manually for large-output commands.

## What "install" actually touches

- `~/.claude/skills/` — ponytail (+3), superpowers (13)
- `~/.claude/commands/gsd/` — 31 command files
- `~/.claude/get-shit-done/` — supporting workflows/templates/bin
- `~/.claude/CLAUDE.md` — appends two rule sections, does not overwrite
- `~/.local/bin/` — rtk binary
- pipx-isolated venvs — code-review-graph, graphify, markitdown (no shared
  dependencies with your other Python projects, deliberately — see the note
  below)
- npm global — context-mode
- `.mcp.json` in the directory you ran the installer from

### Why pipx, not plain pip

A plain `pip install` puts these tools' dependencies into your global Python
environment, which can silently upgrade packages other projects depend on
(this repo exists partly because that happened during initial testing —
`starlette`, `pydantic`, and `websockets` got bumped and broke unrelated
projects in the same environment). `pipx` gives each CLI tool its own
isolated venv instead.

## License

MIT — see [LICENSE](LICENSE). Individual tools installed by this script
retain their own upstream licenses; nothing here is vendored or relicensed.
