# The reviewer batch

Read at step 2 of every pass, before composing the batch.

## Contents

- Which agents, and on what condition
- The scope: the full diff
- The batch
- Project-specific reviewers
- The budget
- What every prompt says

## Which agents, and on what condition

**Review with the agents of Anthropic's official [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) plugin.** If it is not installed, say so and stop rather than improvising a review yourself: it carries the correctness review, on which the very notion of a blocking finding depends.

Not the `code-review` skill: it is user-invocable only (`disable-model-invocation`), and must not be worked around by re-implementing its pipeline by hand. `pr-review-toolkit` is a separate tool whose components are **agents**, launched through the `Agent` tool.

## The scope: the full diff

**Scope: the PR's full diff, on every pass** — `gh pr diff <url>`, never only the previous pass's fixes. A pass does not re-read the previous pass's fixes; it searches afresh on the current state of the diff: what a pass misses counts as much as what it introduces. Restricting to the last commit mechanically shrinks the batch below — a pass's fixes are always narrower than the findings that prompted them, so fewer conditions trigger, and nothing ever brings them back: a ratchet, not an oscillation. Observed: six agents at pass 1, then three, then two, then **one** at pass 4 — and the only blocking finding of the whole loop found at pass 5, on a full batch, by a `silent-failure-hunter` none of passes 2 to 4 would have launched.

`gh pr diff` breaks beyond 300 files (an API limit). Fall back to `git diff <base>...HEAD` locally, never to a subset of commits: a broken tool does not redefine the scope.

**Evaluate the conditions on the evidence, never from memory**: run `gh pr diff <url> --name-only`, plus a `grep -nE` for the language's error-handling keywords (`rescue`, `catch`, `except`, `recover`…) over the diff, **before** composing the batch. Coming out of step 4, you have in mind what you just fixed, not what the PR contains — the command neutralises that bias. Record in the review file which agents were launched and on what condition, so that shrinking is visible the moment it starts.

## The batch

Launch in parallel, each with `model: "sonnet"` set explicitly (never omitted nor left to `inherit`: most of the plugin's agents otherwise inherit the caller's model, which would defeat the independent eye sought) and without isolation (fresh agents, not forks):

- `code-reviewer` — **always**, with no condition or exception: the floor of a pass, including the last one and on a one-line diff;
- `silent-failure-hunter` — if the diff touches error handling (`catch`, fallback, code that could swallow an error);
- `pr-test-analyzer` — if test files changed;
- `comment-analyzer` — if comments or docstrings were added or modified;
- `type-design-analyzer` — if new types were introduced;
- `code-simplifier` — **always**, on the same terms as `code-reviewer`, and in parallel with the others rather than as a final sequential pass (the loop already sorts blocking from non-blocking at step 4).

## Project-specific reviewers

A project may ask, in its `CLAUDE.md` / `AGENTS.md`, for extra reviewer agents with the condition that triggers each — for instance `layered-rails-reviewer`, from the [layered-rails](https://github.com/palkan/skills) plugin, whenever the diff touches Ruby under `app/`. Add them to the same parallel batch, on the same terms (`model: "sonnet"`, fresh agent). Go through the agent rather than an equivalent skill: a review is an independent eye, so a fresh context, never your own.

Architecture reviewers of that kind find what no `pr-review-toolkit` agent looks for — inverted dependencies, business logic stranded in a controller, abstractions straddling two layers — and their findings are **non-blocking by default**, as [`blocking.md`](blocking.md) says. Without that rule, the loop would restart on design disagreements.

If a project-specific reviewer's plugin is missing, say so and carry on with the agents available.

## The budget

> [!IMPORTANT]
> **A pass is budgeted, never trimmed.** Each reviewer reads the whole diff, and there are four to seven of them: a pass typically costs close to a million fresh tokens — often more than planning and implementing the change together. That is expensive, and it is the price of the only net that catches blocking findings; savings are made elsewhere (fewer tool turns, shorter contexts), never by removing an agent from the batch. When the budget no longer allows a full pass, **stop the loop cleanly** — PR pushed, findings recorded in the review file — rather than launching a reduced one that gives the illusion of having looked.

## What every prompt says

Every agent receives the PR URL and how to read its diff (`gh pr diff <url>`); their verdicts are merged into a single list of findings before step 3, not handled as separate reviews.

**Tell every agent it must modify nothing — explicitly, including `git stash` and `git checkout`.** These agents have write tools, the loop works in a shared checkout, and the author fixes things *while* they read: an agent that runs `git stash` to read the pushed state carries off uncommitted fixes. Point them instead to `git show HEAD:<file>` if they want to read past the work in progress.

**Tell every agent what not to report**, in the same prompt: what it itself calls optional, low-confidence or not recommended; what predates the PR — a repository convention, a pattern shared by files the diff does not touch; and a guard against a case the only caller makes impossible — two fields written in the same stroke, a value already validated upstream, an input no outsider supplies. A finding it hesitates over, it keeps to itself. These few patterns account for most rejected findings, and some agents (`type-design-analyzer`, `code-simplifier`, architecture reviewers) see more than half of theirs rejected — every rejection is paid for in the author's context, the most expensive of the chain.

**From the second pass on, append to the prompt the false positives already recorded** in earlier passes of this loop (the "Rejected" sections of the previous `# Pass n`), with the reason for rejection, and ask not to raise them again without new evidence. A fresh-context agent has no memory of earlier passes: without this list, re-reading the full diff brings back every round what has already been settled, and that repetition is what tempts one to narrow the scope — and so the batch. Memory is paid once in the prompt rather than in coverage.
