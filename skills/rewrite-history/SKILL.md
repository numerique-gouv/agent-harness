---
name: rewrite-history
description: Rewrites a branch's history into a short, readable list of commits — backup tag, rebuild, check that the tree is identical and that every commit parses, push with --force-with-lease, never a bare --force. review-loop calls it once converged. Triggers: "clean up the history of this branch", "squash the review fixes", "rewrite the branch history".
---

# rewrite-history

Locally, on a branch that has never been merged and so has no history to preserve. A branch that converges after several review passes carries a history written by the loop, not by the work: three successive versions of the same comment, a fix that repairs the previous fix, a "correct what the previous pass wrongly stated". Those second thoughts were useful during the loop; they are of no use to whoever reads the branch.

> [!NOTE]
> **After a rewrite, SHAs no longer point at anything.** They all change, and signing changes them again. Refer to a commit **by its message** in a review, a report or a conversation; a SHA that can no longer be found is normal, not a sign of loss.

## 1. Decide the shape

Aim for **a short, understandable list of commits, made for a human reader**. Two practical consequences: review fixes are absorbed into the commit they fix — what they taught moves up into its message, which becomes the right place to say why the code has this shape; and a fix unrelated to the branch's subject, a neighbouring bug found along the way, keeps its own commit, because that is exactly what a reviewer wants to be able to isolate. The right number follows from that; it is not set in advance.

## 2. Back up, rewrite, check

```sh
git -c tag.gpgsign=false tag -f backup-<topic> HEAD   # before touching anything
BASE=$(git merge-base origin/<default-branch> HEAD)
# rewrite: reset --hard "$BASE", then rebuild the commits
git diff backup-<topic> HEAD                          # MUST be empty
```

The `-c tag.gpgsign=false` is not decorative: where `tag.gpgsign` is enabled, a signed tag requires a message, and `git tag -f <name> HEAD` fails with `fatal: no tag message?`. A backup is a local, disposable marker; it has nothing to sign.

**The check that matters is on the final tree, not on each commit**: `git diff` between the backup and the new HEAD must be empty, otherwise the rewrite lost or added something. This skill rewrites a branch onto its own base; it is not for pushing a rebase onto the default branch, where that diff is never empty. Check also that what must parse parses at *each* commit (`sh -n`, `ruby -c`, `node --check`, `python -m py_compile`, as relevant) — a readable history is a bisectable history, and rebuilding intermediate states by hand is precisely what can produce a commit that does not stand on its own.

## 3. Push, only if everything checked out

```sh
git push --force-with-lease
```

`--force-with-lease`, never a bare `--force`: it refuses if someone pushed to the branch in the meantime, which is exactly the case where nothing must be overwritten. **If a single check failed, do not push**: hand back saying which one, the backup still in place.

The tree being bit-for-bit identical, the CI from before the rewrite already says what the one after will say — but it says it of a SHA the PR no longer carries. That is not the same claim, and the gap is not theoretical: a suite that brings up external services sometimes fails with no fault in the code. The force-push started a new CI run: invoke the `ci-watch` skill, and hand back only once it is green — otherwise "delivered" would be said of a state nobody saw green.

## 4. Leave a way back, or clean up

```sh
git reset --hard backup-<topic>   # go back to the previous history
git tag -d backup-<topic>         # or get rid of it
```

Tell the caller that the history was rewritten and pushed again, since the SHAs changed under whoever was following the PR, and leave them these two commands.
