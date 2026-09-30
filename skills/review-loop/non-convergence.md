# When the loop does not converge

Read at step 4, before handling a blocking finding that resembles an earlier one, and when five passes have followed one another.

This is not a cap on passes — it is a signal that things are not converging on their own, to be handled differently from "one more pass".

**Before treating a new blocking finding as routine (step 4), compare it with the earlier passes of this same loop** (the `# Pass n` sections of the review file, not only the conversation's memory, which may have been summarised): does it touch the same area, the same constraint, as a finding already "settled" in an earlier pass? Three shapes:

- **Simple bounce (A → A)**: the fix meant to settle A did not hold; the same finding reappears unchanged.
- **Oscillation (A ↔ B)**: fixing A made B appear, and fixing B as an ordinary finding would bring A back at the next pass — two constraints pulling against each other, not a failed fix.
- **Ratchet (A₁ → A₂ → A₃…)**: the **same invariant**, correctly fixed each time, but found again at the next pass *one notch further* — one more nesting level, one more caller, one more list level. The costliest shape, because every fix is legitimate on its own: nothing goes red, the pass congratulates itself, and the next occurrence turns up elsewhere. Typical example: "never cache an unusable response", extended five times — refusal, version fallback, malformed record, empty sub-list — before anyone asked what the standard said of the general case.

**Trigger: the second extension, not the fifth.** As soon as the same invariant is fixed a second time in a different place, stop fixing at the site and look for its **general statement in the source of truth** — the standard, the RFC, the library's contract. The rule that closes every level at once is nearly always already written there, and it is stated on the *result* rather than on the shape of the data. In the example above, it was one sentence of the standard: a directory with nothing to give **refuses**, it never succeeds empty — so a success with nothing to read is an unreadable response, at whatever depth.

In all three cases, **do not blindly try one more local fix** — step back:

1. Set side by side what A requires and what B (or the original A) requires, and why a local fix of one undoes the other — re-read, if needed, the standard or project instructions the findings cite; the real constraint is sometimes higher up than each finding alone suggests.
2. Look for a solution that satisfies both at once, not one that arbitrates between them — a broader design change rather than one more patch in the same place. If it exists: apply it as an ordinary fix (commit, re-test, push) and resume the loop normally — the next pass must check that it did break the cycle.
3. If, after a serious search, no solution satisfies both: stop and ask the user to arbitrate rather than deciding alone for one side or carrying on oscillating. State the tension explicitly — what each option costs, why they are incompatible as they stand, what was tried and why it does not work — not just "it's looping".

Separately, if five passes follow one another with no detectable bounce or oscillation (findings different each time and with no visible link), stop and report to the user anyway — beyond that number, something escaping the process is more likely than a genuinely slow convergence.

**The verification pass of a structural fix is the one exception to the full batch.** When a pass ends on a structural remedy — the one of point 2 above — and the only open question is "did this remedy break the cycle?", the next pass may be limited to `code-reviewer` and the reviewer that found the cycle, with a prompt asking that question rather than "review everything". This is not the shrinking this skill forbids elsewhere: the scope stays the full diff, it is the *question* that is targeted, and it is named in the review file. Every other pass keeps the whole batch.

**State the cost when handing back.** A pass is four to seven reviewers, each reading the whole diff — typically close to a million fresh tokens; five passes cost several times what implementing the change did. When the loop stops on this guardrail, give the user what they need to decide: how many passes ran, what each found, and what one more pass would cost — not just "it doesn't converge".
