#!/usr/bin/env bash
# Smoke test: detection, worker listing, and one trivial job per available worker.
# Run from inside a harness (or a plain terminal) — the current harness is skipped.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FARM="$ROOT/scripts/farm"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/farm-smoke.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

fail=0
ok()   { printf 'ok    %s\n' "$*"; }
bad()  { printf 'FAIL  %s\n' "$*"; fail=1; }

self=$("$FARM" detect)
[[ "$self" =~ ^(claude|codex|grok|unknown)$ ]] && ok "detect -> $self" || bad "detect printed '$self'"

if FARM_WORKER=codex "$FARM" detect | grep -qx codex; then ok "FARM_WORKER override"; else bad "FARM_WORKER override"; fi

workers=()
while IFS= read -r w; do [[ -n "$w" ]] && workers+=("$w"); done < <("$FARM" workers)
ok "workers -> ${workers[*]:-(none)}"

if [[ "$self" != unknown ]]; then
  if "$FARM" run "$self" "x" >/dev/null 2>&1; then bad "run refused self"; else ok "run refuses self ($self)"; fi
fi

printf 'Reply with exactly the word PONG and nothing else.\n' >"$WORK/ping.md"
for w in "${workers[@]}"; do
  out="$WORK/$w"
  if "$FARM" run "$w" -C "$WORK" -t 180 -o "$out" -f "$WORK/ping.md" >"$out.console" 2>&1 \
     && grep -q PONG "$out.result.md" && grep -q '^exit=0' "$out.meta"; then
    ok "run $w -> PONG ($(grep '^duration_s' "$out.meta"))"
  else
    bad "run $w (see $out.console, $out.stderr.log)"
    cat "$out.console" 2>/dev/null | sed 's/^/      /'
    trap - EXIT
  fi
done

if [[ ${#workers[@]} -ge 2 ]]; then
  : >"$WORK/jobs.tsv"
  for w in "${workers[@]}"; do printf '%s\tread-only\t%s\t%s\n' "$w" "$WORK" "$WORK/ping.md" >>"$WORK/jobs.tsv"; done
  if "$FARM" par "$WORK/jobs.tsv" -t 180 >"$WORK/par.console" 2>&1 \
     && [[ $(grep -l PONG "$WORK"/.farm/runs/*/*.result.md | wc -l) -ge ${#workers[@]} ]]; then
    ok "par ${#workers[@]} jobs"
  else
    bad "par (see $WORK/par.console)"; cat "$WORK/par.console" | sed 's/^/      /'; trap - EXIT
  fi
fi

exit $fail
