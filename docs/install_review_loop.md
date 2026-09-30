# Installing `/review-loop`

`/review-loop` is two skills — `review-loop` and `ci-watch`, which it calls — and six reviewer sub-agents it delegates the review to. Install both, check the prerequisites, then tell the skill what it needs to know about your project.

## Install the skills

Pick one route: installing through both leaves you with every skill twice.

<details>
<summary><strong>For Claude Code, as a plugin</strong></summary>

A managed, read-only bundle that updates when this repository does. From inside a session:

```
/plugin marketplace add numerique-gouv/agent-harness
/plugin install agent-harness@numerique-gouv
```

</details>

<details>
<summary><strong>For any agent, with the <code>skills</code> CLI</strong></summary>

[`skills`](https://github.com/vercel-labs/skills) copies the skill files into your project, where you own and edit them, for [any other agent it supports](https://github.com/vercel-labs/skills#supported-agents). Take both `review-loop` and `ci-watch`.

```bash
npx skills@latest add numerique-gouv/agent-harness
```

Add `-g` to install for your user rather than for the current project. Pull later changes with `npx skills update`.

</details>

## Install the reviewers

`review-loop` delegates the review to the six sub-agents of Anthropic's [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) plugin: `code-reviewer`, `code-simplifier`, `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter` and `type-design-analyzer`. The loop stops without them.

```
/plugin install pr-review-toolkit@claude-plugins-official
```

On another agent, ask it to install them itself, in its own sub-agent format:

> Install the six agents of https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit/agents as your own sub-agents, keeping their names and prompts.

## Prerequisites

- The [`gh`](https://cli.github.com) CLI, authenticated on the repository.

## Configure it for a project

It reads the project's agent instructions (`AGENTS.md`, `CLAUDE.md`…) for four things, all optional:

```md
## Review loop

- Test command: `make test`
- Specifications implemented: <links> — a violation of a normative rule is a blocking finding
- Extra reviewers: `layered-rails-reviewer` when the diff touches Ruby under `app/`
- Review files: `.scratch/reviews/`
```

Review files are working notes, one per PR; ignore their directory in git.
