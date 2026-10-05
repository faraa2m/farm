# Brief

You are a worker agent completing one bounded task. You have no other context than this brief and the files on disk. Do not ask questions; if something is ambiguous, pick the most conservative interpretation and state the assumption in your final answer.

## Goal

<!-- One or two sentences. What exists when you are done that does not exist now. -->

## Scope

<!-- Directory and files you may read. Files you may edit, if any. -->

- Working directory:
- May read:
- May edit:

## Constraints

<!-- Language/version, style rules, libraries to use or avoid, commands you may run. -->

## Done criteria

<!-- Observable facts the orchestrator will check. Prefer commands with expected output. -->

1.
2.

## Output format

<!-- What the final answer must contain, in order. Keep it machine-readable where possible. -->

Final answer must contain, in this order:
1. **Summary** — three lines max.
2. **Changes** — files touched with one line each (or "none").
3. **Verification** — the exact commands you ran and their results.
4. **Assumptions / open issues** — or "none".

## Do not

- Touch files outside *May edit*.
- Commit, push, install global packages, or change configuration outside the working directory.
- Claim a check passed without having run it.
