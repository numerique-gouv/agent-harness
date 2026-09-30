# Fixing a finding

Read at step 4, on the first confirmed finding of the loop, and at step 5 before saying "verified".

**Prefer the most mechanical fix to a rewrite**: delete rather than rephrase, link to the document that already owns the description rather than restating it, fix the exact point rather than reworking the whole sentence or paragraph around it. Every new line of prose written to fix a finding is itself a new chance of a finding at the next pass — a minimal fix closes that door instead of reopening it.

**A fix that asserts an external fact is checked as it is written, not at the next pass.** As soon as a fix states something the repository does not prove — a requirement of a standard and its identifier, a cardinality, the content of a certificate, the behaviour of a standard-library class, a count in a fixture — go and check it at the source **before** writing it, and note in the review file how it was checked (fetching the chapter, `openssl x509`, `grep` on the fixture). Two corollaries:

- **never a quotation you have not read in the source itself** — paraphrase what you actually observed;
- **never a figure describing an external system** ("the eleven other member states"): it is wrong or will become so, and the sentence stands without it.

These are, by far, the errors a loop makes most: an invented requirement identifier, a quotation absent from the certificate, a wrong count, a justification that reads a chapter backwards, a test premise the fixtures contradict, a comment describing a protection the code does not provide. None survives thirty seconds of checking at writing time; each costs a whole pass to find again.

> [!IMPORTANT]
> **A passing test does not prove it tests anything.** For every behavioural fix, verification takes three steps: **disable the fix, watch the test go red, restore it.** A test written after the fix often passes for reasons unrelated to it — a fixture that already satisfies the assertion, a path execution never reaches, a guard upstream that absorbs the case. Without having seen it go red, you have not verified the fix: you have verified that the suite still passes, which you already knew.
>
> The same requirement holds for what you **write** in the review file and in the report: "verified" is said only of what was seen failing, then passing. Announcing a verification that was not done is the one flaw that makes this loop useless — everything else is caught at the next pass.
