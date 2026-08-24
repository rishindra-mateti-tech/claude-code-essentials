#!/usr/bin/env bash
# claude-code-essentials installer
# Installs a curated, tested combination of Claude Code skills, MCP servers,
# and CLI tools. Fetches from each tool's original source at install time —
# nothing is vendored, so you always get the upstream project directly.
#
# Usage:
#   install.sh                 install everything
#   install.sh --dry-run       show what would happen, change nothing
#   install.sh --uninstall     remove everything this script installs
#   install.sh --skip-rtk      skip rtk
#   install.sh --skip-gsd      skip get-shit-done
#   install.sh --skip-superpowers   skip superpowers skills
set -uo pipefail

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
COMMANDS_DIR="$CLAUDE_DIR/commands"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DRY_RUN=false
UNINSTALL=false
SKIP_RTK=false
SKIP_GSD=false
SKIP_SUPERPOWERS=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --skip-rtk) SKIP_RTK=true ;;
    --skip-gsd) SKIP_GSD=true ;;
    --skip-superpowers) SKIP_SUPERPOWERS=true ;;
    *) echo "Unknown flag: $arg" >&2; exit 1 ;;
  esac
done

SUCCEEDED=()
FAILED=()
SKIPPED=()

log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$1"; }
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$1"; }
fail() { printf '  \033[1;31m✗\033[0m %s\n' "$1"; }
dry()  { printf '  \033[1;34m→ would run:\033[0m %s\n' "$1"; }

run() {
  # run <label> <command...> — tracks success/failure honestly, respects --dry-run
  local label="$1"; shift
  if $DRY_RUN; then
    dry "$label: $*"
    return 0
  fi
  if "$@" >/dev/null 2>&1; then
    ok "$label"
    SUCCEEDED+=("$label")
    return 0
  else
    fail "$label (command failed: $*)"
    FAILED+=("$label")
    return 1
  fi
}

# ===========================================================================
if $UNINSTALL; then
  log "Uninstalling claude-code-essentials components"
  rm -rf "$SKILLS_DIR/ponytail" "$SKILLS_DIR/ponytail-review" "$SKILLS_DIR/ponytail-audit" "$SKILLS_DIR/ponytail-debt"
  ok "removed ponytail skills"
  for name in brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch \
              receiving-code-review requesting-code-review subagent-driven-development systematic-debugging \
              test-driven-development using-git-worktrees verification-before-completion writing-plans writing-skills; do
    rm -rf "${SKILLS_DIR:?}/$name"
  done
  ok "removed superpowers skills"
  rm -rf "$COMMANDS_DIR/gsd" "$CLAUDE_DIR/get-shit-done"
  ok "removed get-shit-done commands"
  rm -f "$HOME/.local/bin/rtk" "$HOME/.local/bin/rtk.exe"
  ok "removed rtk binary"
  command -v pipx >/dev/null 2>&1 && pipx uninstall code-review-graph >/dev/null 2>&1
  command -v pipx >/dev/null 2>&1 && pipx uninstall graphifyy >/dev/null 2>&1
  command -v pipx >/dev/null 2>&1 && pipx uninstall markitdown >/dev/null 2>&1
  ok "removed pipx tools (code-review-graph, graphify, markitdown)"
  npm uninstall -g context-mode >/dev/null 2>&1
  ok "removed context-mode (npm global)"
  echo ""
  warn "NOT removed automatically (manual, since they hold your own edits):"
  warn "  - $CLAUDE_MD  (this script's rule sections are clearly marked, remove by hand)"
  warn "  - .mcp.json in any project you ran the installer from"
  warn "  - the hooks.PreToolUse entry in $CLAUDE_DIR/settings.json, if you added it"
  echo ""
  echo "Uninstall complete. See docs/UNINSTALL.md for exact manual-removal steps."
  exit 0
fi

$DRY_RUN && log "DRY RUN — nothing will be installed or modified"

mkdir -p "$SKILLS_DIR" "$COMMANDS_DIR"

# ---------------------------------------------------------------------------
log "Checking prerequisites"
MISSING=()
command -v git  >/dev/null || MISSING+=("git")
command -v node >/dev/null || MISSING+=("node/npm")
command -v pip  >/dev/null || command -v pip3 >/dev/null || MISSING+=("python/pip")
if [ "${#MISSING[@]}" -gt 0 ]; then
  fail "Missing required tools: ${MISSING[*]}"
  echo "Install these first, then re-run."
  exit 1
fi
PIP=$(command -v pip || command -v pip3)
ok "git, node, pip found"

if ! python3 -m pipx --version >/dev/null 2>&1 && ! python -m pipx --version >/dev/null 2>&1; then
  if $DRY_RUN; then
    dry "pip install --user pipx"
  else
    log "Installing pipx (isolates each CLI tool, avoids dependency conflicts with your other Python projects)"
    if $PIP install --user pipx >/dev/null 2>&1; then
      ok "pipx installed"
      python -m pipx ensurepath >/dev/null 2>&1 || python3 -m pipx ensurepath >/dev/null 2>&1 || true
    else
      fail "pipx install failed — pipx-based tools below will be skipped"
      FAILED+=("pipx")
    fi
  fi
