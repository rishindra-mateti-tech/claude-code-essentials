# Troubleshooting

## `/plugin` command not available

Some Claude Code environments (certain hosted or SDK-based desktop
sessions) don't expose the `/plugin` command system. This affects two
things in this repo:

- You can't swap rtk for token-optimizer (that swap needs `/plugin`).
- Nothing else here needs `/plugin`; everything installs through plain
  `pip`/`pipx`/`npm`/`git clone`, which work regardless.

If you need `/plugin`, use a standard `claude` CLI terminal session rather
than a hosted app session.

## rtk hook not firing (output stays uncompressed)

Run a verbose command like `pip list` or `git log`. If the output comes
back full-size instead of compressed, the hook isn't active. Two likely
causes:

**1. Settings were added after the session started.** Restart Claude Code
(or start a new session) so it re-reads `~/.claude/settings.json`.

**2. The environment doesn't run the standard `claude` CLI process.**
Confirmed during development: some hosted/SDK-based Claude Code sessions
don't read local hooks at all, even though `rtk init -g` reports success
and the hook config in `settings.json` is correctly formed. To check which
case you're in, test the binary directly:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"git status"}}' | rtk hook claude
```

If that prints a rewritten command, the binary and hook protocol are fine,
the problem is specifically that this session isn't invoking it. In that
case, either switch to a real `claude` CLI terminal, or invoke
`rtk <command>` manually for large-output commands until you can.

## `.mcp.json` already exists

The installer will not overwrite an existing `.mcp.json` in the directory
you run it from. It prints a warning and skips that step. Add the
`code-review-graph` and `context-mode` entries from the README's
["What install actually touches"](../README.md#what-install-actually-touches)
section by hand.

## Parser timeouts during `code-review-graph build`

You may see lines like:

```
Skipping unavailable tree-sitter parser for python: ... timed out after 5.0 seconds
```

This happens on cold start, when the parser's grammar hasn't been cached
yet, and can recur on slower machines even after a first successful build.
The index still builds and is still usable; affected languages fall back to
a lighter-weight parse rather than full AST extraction for that run. Running
`code-review-graph build` again sometimes clears it, sometimes doesn't;
either way, the tool remains functional even in fallback mode.

## pip install broke other Python projects

This is exactly why this repo uses `pipx` instead of `pip` for every
Python-based tool. If you installed something manually with plain `pip`
before finding this repo and now have dependency conflicts, check
`pip list` for unexpectedly recent versions of `starlette`, `pydantic`,
`websockets`, `httpx`, or `authlib`, and reinstall the versions your other
projects expect. Going forward, prefer `pipx install <tool>` for any
standalone CLI tool.

## Something else

Open an issue with the exact command you ran, the full output, and your
OS/shell (Git Bash, WSL, macOS, Linux).
