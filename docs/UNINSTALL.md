# Uninstalling

## Automatic

```bash
./install.sh --uninstall
```

Removes: ponytail skills, superpowers skills, get-shit-done commands, the rtk
binary, and the pipx/npm-installed tools (code-review-graph, graphify,
markitdown, context-mode).

## Left in place on purpose

The uninstaller does not touch these automatically, because they may hold
your own edits mixed in with what this script added:

**`~/.claude/CLAUDE.md`** — the two sections this script appended
(`## Ponytail (always use before writing code)` and
`## Token efficiency (from claude-token-efficient)`) are clearly headed.
Delete those two sections by hand; leave the rest of the file alone.

**`.mcp.json`** in any project you ran the installer from — delete the file,
or just remove the `code-review-graph` and `context-mode` entries if you
added others of your own.

**The rtk hook in `~/.claude/settings.json`** — if you manually added the
`hooks.PreToolUse` entry for rtk (see README), remove that block by hand.
Uninstalling the binary does not remove the hook config.

## Manual, tool by tool

If you only want one thing gone:

```bash
# skills
rm -rf ~/.claude/skills/ponytail ~/.claude/skills/ponytail-review \
       ~/.claude/skills/ponytail-audit ~/.claude/skills/ponytail-debt

# get-shit-done
rm -rf ~/.claude/commands/gsd ~/.claude/get-shit-done

# rtk
rm -f ~/.local/bin/rtk ~/.local/bin/rtk.exe

# pipx tools
pipx uninstall code-review-graph
pipx uninstall graphifyy
pipx uninstall markitdown

# context-mode
npm uninstall -g context-mode
```