fi
PIPX="python -m pipx"
$PIPX --version >/dev/null 2>&1 || PIPX="python3 -m pipx"
PIPX_OK=true
$PIPX --version >/dev/null 2>&1 || PIPX_OK=false

# ---------------------------------------------------------------------------
log "ponytail (core + review/audit/debt) — minimal-code discipline"
if $DRY_RUN; then
  dry "clone DietrichGebert/ponytail, copy 4 skill dirs into $SKILLS_DIR"
elif git clone --depth 1 -q https://github.com/DietrichGebert/ponytail.git "$TMP_DIR/ponytail" >/dev/null 2>&1; then
  OK_COUNT=0
  for name in ponytail ponytail-review ponytail-audit ponytail-debt; do
    if [ -d "$TMP_DIR/ponytail/skills/$name" ]; then
      mkdir -p "$SKILLS_DIR/$name"
      cp -r "$TMP_DIR/ponytail/skills/$name/"* "$SKILLS_DIR/$name/"
      OK_COUNT=$((OK_COUNT + 1))
    fi
  done
  if [ "$OK_COUNT" -eq 4 ]; then
    ok "ponytail + 3 variants installed"
    SUCCEEDED+=("ponytail (4 skills)")
  else
    fail "only $OK_COUNT/4 ponytail skill dirs found upstream"
    FAILED+=("ponytail (partial: $OK_COUNT/4)")
  fi
else
  fail "ponytail clone failed"
  FAILED+=("ponytail")
fi

# ---------------------------------------------------------------------------
if $SKIP_SUPERPOWERS; then
  SKIPPED+=("superpowers (--skip-superpowers)")
