#!/usr/bin/env bash
# claude-code-essentials installer
# Installs a curated, tested combination of Claude Code skills, MCP servers,
# and CLI tools. Fetches from each tool's original source at install time —
# nothing is vendored, so you always get the upstream project directly.
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
COMMANDS_DIR="$CLAUDE_DIR/commands"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INSTALLED=()
SKIPPED=()

log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$1"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$1"; }

mkdir -p "$SKILLS_DIR" "$COMMANDS_DIR"

# ---------------------------------------------------------------------------
log "Checking prerequisites"
command -v git  >/dev/null || { echo "git is required."; exit 1; }
command -v node >/dev/null || { echo "node/npm is required."; exit 1; }
command -v pip  >/dev/null || command -v pip3 >/dev/null || { echo "python/pip is required."; exit 1; }
PIP=$(command -v pip || command -v pip3)
ok "git, node, pip found"

if ! python3 -m pipx --version >/dev/null 2>&1 && ! python -m pipx --version >/dev/null 2>&1; then
  log "Installing pipx (isolates each CLI tool, avoids dependency conflicts with your other Python projects)"
  $PIP install --user pipx >/dev/null
  python -m pipx ensurepath >/dev/null 2>&1 || python3 -m pipx ensurepath >/dev/null 2>&1 || true
fi
PIPX="python -m pipx"
$PIPX --version >/dev/null 2>&1 || PIPX="python3 -m pipx"

# ---------------------------------------------------------------------------
log "Installing ponytail (core + review/audit/debt) — enforces minimal-code discipline"
git clone --depth 1 -q https://github.com/DietrichGebert/ponytail.git "$TMP_DIR/ponytail"
for name in ponytail ponytail-review ponytail-audit ponytail-debt; do
  mkdir -p "$SKILLS_DIR/$name"
  cp -r "$TMP_DIR/ponytail/skills/$name/"* "$SKILLS_DIR/$name/"
done
ok "ponytail + 3 variants installed to $SKILLS_DIR"
INSTALLED+=("ponytail (core, review, audit, debt)")

