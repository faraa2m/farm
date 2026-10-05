# farm

A skill that lets local coding agents delegate to each other. Install it once into Claude Code, Codex, and Grok CLI; whichever one you are talking to becomes the orchestrator and can farm bounded work to the other two, in parallel, headlessly, with results on disk.

```
you ──▶ claude  (orchestrator: triage, briefs, verify, integrate)
           ├──▶ codex   exec  … -s workspace-write   (implement slice A, run tests)
           └──▶ grok    -p    … --permission-mode plan (research options for B)
```

Swap any name for any other: the skill is the same file in every harness, and `farm detect` tells it which one it is.

## Why

Each harness has a headless mode and different strengths — Codex's sandbox and test loop, Claude Code's multi-file reasoning, Grok's speed and web search. Without a shared protocol, using more than one means copy-pasting between terminals. `farm` gives the orchestrating agent a decision procedure (what is worth farming, to whom) and a single command to do it.

## Install

```sh
git clone https://github.com/faraa2m/farm.git
cd farm && ./install.sh
tests/smoke.sh        # one short job per installed worker
```

`install.sh` copies the skill into `~/.claude/skills/farm` (Claude Code; Grok also reads this), `~/.agents/skills/farm` (Codex), `~/.codex/skills/farm`, and `~/.grok/skills/farm`. Re-run after `git pull`. `uninstall.sh` removes all four.

Requirements: bash 4+, `jq`, `rsync`, GNU `timeout` (`brew install coreutils` on macOS), and at least two of `claude`, `codex`, `grok` on `PATH`.

## Use

In any of the three harnesses:

> /farm — survey retry strategies in the three HTTP libraries we use, and separately convert `fixtures/*.json` to schema v2 with tests passing.

The orchestrator runs `farm detect`, decides the survey goes to grok (read-only) and the conversion to codex (`--write`), writes a brief for each, runs both, reads the results, diffs codex's changes, runs the tests itself, and reports.

Direct use from a shell works too:

```sh
farm=~/.claude/skills/farm/scripts/farm
$farm detect
$farm workers
$farm run grok  -C . -f brief.md
$farm run codex -C . --write -t 1200 -f brief.md
$farm par jobs.tsv            # worker<TAB>read-only|write<TAB>dir<TAB>brief
```

Each job writes `OUT.result.md`, `OUT.meta` (exit, duration, cost), `OUT.stderr.log`, and for claude/grok the raw JSON. Default `OUT` is `.farm/runs/<timestamp>/<worker>-<n>`; `.farm/` is added to the repo's `.git/info/exclude`.

## Layout

| Path | Purpose |
|---|---|
| `SKILL.md` | The orchestrator protocol the agent follows |
| `scripts/farm` | Dispatcher: `detect`, `workers`, `run`, `par` |
| `references/triage.md` | Farmability test, worker strengths, modes, timeouts |
| `references/workers.md` | Exact headless invocation per harness, detection markers, how to add one |
| `templates/brief.md` | Task contract handed to a worker |
| `tests/smoke.sh` | Detection + PONG round-trip per worker |

## Design notes

- **Read-only by default.** `--write` maps to the harness's edit-without-prompting mode (`acceptEdits` / `workspace-write`); nothing ever bypasses sandboxes.
- **No self-farming.** `farm run` refuses the current harness; use its native subagents for that.
- **Markers are scrubbed.** Workers are spawned with the parent's `CLAUDECODE` / `CODEX_*` / `GROK_*` variables removed and `FARM_WORKER` set, so nested detection is correct.
- **Nothing is interpolated.** Prompts travel by file or stdin; commands are arrays.
- **No daemon, no state** beyond the run directory.

## License

MIT
