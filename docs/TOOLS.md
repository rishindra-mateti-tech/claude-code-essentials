# Tools, in depth

The README's table gives the short version. This is the longer one: what
each tool actually does, the evidence behind picking it, and what its real
limitations are.

## ponytail

**What it does**: enforces a decision ladder before any code gets written.
Does this need to exist at all, is it already in the codebase, is it in the
standard library, is it a native platform feature, is it an existing
dependency, can it be one line, only then write new code.

**Why chosen**: it's the only tool in this space that targets code
generation itself rather than code review after the fact. Self-contained
skill file, no hooks, no background process, so the cost of having it
installed is close to zero even on tasks where it doesn't end up mattering.

**What's installed vs. skipped**: 4 of 6 skills from the source repo.
`ponytail-review` and `ponytail-audit` are real review tools (diff-level and
repo-wide over-engineering scans). `ponytail-debt` tracks the `ponytail:`
comments the core skill leaves behind when it deliberately defers something.
`ponytail-gain` and `ponytail-help` are skipped: both are static
text-display commands with no effect on behavior, `ponytail-gain` prints a
fixed benchmark scoreboard from the project's own README, `ponytail-help`
prints a command reference card.

**Limitation**: it's a skill, not a hook. Claude Code's convention is to
self-invoke a skill when a task matches its description, which is a strong
default but not a hard guarantee on every single edit.

## taste-skill

**What it does**: an anti-slop frontend/UI skill. Reads a design brief,
infers the right design direction, and pushes generated interfaces away
from generic AI-default patterns (predictable purple gradients, cookie
cutter layouts, system fonts) toward something intentional. The core
variant has three adjustable dials: design variance, motion intensity, and
visual density.