# ---------------------------------------------------------------------------
log "Installing superpowers (TDD, debugging, planning workflow skills)"
git clone --depth 1 -q https://github.com/obra/superpowers.git "$TMP_DIR/superpowers"
for dir in "$TMP_DIR/superpowers/skills"/*/; do
  name=$(basename "$dir")
  # using-superpowers forces every other skill to auto-invoke on every message —
  # deliberately excluded so skills stay explicit-call, not forced.
  [ "$name" = "using-superpowers" ] && { warn "skipped using-superpowers (forces auto-invocation, not explicit-call)"; continue; }
  mkdir -p "$SKILLS_DIR/$name"
  cp -r "$dir"* "$SKILLS_DIR/$name/"
done
ok "13 superpowers skills installed (explicit-call only)"
INSTALLED+=("superpowers (13 skills)")

# ---------------------------------------------------------------------------
log "Installing code-review-graph (tree-sitter code index, MCP server)"
$PIPX install code-review-graph >/dev/null 2>&1 || warn "code-review-graph pipx install failed, skipping"
ok "code-review-graph installed"
INSTALLED+=("code-review-graph")

log "Installing graphify (cross-format knowledge graph, explicit-call CLI)"
$PIPX install graphifyy >/dev/null 2>&1 || warn "graphify pipx install failed, skipping"
ok "graphify installed (dormant — call explicitly, don't wire as always-on)"
INSTALLED+=("graphify")

log "Installing markitdown (file-to-markdown converter, explicit-call CLI)"
$PIPX install markitdown >/dev/null 2>&1 || warn "markitdown pipx install failed, skipping"
ok "markitdown installed"
INSTALLED+=("markitdown")

# ---------------------------------------------------------------------------
log "Installing context-mode (MCP server, register manually per-project — see README)"
npm install -g context-mode >/dev/null 2>&1 || warn "context-mode npm install failed, skipping"
ok "context-mode installed globally"
INSTALLED+=("context-mode")

# ---------------------------------------------------------------------------
log "Installing get-shit-done (milestone/phase planning commands)"
git clone --depth 1 -q https://github.com/conradvc/CC-get-shit-done.git "$TMP_DIR/gsd"
mkdir -p "$COMMANDS_DIR/gsd" "$CLAUDE_DIR/get-shit-done"
cp -r "$TMP_DIR/gsd/commands/gsd/"* "$COMMANDS_DIR/gsd/"
cp -r "$TMP_DIR/gsd/get-shit-done/"* "$CLAUDE_DIR/get-shit-done/"
ok "31 /gsd:* commands installed"
INSTALLED+=("get-shit-done (31 commands, community fork of an unmaintained package — verify it still works for you)")

# ---------------------------------------------------------------------------
log "Installing rtk (bash output compression)"
OS="$(uname -s)"
ARCH="$(uname -m)"
RTK_URL=""
case "$OS" in
  Linux)  RTK_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-unknown-linux-musl.tar.gz" ;;
  Darwin) RTK_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-apple-darwin.tar.gz" ;;
  MINGW*|MSYS*|CYGWIN*) RTK_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip" ;;
esac
mkdir -p "$HOME/.local/bin"
if [ -n "$RTK_URL" ]; then
  if [[ "$RTK_URL" == *.zip ]]; then
    curl -fsSL -o "$TMP_DIR/rtk.zip" "$RTK_URL" && unzip -oq "$TMP_DIR/rtk.zip" -d "$TMP_DIR/rtk_x" && cp "$TMP_DIR/rtk_x/rtk.exe" "$HOME/.local/bin/rtk.exe"
    RTK_BIN="$HOME/.local/bin/rtk.exe"
  else
    curl -fsSL "$RTK_URL" | tar -xz -C "$TMP_DIR" && cp "$TMP_DIR/rtk" "$HOME/.local/bin/rtk"
    RTK_BIN="$HOME/.local/bin/rtk"
    chmod +x "$RTK_BIN"
  fi
  ok "rtk installed to $RTK_BIN"
  INSTALLED+=("rtk (bash compression)")
  warn "Automatic hook wiring is CLI-only (needs the standard 'claude' process — see README). Run 'rtk init -g' yourself from a real claude CLI terminal to enable it. Until then, invoke $RTK_BIN <command> manually for verbose commands."
else
  warn "Could not detect OS for rtk binary — install manually from https://github.com/rtk-ai/rtk/releases"
fi

# ---------------------------------------------------------------------------
log "Registering MCP servers for this project ($(pwd))"
if [ -f ".mcp.json" ]; then
  warn ".mcp.json already exists here — not overwriting, add code-review-graph/context-mode manually if missing"
else
  CRG_BIN="$(command -v code-review-graph || echo "$HOME/.local/bin/code-review-graph")"
  cat > .mcp.json <<EOF
{
  "mcpServers": {
    "code-review-graph": {
      "command": "$CRG_BIN",
      "args": ["serve", "--repo", "$(pwd)"]
    },
    "context-mode": {
      "command": "npx",
      "args": ["context-mode", "mcp"]
    }
  }
}
EOF
  ok ".mcp.json created in $(pwd)"
fi
INSTALLED+=("MCP registration (.mcp.json in current project)")

# ---------------------------------------------------------------------------
log "Adding standing rules to CLAUDE.md"
touch "$CLAUDE_MD"
if ! grep -q "ponytail skill first" "$CLAUDE_MD" 2>/dev/null; then
  cat >> "$CLAUDE_MD" <<'EOF'

## Ponytail (always use before writing code)

Before writing, adding, refactoring, or fixing any code, apply the `ponytail`
skill first. Applies by default on every coding task, not only when
explicitly asked.

## Token efficiency (from claude-token-efficient)

- Read existing files before writing. Don't re-read unless changed.
- Thorough in reasoning, concise in output.
- Skip files over 100KB unless required.
- No sycophantic openers or closing fluff.
- No emojis or em-dashes.
- Do not guess APIs, versions, flags, commit SHAs, or package names. Verify by reading code or docs before asserting.
EOF
  ok "rules appended to $CLAUDE_MD"
else
  warn "CLAUDE.md rules already present, skipped"
fi

# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
echo " Installed:"
for i in "${INSTALLED[@]}"; do echo "  - $i"; done
echo ""
echo " Why these, over the alternatives, and with what evidence:"
echo "   see README.md — every choice here has a documented reason"
echo "   and a maturity/star-count comparison, not just a pick."
echo ""
echo " Restart Claude Code (or start a new session) for skills,"
echo " commands, and MCP servers to load."
echo "============================================================"
