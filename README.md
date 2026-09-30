# agent-harness

Reusable skills for [Claude Code](https://code.claude.com), extracted from the harness a team runs daily on a spec-driven Rails project and stripped of everything specific to it. Each skill is small, readable, and meant to be adapted.

## Installation

Two ways in. **The [Claude Code plugin](https://code.claude.com/docs/en/plugins)** installs the whole set as a managed bundle that updates when this repository does. **[skills.sh](https://skills.sh)** copies the skill files into your project, where you own and edit them. Pick one: installing both leaves you with every skill twice.

<details>
<summary><strong>Claude Code plugin</strong></summary>

From inside a session:

```
/plugin marketplace add numerique-gouv/agent-harness
/plugin install agent-harness@numerique-gouv
```

</details>

<details>
<summary><strong>Editable copies, any agent</strong></summary>

```bash
npx skills@latest add numerique-gouv/agent-harness
```

Pull later changes with `npx skills update`.

</details>

### Prerequisites

- The [`gh`](https://cli.github.com) CLI, authenticated on the repository.
- Anthropic's [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) plugin, whose agents do the reviewing: `/plugin install pr-review-toolkit@claude-plugins-official`. `review-loop` stops if it is missing.

## Skills

| Skill | What it does |
| --- | --- |
| [`review-loop`](skills/review-loop/SKILL.md) | Review → fix on an open PR until a pass confirms no blocking finding, then rewrites the history. Fresh-context Sonnet reviewers, fixes by the author, CI watched in the background |
| [`ci-watch`](skills/ci-watch/SKILL.md) | Watches a PR's CI in the background, reads its verdict and iterates until green; stops on the same check failing twice or on an infrastructure failure |
| [`rewrite-history`](skills/rewrite-history/SKILL.md) | Rewrites a branch into a short, readable list of commits: backup tag, identical tree, every commit parses, `--force-with-lease` |

`review-loop` calls the other two; they also work on their own.

## Adapting `review-loop` to a project

It reads the project's `CLAUDE.md` (or `AGENTS.md`) for four things, all optional:

```md
## Review loop

- Test command: `make test`
- Specifications implemented: <links> — a violation of a normative rule is a blocking finding
- Extra reviewers: `layered-rails-reviewer` when the diff touches Ruby under `app/`
- Review files: `.claude/reviews/`
```

Review files are working notes, one per PR; ignore their directory in git.