**Why chosen over Anthropic's frontend-design**: 79.8k stars vs. 33.9k
(repo-wide, not plugin-specific), 13 skill variants vs. 1, adjustable dials
vs. none, and it installs via `npx skills add` rather than requiring
`/plugin` access, which this repo can't assume every environment has. Full
breakdown in
[COMPARISONS.md](COMPARISONS.md#taste-skill-vs-anthropic-frontend-design).

**What's installed vs. skipped**: 1 of 13 variants, the core
`design-taste-frontend` skill. The other 12 (v1 preserved, GPT/Codex
optimized, image-to-code, redesign-existing-projects, several stylistic
variants, image-generation skills) are not installed by default; running
all of them as always-on would mean multiple frontend-design skills
competing on the same task with no priority order between them. Install a
different variant yourself with `--skill "<name>"` if the default core
skill isn't the fit you want, in place of it rather than alongside it.

**Verified during this repo's own testing**: the `skills` CLI runs a
built-in safety scan (Gen, Socket, Snyk) before installing and reported
"Safe, 0 alerts, Low Risk" for the `design-taste-frontend` skill at
install time.

**Activation**: self-triggering skill, same convention as ponytail, and
reinforced the same way, a CLAUDE.md rule scoping it to frontend/UI code
specifically so it doesn't try to weigh in on backend work.

## superpowers

**What it does**: 13 skills covering test-driven development, systematic
debugging, brainstorming before implementation, writing plans, requesting
and receiving code review, git worktrees, parallel agent dispatch, and more.

**Why chosen**: accepted into Anthropic's official plugin marketplace,
actively maintained by its author (obra / Jesse Vincent). Each skill is
explicit-call, so having 13 of them installed costs nothing until you
actually invoke one by name.

**What's excluded**: `using-superpowers`, a 14th skill in the source repo.
Its own instructions state it should be invoked "before ANY response,
including clarifying questions" whenever a skill is even 1% relevant, with
a table of "red flags" specifically written to argue against holding back.
That's a meta-skill designed to force every other skill into automatic use,
which directly conflicts with keeping the rest of the set explicit-call
only. Excluding it doesn't reduce the other 13 skills' usefulness, it just
removes the piece that would override your control over when they run.

## code-review-graph

**What it does**: parses your codebase with tree-sitter (no LLM calls, no
embeddings) into a local SQLite-backed graph, then answers structural
questions ("what calls this function", "what's the blast radius of changing
this file") from that index instead of reading files fresh each time.

**Why chosen over graphify**: same underlying technique, but narrower scope
by design. code-review-graph indexes code only; graphify also indexes docs,
PDFs, SQL schemas, and more. For day-to-day code review, the narrower tool
is the better fit, and running both would mean maintaining two overlapping
indexes of the same repo.

**Why chosen over sigmap**: sigmap's indexing does the same base job
(answer questions about code cheaply) plus one distinct capability,
`sigmap verify`, checking an AI's answer against the actual codebase to
catch hallucinated file or symbol references. code-review-graph doesn't do
that verification step. If you've hit a real hallucination problem, add
sigmap alongside; otherwise the overlap outweighs the benefit.

**Metrics claimed**: ~65x median per-question token reduction across tested
repositories in the project's own benchmarks, up to 376x on the largest
tested repo (fastapi). Not independently re-verified here.

**Known limitation, observed during this repo's own testing**: on Windows,
the Python/JS/TS/SQL tree-sitter parsers can hit a 5-second cold-start
timeout when the grammar cache isn't warm, causing those languages to fall
back to a lighter parse for that build. The index still works; see
[TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## graphify

**What it does**: builds a cross-format knowledge graph across code, docs,
PDFs, SQL schemas, and configs. Local-first, tree-sitter based, no
embeddings.

**Why installed but not always-on**: broader scope than code-review-graph
is exactly why it's kept explicit-call. Running both as MCP servers all the
time means double-indexing the code portion of your repo for no benefit.
Call it by name specifically when a task is genuinely cross-format, a code
file plus its related PDF spec, for example.

## markitdown (Microsoft)

**What it does**: converts PDF, DOCX, PPTX, images, audio, HTML, and more
into Markdown for LLM consumption.

**Why chosen**: official Microsoft project, single-purpose, no overlap with
anything else in this stack. Straightforward pick, no real alternative was
seriously considered.

## context-mode

**What it does**: sandboxes large tool output (from Bash, Read, Grep,
WebFetch, Task calls) into a subprocess and feeds only a compressed summary
into context, instead of the raw output.

**Why chosen over caveman and Paritok**: broader hook surface than either
competitor covers, plus persistent session memory and cross-platform
routing across 17+ tool integrations.

**What's installed vs. what's not wired**: this repo registers context-mode
as an MCP server only. Its `PreToolUse`/`PostToolUse` hook wiring, the part
that would make it auto-intercept every Bash/Read/Grep/WebFetch call, is
left off by default. That's a bigger standing change (it touches
`settings.json` and affects every future command), so it's opt-in rather
than something this installer decides for you.

## get-shit-done (community fork)

**What it does**: 31 slash commands (`/gsd:new-milestone`, `/gsd:plan-phase`,
`/gsd:execute-phase`, and so on) for structured, multi-day project planning
with persisted state across sessions.

**Why the fork, not the original**: the original `get-shit-done-cc` npm
package is marked unsupported/abandoned by its own maintainer.
`conradvc/CC-get-shit-done` is an actively maintained community fork that
provides the same command set. Since it's a fork of an abandoned project
rather than something with its own long independent track record, verify it
still works for your use case before depending on it for anything time
sensitive.

## rtk

**What it does**: a Rust CLI that transparently rewrites bash commands
before they execute, compressing verbose output (build logs, package lists,
git history) before it reaches the agent's context.

**Why chosen over Paritok, caveman, and token-optimizer**: 77k+ GitHub
stars, 1,500+ commits, integrations across 16 different AI coding tools.
The most independently validated option in this category by a wide margin.

**Why not token-optimizer, if it covers more ground**: token-optimizer does
cover more (bash output compression plus config/skill/memory bloat and
compaction survival, which rtk doesn't touch), but its larger savings
figures are self-reported and unaudited; only a smaller subset is
independently metered with real logged data. rtk's narrower scope is fully
backed by real-world adoption. See
[COMPARISONS.md](COMPARISONS.md#rtk-vs-token-optimizer) for the full
breakdown, and the README's Swap options section for the install command if
you want token-optimizer instead.

**Known limitation, observed during this repo's own testing**: rtk's
automatic compression depends on Claude Code's `PreToolUse` hook, which
requires the standard `claude` CLI process. Some hosted/SDK-based sessions
don't run that process and won't fire the hook even though setup reports
success. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## claude-token-efficient rules

**What it does**: a small set of CLAUDE.md rules reducing response
verbosity, no sycophantic openers, no filler closings, verify claims before
asserting them, and so on.

**Why chosen**: not a tool at all, just a text file. 6k+ stars, single file,
zero install risk, and directly additive to anything else in this stack.
