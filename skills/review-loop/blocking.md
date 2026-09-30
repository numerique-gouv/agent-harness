# Blocking or non-blocking

Read at step 4 of the loop, before classifying the first finding of a pass.

The reviewers do not label their own findings blocking or non-blocking — that classification is **entirely up to whoever runs the loop**, at step 4, by reading the cited code (or text), never the summary a reviewer gives of it. It is the easiest point of this skill to get wrong: classify too broadly and the review loops on comfort; too narrowly and real defects slip through. When genuinely in doubt after applying the rules below, treat the finding as non-blocking — it then does not make the loop go round again, but it stays visible in the review file.

- **Blocking**, only in **code** (never in a comment, never in documentation — see below):
  - a correctness bug;
  - a real security flaw;
  - a violation of a **normative** rule of a specification the project implements (a rule that constrains what the code does or emits, not a stylistic one);
  - anything that would break CI if left as is.
- **Non-blocking**, everything else — explicitly including:
  - **any error in a comment or in documentation**, even a factually wrong statement, a wrong attribution, a security mechanism described misleadingly, or a misquoted specification rule. Text stays text, never executed code, so never blocking in itself — fixed like any confirmed finding, but it does not force another pass. Treating textual errors as if they cost as much as a code bug is how a documentation-only PR ends up taking five passes;
  - **duplication**, including a breach of a "one fact, one place" documentation rule — unless both copies have already diverged in substance in **code** (one does something the other does not: a correctness bug, therefore blocking under the first criterion, not because of the duplication itself);
  - **omission / completeness** (a missing fact, an unreported nuance);
  - style, naming, cleanup, nitpicks, structure.
