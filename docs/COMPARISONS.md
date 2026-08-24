# Comparisons

The reasoning behind every "chosen over X" line in the README, with the
actual numbers behind each call.

## rtk vs. token-optimizer

| | rtk | token-optimizer |
|---|---|---|
| Scope | Bash output compression only | Bash compression, plus config/skill/memory bloat, plus compaction survival |
| GitHub stars | 77.2k | 2,000+ |
| Commits | 1,503 (develop branch) | 982 |
| Platform integrations | 16 AI tools | Claude Code, Codex, OpenCode, OpenClaw, GitHub Copilot |
| Verified savings | Adoption-proven at scale, no formal audited figure published | Split: a metered subset (~$313/mo) has logged, reproducible receipts; the larger headline figure (~$1,877/mo) is explicitly labeled "estimated, counterfactual, unmeasured" |
| Windows support | Direct binary download, no `/plugin` needed | Windows requires `/plugin` per the project's own docs |
| Installed by default here | Yes | No, documented as a swap option |

**Verdict used in this repo**: rtk's evidence is narrower in scope but far
more independently verified. token-optimizer's broader claims are plausible
but not yet backed by third-party verification at the same scale. Given
this repo also needed something that works without `/plugin` access (not
guaranteed in every Claude Code environment), rtk was the safer default. If
you have `/plugin` access and want the broader coverage, see the README's
Swap options section for the exact install command.

## code-review-graph vs. graphify vs. sigmap

| | code-review-graph | graphify | sigmap |
|---|---|---|---|
| Parsing | tree-sitter, no LLM | tree-sitter, no LLM | deterministic signature maps, no embeddings |
| Scope | Code only | Code, docs, PDFs, SQL, configs | Code, 33 languages |
| Unique feature | "Blast radius" change-impact tracing | Cross-format graph, confidence-tagged edges | `sigmap verify`, catches hallucinated file/symbol references |
| Claimed token reduction | ~65x median, up to 376x on largest tested repo | Not directly comparable, broader scope | ~97% |
| Installed by default here | Yes, always-on MCP | Yes, explicit-call only | No |

**Verdict used in this repo**: code-review-graph and graphify solve the same
core problem (index code, answer questions cheaply) with different scope.
Running both always-on would double the indexing cost for the ~80% of
functionality they share, so graphify stays dormant and code-review-graph
is the default. sigmap's overlap with code-review-graph is similar, but its
`verify` capability is genuinely distinct (nothing else here checks my
answers against your real code). It's left uninstalled by default because
that's a problem worth solving reactively (after you've caught a
hallucination), not preemptively.

## superpowers vs. get-shit-done vs. ruflo

| | superpowers | get-shit-done | ruflo |
|---|---|---|---|
| Unit | 13 skills | 31 slash commands | Full orchestration framework |
| Invocation | Explicit-call (skill name) | Explicit-call (`/gsd:*`) | Designed to run background agent swarms |
| Best for | Per-task discipline (TDD, debugging, planning) | Multi-day milestone tracking with persisted state | Teams running multiple coordinated agents |
| Maintenance | Official Anthropic marketplace listing | Community fork of an abandoned original | Independent project |
| Installed by default here | Yes | Yes (fork) | No |

**Verdict used in this repo**: superpowers and get-shit-done solve different
problems (task-level discipline vs. project-level planning) and don't
overlap, so both are included. ruflo is built for a fundamentally different
use case, coordinated multi-agent teams, and has no clean "install it but
it stays quiet until called" mode the way a skill or command set does. It's
excluded regardless of quality, because the shape doesn't fit solo,
on-demand use.

## context-mode vs. caveman vs. Paritok

| | context-mode | caveman | Paritok |
|---|---|---|---|
| Hook surface | Bash, Read, Grep, WebFetch, Task | Bash and browse compression only | File reads, tool schemas, chat history |
| Platform integrations | 17+ | 30+ agents claimed for the skill component | Claude Code, Cursor, Codex |
| Stars | Not independently large, but broadest scope in this comparison | Smaller, less proven | 1.5k |
| Installed by default here | Yes, MCP tools only, hooks not wired | No | No |

**Verdict used in this repo**: context-mode's hook surface is the broadest
of the three, which is exactly why it's included but not fully wired.
Wiring every hook (Bash, Read, Grep, WebFetch, Task) is a bigger standing
change than this installer makes on your behalf; you get the MCP tools by
default and can opt into the full hook set yourself.
