# Changelog

All notable changes to this project are documented here.

## 2026-08-24

### Added

- Initial release: installer for ponytail, superpowers, code-review-graph,
  graphify, markitdown, context-mode, get-shit-done, and rtk, with a
  README documenting the reasoning behind each choice.
- Project banner and a before/after usage example in the README.
- `--dry-run`, `--uninstall`, `--skip-rtk`, `--skip-gsd`, and
  `--skip-superpowers` flags.
- `docs/UNINSTALL.md`, `docs/TROUBLESHOOTING.md`, `docs/TOOLS.md`,
  `docs/COMPARISONS.md`, `docs/INSTALL.md`, `SECURITY.md`.
- A shellcheck GitHub Action covering `install.sh`.
- A standalone architecture diagram showing the always-on vs.
  explicit-call tool split.
- A "Best combinations" section in the README with three stack profiles
  and the reasoning for the chosen default.
- Trust and safety, and Tested on, sections in the README.

### Changed

- `install.sh` now tracks success and failure per component honestly
  instead of always reporting success regardless of outcome.
- Default branch renamed from `master` to `main` to match README
  references.
- Fixed a placeholder install URL that pointed at a literal `<you>`.
- Fixed wording that described context-mode's `.mcp.json` registration
  as manual when the script actually performs it automatically.
- Removed all em dashes and en dashes from every file in the repo.
- Removed the Paxel row from the tool-comparison table; it isn't a real
  alternative to anything installed here.
- Reworded the design-taste-skill note to stop assuming the installer's
  user already has one installed.
