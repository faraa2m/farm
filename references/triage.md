# Triage: deciding what to farm and to whom

## The farmability test

Ask these in order; the first "no" ends it.

1. **Can I write done-criteria I can check without the worker's help?** If verification requires trusting the worker's report, keep the task.
2. **Can the brief stand alone?** The worker has no transcript, no memory of what the user said, and no access to your reasoning. Everything it needs must be in the brief or on disk.
3. **Is it isolated?** Two workers editing the same file produce merge conflicts, not parallelism. Give each `--write` job its own directory or worktree, or make all but one job read-only.
4. **Is the cold start worth it?** A worker spends its first minute reading the repo. Below ~3 minutes of expected work, inline is faster and cheaper.
5. **Is it safe to run unattended?** Headless workers cannot ask the user anything. No secrets, no deploys, no deletes, no force-pushes, no payments.

## Shapes of work that farm well

- **Fan-out research** — "survey how libraries X, Y, Z handle retries; produce a comparison table with links." Grok, read-only.
- **Independent implementation slices** — one worker per module when module boundaries are clean. Codex with `--write`, one directory each.
- **Second opinions** — the same review brief to two workers; disagreements are where to look. Codex + Claude, read-only.
- **Bulk mechanical transforms with a test oracle** — "convert these 40 fixtures to the new schema; `npm test` must pass." Codex with `--write`.
- **Drafts you will edit anyway** — release notes, ADR skeletons, migration guides. Claude for long-form, Grok for quick.

## Shapes that do not farm

- Anything mid-conversation with the user (requirements still moving).
- Debugging where the key fact is in your context, not on disk.
- Final integration, merging, committing, PR creation.
- Tasks under a few minutes.

## Worker strengths

| | codex | claude | grok |
|---|---|---|---|
| Sandboxed file edits + test loop | strong (default sandbox) | good (`acceptEdits`) | good (`acceptEdits`) |
| Multi-file reasoning / refactor | good | strong | fair |
| Long-form writing | fair | strong | good |
| Web research | blocked by sandbox network policy | depends on tools enabled | strong (web search on by default) |
| Speed for short tasks | medium | medium | fast |
| Independent code review | strong (`codex exec review`) | strong | fair |

Costs vary by configured model; read `cost_usd` from each job's `.meta` and adjust.

## Choosing a mode

- `--read-only` (default): the worker may run commands and read files, not edit. Use for research, review, planning, answers.
- `--write`: the worker may edit under `-C DIR`. Use only with a test oracle and a `git diff` review afterwards.

## Timeouts

Default 900 s. Research and review: 300–600 s is plenty. Implementation with tests: 1200–1800 s. A killed job leaves a `[farm] killed after Ns timeout` line at the end of `.result.md`; treat partial output as untrusted.
