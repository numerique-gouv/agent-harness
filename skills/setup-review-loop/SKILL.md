---
name: setup-review-loop
description: Sets a repository up for review-loop, in conversation with the user — checks the skills and reviewers are installed, then settles the test command, the standards implemented, the review files and their .gitignore line, and any project-specific reviewer, and writes the "Review loop" block into the project's agent instructions. Run once per repository, and again to change the setup.
disable-model-invocation: true
---

# setup-review-loop

Walks the user through what [`review-loop`](../review-loop/SKILL.md) needs from a repository, and writes it down. A conversation, not a script: explore first, then settle one section at a time, then show the result and write only once the user agrees.

## 1. Explore

Read what exists before asking anything; never ask what the repository answers.

- **The agent instructions file**: `CLAUDE.md` or `AGENTS.md` at the root. Is there already a `## Review loop` block? If so, this run updates it.
- **The skills**: are `review-loop` and `ci-watch` both among your skills?
- **The reviewers**: are the six sub-agents of [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) — `code-reviewer`, `code-simplifier`, `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter`, `type-design-analyzer` — among the sub-agents you can launch?
- **`gh`, and the right to push**: `review-loop` reads the PR with `gh` and pushes its fixes to the PR's branch with `git`. Check all three, none of which writes anything:
  - `gh auth status` — installed, logged in, and on which account;
  - `gh repo view --json viewerPermission -q .viewerPermission` — `WRITE`, `MAINTAIN` or `ADMIN`; anything else cannot push to a branch of this repository;
  - `git push --dry-run origin HEAD` — git's own credentials reach the remote and are accepted for a push. `gh` being logged in does not prove it: git may use other credentials, or none.
- **The test command**: a `Makefile` target, the `scripts` of `package.json`, a `Rakefile`, `bin/`, the CI workflows under `.github/workflows/` — what CI runs is the best evidence of what the tests are.
- **Standards implemented**: external documents the code must comply with, as the instructions file or `docs/` name them — a standard, an RFC, a regulation, a published API contract.
- **The stack**: `Gemfile`, `package.json`, `pyproject.toml`, `go.mod`… It decides which project-specific reviewers are worth proposing.
- **`.gitignore`**: does it already ignore a directory for working notes?

## 2. Settle, one section at a time

Summarise what the exploration found, then take the sections in order. One section, one answer, then the next. Lead each with the recommended answer, so the user can accept it in a word; skip a section the exploration already settled, saying so in one line.

**A. Missing pieces.** If a skill, a reviewer or `gh` is missing, say which, and offer to fix it:

- in Claude Code, the reviewers install with `claude plugin install pr-review-toolkit@claude-plugins-official` — run it with the user's agreement, or give them `/plugin install pr-review-toolkit@claude-plugins-official` to type;
- on another agent, offer to create the six sub-agents yourself, in your own sub-agent format, from the [upstream files](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit/agents), keeping their names and prompts;
- `gh` and the git credentials are the user's to set up — never run a login, never handle a token. Say which check failed and what fixes it: `gh auth login` for `gh`; `gh auth setup-git` when `gh` is logged in but git has no credentials for the remote; a token with the `repo` scope, plus `workflow` if the PR may touch `.github/workflows/`; or a fork, when the account can only read this repository. Once the user says it is done, run the three checks again.

Newly installed sub-agents may only be visible from a new session; say so rather than checking for them again in this one. `review-loop` stops without the reviewers, so if the user declines, carry on with the setup but say it will not run until they are installed.

**B. Test command.** Propose what CI runs, or the obvious runner of the stack. One command, the one a contributor runs before pushing.

**C. Standards implemented.** If the project implements some, propose their links: a violation of one of their normative rules becomes a blocking finding. If none, skip the line.

**D. Review files.** Recommend `.scratch/reviews/`, or the directory the project already uses for working notes. Then ask whether to ignore it in git — recommended **yes**: review files are working notes, one per PR, and age badly in history. On yes, add the line to `.gitignore`, unless a pattern there already covers it.

**E. Project-specific reviewers.** Explain in one sentence: a reviewer for what only this project cares about, run in the same batch whenever its condition holds, its findings classified like everyone else's. Then propose what the stack suggests — for a Rails application, [`layered-rails-reviewer`](https://github.com/palkan/layered-rails-skills) when the diff touches Ruby under `app/` — and ask whether the user has others in mind. For each reviewer kept:

1. install it, as section A does — for `layered-rails-reviewer`, `claude plugin marketplace add palkan/layered-rails-skills` then `claude plugin install layered-rails@layered-rails-skills` in Claude Code; elsewhere `npx skills@latest add palkan/layered-rails-skills --skill layered-rails`, then create a sub-agent named `layered-rails-reviewer` from [its upstream prompt](https://github.com/palkan/layered-rails-skills/blob/master/layered-rails/agents/layered-rails-reviewer.md);
2. settle its condition with the user, stated on the diff (paths, languages, file kinds). No condition means every pass, and every pass costs a full read of the diff: say so.

Propose nothing you cannot name a source for; a reviewer the user describes but that does not exist yet is theirs to write, not yours to improvise.

## 3. Confirm

Show the user, in one message, everything this run will write:

- the block for the instructions file:

  ```md
  ## Review loop

  - Test command: `<command>`
  - Standards implemented: <links>
  - Extra reviewers: `<name>` when <condition>
  - Review files: `<directory>`
  ```

  leaving out every line that has nothing to say;
- the `.gitignore` line, if any.

Let them edit it before writing.

## 4. Write

- **The file**: `CLAUDE.md` if it exists, else `AGENTS.md`. If neither exists, ask which to create; never create one when the other is there.
- **The block**: replace an existing `## Review loop` block in place; otherwise append it. Touch nothing else in the file.
- **`.gitignore`**: append the line, with nothing else.

Do not commit: say which files changed, and leave the commit to the user.

## 5. Done

Say what `review-loop` will now read from the block, that it can be edited by hand at any time, and that running this skill again updates it. If anything from section A is still missing, repeat it last.
