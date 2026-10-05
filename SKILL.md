---
name: farm
description: Use when a request contains work that another local coding agent could do in parallel or independently — Claude Code, Codex, and Grok CLI farming bounded tasks to each other. Triggers — "/farm", "farm this out", "delegate this to codex / claude / grok", "run these in parallel across agents", "get a second opinion from another agent", "have codex review this", or any request with two or more independent, well-specified subtasks. Whichever harness is running becomes the orchestrator; it triages, writes briefs, dispatches headless jobs to the other installed harnesses via scripts/farm, then verifies and integrates the results. Do not use for single small edits, work that needs the user mid-task, or anything involving secrets.
---

# Farm

You are the orchestrator. Other harnesses are workers. The job: decide what to hand off, hand it off cleanly, and own the result.

`scripts/farm` (relative to this skill's directory) is the only interface to workers. Call it with the absolute path to this skill folder, e.g. `~/.claude/skills/farm/scripts/farm` — check which copy exists with `ls -d ~/.claude/skills/farm ~/.agents/skills/farm ~/.grok/skills/farm 2>/dev/null | head -1`.

## 1. Identify yourself

```sh
FARM=$(ls -d ~/.claude/skills/farm ~/.agents/skills/farm ~/.codex/skills/farm ~/.grok/skills/farm 2>/dev/null | head -1)/scripts/farm
$FARM detect     # claude | codex | grok | unknown
$FARM workers    # installed harnesses other than you
```

Never farm to yourself — `farm run` refuses it. Parallelism within your own harness is what your native subagents are for.

If `workers` prints nothing, say so and do the work yourself.

## 2. Triage — what is farmable

A subtask qualifies only if **all** hold:

- **Independent** — it does not share mutable files with other in-flight work, or it gets its own directory/worktree.
- **Self-contained** — you can state it in one brief with no reference to this conversation.
- **Checkable** — it has done-criteria you can verify yourself (tests pass, file exists with shape X, answer cites sources).
- **Worth a cold start** — roughly 3+ minutes of agent work. A worker starts with zero context; tiny tasks are faster done inline.

Never farm: the final integration, anything that needs a user decision mid-way, anything touching credentials or secrets, or destructive operations (deletes, force-pushes, deploys).

If nothing qualifies, say "nothing worth farming" in one line and proceed normally.

## 3. Pick a worker

| Worker | Reach for it when | Avoid when |
|---|---|---|
| **codex** | Autonomous code changes with a test loop inside a sandbox; an independent second-opinion review of a diff | Task needs network (sandbox blocks it by default) or long prose |
| **claude** | Multi-file reasoning, careful refactors, long-form docs, review with judgment calls | Cheap mechanical bulk work |
| **grok** | Fast breadth: research with web search, alternative-approach generation, summaries, quick drafts | Precise multi-file edits in a large repo |

Default to the cheapest worker that can clearly do it. Send the same brief to two workers only for review / second-opinion tasks, where disagreement is the signal.

Full matrix and rationale: `references/triage.md`.

## 4. Write the brief

One brief per job, from `templates/brief.md`. Fill every section — goal, scope, constraints, done-criteria, output format, do-not-touch. Write it to disk; never pass long prompts on the command line:

```sh
RUN=.farm/runs/$(date +%Y%m%d-%H%M%S); mkdir -p "$RUN"
cat > "$RUN/codex-1.brief.md" <<'EOF'
...
EOF
```

A brief the worker cannot complete without asking you a question is a bad brief. Rewrite it.

## 5. Dispatch

```sh
# one job; read-only by default
$FARM run grok  -C "$PWD" -f "$RUN/grok-1.brief.md"
# a job that may edit files under -C
$FARM run codex -C "$PWD" --write -t 1200 -f "$RUN/codex-1.brief.md"
# several at once: worker<TAB>mode<TAB>dir<TAB>brief
printf 'grok\tread-only\t%s\t%s\ncodex\twrite\t%s\t%s\n' "$PWD" "$RUN/grok-1.brief.md" "$PWD" "$RUN/codex-1.brief.md" > "$RUN/jobs.tsv"
$FARM par "$RUN/jobs.tsv"
```

Run jobs in the background and keep working on what you kept for yourself. Each job leaves `<out>.result.md`, `<out>.meta` (exit code, duration, cost), and `<out>.stderr.log`. `.farm/` is added to the repo's `.git/info/exclude` automatically.

Flags, per-harness invocation details, and failure modes: `references/workers.md`.

## 6. Verify and integrate

- Read every `.result.md` in full. Check `.meta` for `exit=` ≠ 0 or a timeout note.
- For `--write` jobs, `git diff` the worker's changes and run the tests yourself. The worker's claim that tests pass is not evidence.
- Reject work that misses the done-criteria: fix the brief, re-run, or finish it yourself. Do not splice in half-done output.
- Report to the user per worker: what it was asked, what it produced, what you kept or discarded, and the cost from `.meta` when present.

## Anti-patterns

- Farming to avoid thinking: if you cannot write the done-criteria, you do not understand the task yet.
- Farming context-heavy work: a worker that needs the conversation history will guess.
- Trusting the summary: always read the artifact the worker produced, not its description of it.
