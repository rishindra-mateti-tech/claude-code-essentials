# Install guide

## Prerequisites

- `git`
- `node` and `npm`
- `python` with `pip` (or `pip3`)

The installer checks for these and exits with a clear message if any are
missing, before touching anything.

## Windows

Use **Git Bash** or **WSL**. `install.sh` is a bash script; PowerShell
cannot run it directly.

```bash
curl -fsSL https://raw.githubusercontent.com/rishindra-mateti-tech/claude-code-essentials/main/install.sh | bash
```

If `curl` isn't available in your Git Bash install, download the script
first and run it locally instead:

```bash
curl -o install.sh https://raw.githubusercontent.com/rishindra-mateti-tech/claude-code-essentials/main/install.sh
bash install.sh
```

## macOS and Linux

Same command as above works directly in a standard terminal.

```bash
curl -fsSL https://raw.githubusercontent.com/rishindra-mateti-tech/claude-code-essentials/main/install.sh | bash
```

## Before you run it

Run the install from inside the project directory you want MCP servers
(`code-review-graph`, `context-mode`) registered for. It writes a
`.mcp.json` file there.

Consider a dry run first to see exactly what will happen without changing
anything:

```bash
bash install.sh --dry-run
```

## Flags

| Flag | Effect |
|---|---|
| `--dry-run` | Show every step that would run, install nothing |
| `--uninstall` | Remove everything this script installs, see [UNINSTALL.md](UNINSTALL.md) |
| `--skip-rtk` | Skip rtk (bash compression) |
| `--skip-gsd` | Skip get-shit-done (milestone commands) |
| `--skip-superpowers` | Skip the superpowers skill set |

## After install

Restart Claude Code, or start a new session. Skills, slash commands, and
MCP servers all load at session start, not mid-session, so nothing from
this install is active until you do.

To verify it worked, in a new session:

- Ask about an installed skill by name (e.g. "use ponytail on this") and
  confirm it responds as expected.
- Check that `code-review-graph` and `context-mode` MCP tools are
  available.
- Type `/gsd:help` to confirm the 31 GSD commands loaded.
- Run a verbose command like `pip list` and check whether rtk compressed
  it; if not, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## If something fails partway through

The installer tracks success and failure per component and prints an
honest summary at the end, including a "FAILED" list if anything didn't
install. It's safe to re-run; already-installed components are detected
and skipped or reinstalled cleanly by the underlying tools (`pipx`, `npm`,
`git clone`), not duplicated.
