# Workers: how each harness is invoked headlessly

`scripts/farm run` builds these commands. This file documents them so you can diagnose a failed job from its `.meta` and `.stderr.log`, or run one by hand.

Before spawning, the dispatcher strips every harness env marker (`CLAUDECODE`, `CLAUDE_CODE_*`, `CODEX_*`, `GROK_*`) and sets `FARM_WORKER=<worker>`, so the worker's own `farm detect` reports itself and never the orchestrator. Prompts are passed via stdin or a file; nothing is shell-interpolated.

## Claude Code — `claude -p`

```sh
claude -p --output-format json --no-session-persistence \
  --permission-mode plan            # read-only;  --write → acceptEdits
  [--model MODEL] [--max-turns N] -- "<prompt>"
```

- Output: JSON envelope on stdout. `.result` is the final answer; `.total_cost_usd`, `.num_turns`, `.is_error` are also present.
- `--no-session-persistence` keeps worker runs out of your session history.
- Nested runs: Claude Code refuses to start when `CLAUDECODE` is set in the environment; the dispatcher unsets it.

## Codex — `codex exec`

```sh
printf '%s' "<prompt>" | codex exec --skip-git-repo-check --ephemeral \
  -C DIR -s read-only               # --write → -s workspace-write
  -o OUT.result.md [-m MODEL] -
```

- Output: the final assistant message is written to `-o` by codex itself; stdout carries the streamed transcript; stderr ends with `tokens used`.
- `--ephemeral` skips session persistence; `--skip-git-repo-check` lets it run in non-repo directories.
- The sandbox blocks network and `ps` by default. Research briefs should not go to codex unless network is enabled in `~/.codex/config.toml`.
- `codex exec review` exists for diff review; `farm` does not wrap it, run it directly when you want codex's native reviewer.

## Grok CLI — `grok -p`

```sh
printf '%s' "<prompt>" | grok --output-format json --permission-mode plan \   # --write → acceptEdits
  --cwd DIR --no-subagents [--model MODEL] [--max-turns N] --prompt-file /dev/stdin
```

- Output: JSON on stdout. `.text` is the final answer; `.total_cost_usd`, `.num_turns`, `.stopReason` are present.
- Grok's own safety layer may decline shell commands it judges risky (for example printing environment variables) even in `auto` mode; the job then returns a short refusal in `.text`. Rewrite the brief rather than escalating permissions.
- `--no-subagents` keeps a worker from fanning out further; remove it deliberately if a brief needs it.

## Detection markers

| Harness | Env vars set in child shells |
|---|---|
| claude | `CLAUDECODE`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_PID` |
| codex | `CODEX_THREAD_ID`, `CODEX_SESSION_ID`, `CODEX_SANDBOX`, `CODEX_VERSION`, `CODEX_CI` |
| grok | `GROK_SESSION_ID`, `GROK_AGENT` |

`farm detect` checks `FARM_WORKER` first, then codex, grok, claude markers (a child inherits its parent's markers, and codex/grok are more often the inner process), then walks parent process names. In codex's sandbox `ps` is forbidden, so the env path is the one that matters there.

## Output files per job

| File | Contents |
|---|---|
| `OUT.result.md` | final answer, plain text |
| `OUT.raw.json` | the JSON envelope (claude, grok); absent for codex |
| `OUT.stderr.log` | worker stderr |
| `OUT.meta` | `worker=`, `mode=`, `dir=`, `exit=`, `duration_s=`, `cost_usd=` when reported, `result=`, `cmd=` |

Exit code `124` means the `timeout` fired; `.result.md` gets a trailing `[farm] killed after Ns timeout` line.

## Adding a worker

1. Add its name to `WORKERS` and a `*_MARKERS` array in `scripts/farm`.
2. Add a `case` arm in `run()` that builds the command, and one in the result-parsing block.
3. Add it to `scrubbed_env`, this file, and the matrix in `triage.md`.
4. Extend `tests/smoke.sh`.
