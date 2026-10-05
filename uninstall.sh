#!/usr/bin/env bash
# Remove this skill from every harness's user-level skills directory.
set -euo pipefail

NAME=farm
for dest in "$HOME/.claude/skills/$NAME" "$HOME/.agents/skills/$NAME" \
            "$HOME/.codex/skills/$NAME" "$HOME/.grok/skills/$NAME"; do
  if [[ -d "$dest" ]]; then
    rm -rf "$dest"
    printf 'removed    %s\n' "$dest"
  fi
done
