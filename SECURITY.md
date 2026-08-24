# Security

## What this script does and doesn't do

`install.sh` fetches each tool from its original upstream source at install
time (GitHub clones, `pip`/`pipx`, `npm`) and copies or configures it onto
your machine. Nothing in this repo is vendored or bundled; you're always
installing the real upstream project.

The script does not request, read, or transmit any secrets, API keys,
passwords, or credentials. It does not make network calls beyond fetching
the tools it installs (GitHub, PyPI, npm).

## Before you pipe this into bash

`curl | bash` runs code you haven't read. That's true of this script as
much as any other. Before running it:

```bash
curl -o install.sh https://raw.githubusercontent.com/rishindra-mateti-tech/claude-code-essentials/main/install.sh
less install.sh
```

Read it, then run `bash install.sh` locally. Or use `--dry-run` first to
see exactly what it would do without it doing anything:

```bash
bash install.sh --dry-run
```

## Why pipx, not plain pip

Every Python-based tool this script installs (`code-review-graph`,
`graphify`, `markitdown`) goes through `pipx`, which gives each one its own
isolated virtual environment. A plain `pip install` puts a tool's
dependencies into your global Python environment, which can silently
upgrade packages your other, unrelated projects depend on. That happened
during this repo's own development (`starlette`, `pydantic`, and
`websockets` got bumped and broke unrelated projects sharing the same
environment), which is why the installer was rewritten to use `pipx`
throughout instead.

## Trusting the upstream projects

This repo picks tools with real, checkable track records (GitHub stars,
commit history, independent adoption) and documents that evidence in
[docs/TOOLS.md](docs/TOOLS.md) and [docs/COMPARISONS.md](docs/COMPARISONS.md).
That's due diligence on maturity, not a security audit of each upstream
project's code. You're trusting those projects' maintainers when you run
this installer, the same as installing any third-party package.

## Reporting an issue

If you find a security problem specific to this repo (not the upstream
tools it installs), open an issue describing it. For problems in one of the
tools this installs, report to that project directly, links are in
[docs/TOOLS.md](docs/TOOLS.md).
