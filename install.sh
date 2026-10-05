#!/usr/bin/env bash
# Copy this skill into every local harness's user-level skills directory.
#   ~/.claude/skills  Claude Code (also read by Grok CLI)
#   ~/.agents/skills  Codex
#   ~/.codex/skills   Codex, legacy location kept in sync
#   ~/.grok/skills    Grok CLI
set -euo pipefail

SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NAME=farm
TARGETS=(
  "$HOME/.claude/skills/$NAME"
  "$HOME/.agents/skills/$NAME"
  "$HOME/.codex/skills/$NAME"
  "$HOME/.grok/skills/$NAME"
)

for dest in "${TARGETS[@]}"; do
  mkdir -p "$dest"
  rsync -a --delete \
    --exclude '.git' --exclude '.github' --exclude 'tests' \
    --exclude 'install.sh' --exclude 'uninstall.sh' \
    "$SRC/" "$dest/"
  chmod +x "$dest/scripts/farm"
  if [[ -f "$dest/SKILL.md" && -x "$dest/scripts/farm" ]]; then
    printf 'installed  %s\n' "$dest"
  else
    printf 'FAILED     %s\n' "$dest" >&2
    exit 1
  fi
done

printf '\nSmoke test (spawns one short job per installed worker):\n  %s/tests/smoke.sh\n' "$SRC"