else
  log "superpowers (TDD, debugging, planning workflow skills)"
  if $DRY_RUN; then
    dry "clone obra/superpowers, copy all skills except using-superpowers into $SKILLS_DIR"
  elif git clone --depth 1 -q https://github.com/obra/superpowers.git "$TMP_DIR/superpowers" >/dev/null 2>&1; then
    COUNT=0
    for dir in "$TMP_DIR/superpowers/skills"/*/; do
      name=$(basename "$dir")
      # using-superpowers forces every other skill to auto-invoke on any
      # 1%-relevant task — deliberately excluded to keep skills explicit-call.
      [ "$name" = "using-superpowers" ] && continue
      mkdir -p "$SKILLS_DIR/$name"
      cp -r "$dir"* "$SKILLS_DIR/$name/"
      COUNT=$((COUNT + 1))
    done
    if [ "$COUNT" -gt 0 ]; then
      ok "$COUNT superpowers skills installed (explicit-call only)"
      SUCCEEDED+=("superpowers ($COUNT skills)")
    else
      fail "superpowers cloned but no skill dirs found"
      FAILED+=("superpowers")
    fi
  else
    fail "superpowers clone failed"
    FAILED+=("superpowers")
  fi
fi

# ---------------------------------------------------------------------------
log "code-review-graph (tree-sitter code index, MCP server)"
if ! $PIPX_OK; then
  fail "skipped — pipx unavailable"
  FAILED+=("code-review-graph")
else
  run "code-review-graph" $PIPX install code-review-graph
fi

log "graphify (cross-format knowledge graph, explicit-call CLI)"
if ! $PIPX_OK; then
  fail "skipped — pipx unavailable"
  FAILED+=("graphify")
else
  run "graphify" $PIPX install graphifyy
fi

log "markitdown (file-to-markdown converter, explicit-call CLI)"
if ! $PIPX_OK; then
  fail "skipped — pipx unavailable"
  FAILED+=("markitdown")
else
  run "markitdown" $PIPX install markitdown
fi

# ---------------------------------------------------------------------------
log "context-mode (MCP server — auto-registered into .mcp.json below)"
run "context-mode" npm install -g context-mode

# ---------------------------------------------------------------------------
if $SKIP_GSD; then
  SKIPPED+=("get-shit-done (--skip-gsd)")
else
  log "get-shit-done (milestone/phase planning, community fork of an unmaintained package)"
  if $DRY_RUN; then
    dry "clone conradvc/CC-get-shit-done, copy commands/gsd and get-shit-done/ into $CLAUDE_DIR"
  elif git clone --depth 1 -q https://github.com/conradvc/CC-get-shit-done.git "$TMP_DIR/gsd" >/dev/null 2>&1; then
    mkdir -p "$COMMANDS_DIR/gsd" "$CLAUDE_DIR/get-shit-done"
    cp -r "$TMP_DIR/gsd/commands/gsd/"* "$COMMANDS_DIR/gsd/"
    cp -r "$TMP_DIR/gsd/get-shit-done/"* "$CLAUDE_DIR/get-shit-done/"
    ok "31 /gsd:* commands installed"
    SUCCEEDED+=("get-shit-done (31 commands)")
  else
    fail "get-shit-done clone failed"
    FAILED+=("get-shit-done")
  fi
fi

# ---------------------------------------------------------------------------
if $SKIP_RTK; then
  SKIPPED+=("rtk (--skip-rtk)")
else
  log "rtk (bash output compression)"
  OS="$(uname -s)"
  RTK_URL=""
  case "$OS" in
    Linux)  RTK_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-unknown-linux-musl.tar.gz" ;;
    Darwin) RTK_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-apple-darwin.tar.gz" ;;
    MINGW*|MSYS*|CYGWIN*) RTK_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-x86_64-pc-windows-msvc.zip" ;;
  esac
  mkdir -p "$HOME/.local/bin"
  if [ -z "$RTK_URL" ]; then
    fail "could not detect OS for rtk binary — install manually from https://github.com/rtk-ai/rtk/releases"
    FAILED+=("rtk")
  elif $DRY_RUN; then
    dry "download and install rtk from $RTK_URL"
  else
    RTK_OK=false
    if [[ "$RTK_URL" == *.zip ]]; then
      if curl -fsSL -o "$TMP_DIR/rtk.zip" "$RTK_URL" 2>/dev/null && unzip -oq "$TMP_DIR/rtk.zip" -d "$TMP_DIR/rtk_x" 2>/dev/null && cp "$TMP_DIR/rtk_x/rtk.exe" "$HOME/.local/bin/rtk.exe" 2>/dev/null; then
        RTK_OK=true
        RTK_BIN="$HOME/.local/bin/rtk.exe"
      fi
    else
      if curl -fsSL "$RTK_URL" 2>/dev/null | tar -xz -C "$TMP_DIR" 2>/dev/null && cp "$TMP_DIR/rtk" "$HOME/.local/bin/rtk" 2>/dev/null; then
        chmod +x "$HOME/.local/bin/rtk"
        RTK_OK=true
        RTK_BIN="$HOME/.local/bin/rtk"
      fi
    fi
    if $RTK_OK; then
      ok "rtk installed to $RTK_BIN"
      SUCCEEDED+=("rtk")
      warn "Automatic hook wiring needs the standard 'claude' CLI process (not every hosted/SDK environment runs it)."
      warn "Run 'rtk init -g' yourself from a real claude CLI terminal to enable it — see docs/TROUBLESHOOTING.md."
      warn "Until confirmed working, invoke $RTK_BIN <command> manually for verbose commands."
    else
      fail "rtk download/install failed"
      FAILED+=("rtk")
    fi
  fi
fi

# ---------------------------------------------------------------------------
log "Registering MCP servers for this project ($(pwd))"
if $DRY_RUN; then
  dry "write .mcp.json in $(pwd) with code-review-graph and context-mode entries"
elif [ -f ".mcp.json" ]; then
  warn ".mcp.json already exists here — not overwriting. Add code-review-graph/context-mode entries manually if missing (see README)."
  SKIPPED+=("MCP registration (.mcp.json already exists)")
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
  SUCCEEDED+=("MCP registration")
fi

# ---------------------------------------------------------------------------
log "Adding standing rules to CLAUDE.md"
if $DRY_RUN; then
  dry "append ponytail + token-efficiency rule sections to $CLAUDE_MD (only if not already present)"
else
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
    SUCCEEDED+=("CLAUDE.md rules")
  else
    warn "CLAUDE.md rules already present, skipped"
    SKIPPED+=("CLAUDE.md rules (already present)")
  fi
fi

# ---------------------------------------------------------------------------
echo ""
echo "============================================================"
if $DRY_RUN; then
  echo " Dry run complete. Nothing was installed or modified."
  echo " Re-run without --dry-run to actually install."
else
  echo " Succeeded (${#SUCCEEDED[@]}):"
  for i in "${SUCCEEDED[@]}"; do echo "   - $i"; done
  if [ "${#SKIPPED[@]}" -gt 0 ]; then
    echo ""
    echo " Skipped (${#SKIPPED[@]}):"
    for i in "${SKIPPED[@]}"; do echo "   - $i"; done
  fi
  if [ "${#FAILED[@]}" -gt 0 ]; then
    echo ""
    echo " FAILED (${#FAILED[@]}) — these did not install, do not assume they're available:"
    for i in "${FAILED[@]}"; do echo "   - $i"; done
  fi
  echo ""
  echo " Why these, over the alternatives: see README.md."
  echo " Something wrong? see docs/TROUBLESHOOTING.md."
  echo " Want it gone? run: install.sh --uninstall"
  echo ""
  echo " Restart Claude Code (or start a new session) for skills,"
  echo " commands, and MCP servers to load."
fi
echo "============================================================"

[ "${#FAILED[@]}" -eq 0 ]
