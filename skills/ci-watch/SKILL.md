---
name: ci-watch
description: Puts a pull request's CI under watch in the background, then reads its verdict and iterates until green. A red check is a fix to make; code scanning is read separately; the same check red twice, or an infrastructure failure, stops. Invoke right after pushing to a PR — review-loop and rewrite-history call it. Triggers: "watch the CI", "wait for CI on this PR", "is the CI green?".
---

# ci-watch

Input: the PR URL or number. CI is one more reviewer, not a red light to wait at: it starts without being waited for, and its verdict is read before pushing again.

## 1. Watch, without waiting

Run `gh pr checks <url> --watch` **in the background** (`Bash` with `run_in_background: true`), then carry on with whatever is left to do. In the seconds after a push, `gh pr checks` answers `no checks reported`: the workflows are not registered yet. Wait for that condition rather than guessing a delay — `timeout 120 sh -c 'until gh pr checks <n> >/dev/null 2>&1; do sleep 5; done'` before the `--watch`. CI and review work on the same diff without depending on each other; running them in parallel saves a full CI run per pass.

**This holds from the first pass**: the CI triggered by opening the PR is often still running when the work starts, and must not delay it. If it has already finished, `--watch` returns immediately. Check whether the project's workflows run on draft PRs before assuming a draft skips them.

> [!TIP]
> **Once the PR is open, CI is the authority: read `gh pr checks`, do not replay the suite locally on top of it.** It is already running, on a clean environment the local machine does not imitate. Replaying costs minutes and hides exactly the environment differences one wants to see.

## 2. When nothing else is left, wait blocking

"Without waiting" holds while there is something else to do: when there is nothing left, wait for the verdict within your own turn rather than handing back.

```sh
timeout 240 gh pr checks <n> --watch --interval 30
#   0 → all green          1 → a check failed
# 124 → still running, run the same command again
```

**A wait watches for a condition; it never counts time.** `gh pr checks --watch`, `gh run watch`, or `until <check>; do sleep 2; done` under `timeout`: the command returns when the awaited thing happens, or when the bound is hit. For the output of a background task, wait for its notification, or watch its output file with `until grep -q <pattern> <file>`.

**Bound every wait, and replay it**: the `Bash` tool cuts off at 600 s, and a command killed by that ceiling does not say whether the checks had finished — it says nothing at all. In slices of a few minutes, each leaves a trace, you stay steerable, and a waiting message is delivered in between.

## 3. Read the verdict

A red check is a **blocking** finding: read the logs (`gh run view <run-id> --log-failed`), fix, and group the fix with the other fixes in progress rather than making a separate cycle of it. If the failure shows the diff **does not build**, repair that first, then re-read the remaining findings against the repaired code before applying them. Do not interrupt review agents still running: their findings hold on the same diff.

**Static analysis is not read from the check's status.** A failing code-scanning check (CodeQL or other) shows "fail" without saying what; its alerts are fetched separately, on every pass, even when the check was green the time before — an alert introduced by a fix is found there and nowhere else:

```sh
gh api "repos/{owner}/{repo}/code-scanning/alerts?pr=<n>&state=open"
```

If the **same** check fails twice in a row despite a fix, or if the failure visibly does not come from the code (infrastructure flakiness, a runner that cannot bring up a service), stop iterating and tell the caller: which check, what its logs show, what was tried.

## What you return

One line: `green`; or `red: <check>, <what the logs show>, <what was tried>`; or `stopped: <same check twice | infrastructure>, <detail>`. The caller decides what comes next — push again, loop again, deliver a verdict.
