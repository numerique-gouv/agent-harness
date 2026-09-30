# The reviewer batch

Read at step 2 of every pass, before composing the batch.

## Contents

- Who reviews: fresh reviewers, never you
- The scope: the full diff
- The batch
- Project-specific reviewers
- The budget
- What every prompt says

## Who reviews: fresh reviewers, never you

**The reviewers are the six sub-agents of Anthropic's [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit)**, installed in your agent as [the install guide](https://github.com/numerique-gouv/agent-harness/blob/main/docs/install_review_loop.md#install-the-reviewers) says. If they are not installed, say so, point to that section, and stop rather than improvising a review yourself: they carry the correctness review, on which the very notion of a blocking finding depends.

Each runs in a fresh context: never a fork of your own conversation, and never yourself — you wrote the code, and the point of the review is an eye that did not. Where your agent lets you choose the reviewers' model, pick it deliberately: a smaller, faster one is usually enough, and cheaper for a batch that reads the whole diff several times over.

## The scope: the full diff

**Scope: the PR's full diff, on every pass** — `gh pr diff <url>`, never only the previous pass's fixes. A pass does not re-read the previous pass's fixes; it searches afresh on the current state of the diff: what a pass misses counts as much as what it introduces. Restricting to the last commit mechanically shrinks the batch below — a pass's fixes are always narrower than the findings that prompted them, so fewer conditions trigger, and nothing ever brings them back: a ratchet, not an oscillation. Observed: six reviewers at pass 1, then three, then two, then **one** at pass 4 — and the only blocking finding of the whole loop found at pass 5, on a full batch, by a `silent-failure-hunter` none of passes 2 to 4 would have launched.

`gh pr diff` breaks beyond 300 files (an API limit). Fall back to `git diff <base>...HEAD` locally, never to a subset of commits: a broken tool does not redefine the scope.

**Evaluate the conditions on the evidence, never from memory**: run `gh pr diff <url> --name-only`, plus a `grep -nE` for the language's error-handling keywords (`rescue`, `catch`, `except`, `recover`…) over the diff, **before** composing the batch. Coming out of step 4, you have in mind what you just fixed, not what the PR contains — the command neutralises that bias. Record in the review file which reviewers were launched and on what condition, so that shrinking is visible the moment it starts.

## The batch

Launch in parallel where your agent allows it:

- `code-reviewer` — **always**, with no condition or exception: the floor of a pass, including the last one and on a one-line diff;
- `silent-failure-hunter` — if the diff touches error handling (`catch`, fallback, code that could swallow an error);
- `pr-test-analyzer` — if test files changed;
- `comment-analyzer` — if comments or docstrings were added or modified;
- `type-design-analyzer` — if new types were introduced;
- `code-simplifier` — **always**, on the same terms as `code-reviewer`, and in parallel with the others rather than as a final sequential pass (the loop already sorts blocking from non-blocking at step 4).

## Project-specific reviewers

A project may ask, in its agent instructions, for extra reviewers with the condition that triggers each — for instance an architecture reviewer such as `layered-rails-reviewer`, from [layered-rails](https://github.com/palkan/layered-rails-skills), whenever the diff touches Ruby under `app/`. Add them to the same batch, on the same terms: a fresh context, never your own.

If a project-specific reviewer is not available, say so and carry on with the others.

## The budget

> [!IMPORTANT]
> **A pass is budgeted, never trimmed.** Each reviewer reads the whole diff, and there are four to seven of them: a pass typically costs close to a million fresh tokens — often more than planning and implementing the change together. That is expensive, and it is the price of the only net that catches blocking findings; savings are made elsewhere (fewer tool turns, shorter contexts), never by removing a reviewer from the batch. When the budget no longer allows a full pass, **stop the loop cleanly** — PR pushed, findings recorded in the review file — rather than launching a reduced one that gives the illusion of having looked.

## What every prompt says

Every reviewer receives the PR URL and how to read its diff (`gh pr diff <url>`); their verdicts are merged into a single list of findings before step 3, not handled as separate reviews.

**Tell every reviewer it must modify nothing — explicitly, including `git stash` and `git checkout`.** Reviewers often have write tools, the loop works in a shared checkout, and the author fixes things *while* they read: a reviewer that runs `git stash` to read the pushed state carries off uncommitted fixes. Point them instead to `git show HEAD:<file>` if they want to read past the work in progress.

**Tell every reviewer what not to report**, in the same prompt: what it itself calls optional, low-confidence or not recommended; what predates the PR — a repository convention, a pattern shared by files the diff does not touch; and a guard against a case the only caller makes impossible — two fields written in the same stroke, a value already validated upstream, an input no outsider supplies. A finding it hesitates over, it keeps to itself. These few patterns account for most rejected findings, and some reviewers (`type-design-analyzer`, `code-simplifier`, architecture reviewers) see more than half of theirs rejected — every rejection is paid for in the author's context, the most expensive of the chain.

**From the second pass on, append to the prompt the false positives already recorded** in earlier passes of this loop (the "Rejected" sections of the previous `# Pass n`), with the reason for rejection, and ask not to raise them again without new evidence. A fresh reviewer has no memory of earlier passes: without this list, re-reading the full diff brings back every round what has already been settled, and that repetition is what tempts one to narrow the scope — and so the batch. Memory is paid once in the prompt rather than in coverage.
