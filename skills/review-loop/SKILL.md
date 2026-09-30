---
name: review-loop
description: Review → fix loop on an already-open pull request, repeated until a pass confirms no blocking finding, then rewrites the branch history. Fresh-context reviewers, fixes made by the author, CI watched in the background. Works on any PR, alone or called by a shipping skill. Triggers: "/review-loop", "run the review loop on this PR", "review and fix this PR until it's clean".
---

# review-loop

Runs `code → review → fix → review → fix → …` on an open pull request until it converges. The PR must already exist: this skill does not push the branch into existence, does not rewrite the final PR description, posts no summary comment and reports nothing to the user in chat. It **returns** to its caller what happened — passes run, review file written, what was fixed and what was rejected in each pass, ambiguous findings awaiting a decision — and the caller decides how to relay it.

It relies on two companion skills shipped alongside it: [`ci-watch`](../ci-watch/SKILL.md) and [`rewrite-history`](../rewrite-history/SKILL.md).

## Input

The PR URL, as an argument. Without one, derive it with `gh pr view --json url -q .url` on the current branch; if that fails (no PR for this branch), stop and say so.

## Project settings

Read the project's agent instructions (`AGENTS.md`, `CLAUDE.md`, or whatever file your agent loads) before the first pass, and take from it, when present:

- **the test command** (`make test`, `npm test`, `bundle exec rspec`…); without one, look for the obvious runner of the stack and say which one you used;
- **the specifications the project implements**, if any — they decide what counts as a normative violation in [`blocking.md`](blocking.md) and where to look for the general rule in [`non-convergence.md`](non-convergence.md);
- **extra reviewers** the project asks for, with their condition — see [`reviewers.md`](reviewers.md#project-specific-reviewers);
- **where review files go**, if the project names a directory; otherwise `.scratch/reviews/`.

## The loop

Repeat as long as the last pass confirmed at least one **blocking** finding; stop as soon as a pass finds none (zero blocking, with or without non-blocking ones). One pass:

1. **Put CI under watch, without waiting for it**: invoke the `ci-watch` skill, then move straight on to step 2. Its verdict is collected at step 4b and required at step 6.

2. **Launch the review** on the PR's full diff, with the reviewer batch of [`reviewers.md`](reviewers.md) — who reviews, which reviewers on which condition, what each prompt says, the budget. Conditions are evaluated on the evidence (`gh pr diff <url> --name-only`), never from memory; `code-reviewer` and `code-simplifier` run on every pass; every reviewer runs in a fresh context, with the order to modify nothing. Their verdicts are merged into a single list of findings before step 3.

3. **Write the review file** at `<reviews-dir>/YYYY-MM-DD-<topic>.md` in the main checkout as soon as the findings arrive, before handling any of them — even with no finding at all, with one line saying the review passed clean. **Mandatory header: the scope reviewed and the list of reviewers launched, with the condition that triggered each** — this is what makes a shrinking batch visible from one pass to the next instead of discovered afterwards. From the second pass on, each pass is appended **to the same file** under a `# Pass n` heading — one file per PR, not one per pass.

4. **Handle the findings one by one** — yourself, in your own context, not through a fresh sub-agent. The review is deliberately given to context-free reviewers for an independent eye; the fix stays with the author of the implementation, who already holds the context it needs. From most to least severe: re-read the cited code, confirm or reject each finding on the evidence (never on the reviewer's summary alone), and classify it blocking / non-blocking according to [`blocking.md`](blocking.md). Classification is entirely the job of whoever runs the loop, and it is the easiest thing here to get wrong.
   - Confirmed (blocking or not) → fix it directly, as [`fixing.md`](fixing.md) says — the most mechanical fix possible, every external fact checked as it is written — one commit per coherent group. Both categories get fixed; only a blocking one forces another pass.
   - False positive → leave the code alone; record why in one line, under a **"Rejected"** section of this pass in the review file. It feeds the final report, and it is appended to the prompt of the next pass's reviewers: that is the only place they can learn it from.
   - Ambiguous, or committing to a design choice → stop and ask; do not decide in the user's place — whatever the pass.
   - A blocking finding that looks like one from an earlier pass → read [`non-convergence.md`](non-convergence.md) before treating it as routine: a bounce, an oscillation or a ratchet call for stepping back, not one more local fix.

4b. **Collect the CI verdict** before pushing again — the one `ci-watch` returns. A red check is a **blocking** finding of this pass, fixed and grouped with the step 4 fixes rather than in a separate cycle; the same check failing twice, or an infrastructure failure, goes back to the user.

5. **Re-test** with the project's test command after the fixes. Suites that need an environment the local machine lacks are read from CI, through `ci-watch`, not replayed locally. For every behavioural fix, verification takes three steps — **disable the fix, watch the test go red, restore it** ([`fixing.md`](fixing.md)). Then push (`git push`).

6. Was a blocking finding confirmed in this pass (review **or** CI)?
   - Yes → back to step 1 for a new pass — unless five passes have followed one another without any bounce or oscillation showing from one to the next: [`non-convergence.md`](non-convergence.md) then says to stop and report, with the cost.
   - No → leave only once the CI of the last push is **green**: this is the one moment it is actually waited for. Red → blocking, back to step 1. Green → go to step 7.

   **And the review file exists on disk, one section per pass**: an `ls <reviews-dir>` before leaving, not the memory of having written it. If it is missing, the pass never happened for anyone else — write it from what you have, then carry on. Without it, the false positives of a pass are relayed to nobody, and the next loop on the same code pays for them again.

7. **Rewrite the history**: invoke the `rewrite-history` skill, which backs up, rewrites, checks the tree, pushes with `--force-with-lease` and waits for the CI of the new SHA. Red is a blocking finding like any other: back to step 1. Then return to the caller.

## Guardrails

- **A pass launching fewer than two reviewers is an execution bug**, never a legitimate optimisation. A pass is budgeted, never trimmed — when the budget no longer allows a full pass, stop the loop cleanly, PR pushed, findings recorded.
- **A blocking finding is read in cited code**, never in a reviewer's summary, a comment or documentation.
- **"Verified" is said only of what was seen failing, then passing.** Announcing a verification that was not done is the one flaw that makes this loop useless — everything else is caught at the next pass.
