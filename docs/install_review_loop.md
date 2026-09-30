# Installing `/review-loop`

`/review-loop` is two skills — `review-loop` and `ci-watch`, which it calls — and six reviewer sub-agents it delegates the review to. A third skill, `setup-review-loop`, sets a repository up for it.

> [!TIP]
> **Install the skills, then type `/setup-review-loop`.** It checks that the reviewers and `gh` are there and offers to install what is missing, then settles with you, one question at a time, the test command, the standards the project implements, where review files go and whether git ignores them, and any project-specific reviewer — and writes it all into your `CLAUDE.md` or `AGENTS.md`. The sections below are the same steps, by hand.

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

[`skills`](https://github.com/vercel-labs/skills) copies the skill files into your project, where you own and edit them, for [any other agent it supports](https://github.com/vercel-labs/skills#supported-agents). Take `review-loop`, `ci-watch` and `setup-review-loop`.

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
- Standards implemented: <links> — external documents the code must comply with (standards, RFCs, regulations, API contracts); a violation of one of their normative rules is a blocking finding
- Extra reviewers: `layered-rails-reviewer` when the diff touches Ruby under `app/`
- Review files: `.scratch/reviews/`
```

Review files are working notes, one per PR; ignore their directory in git.

## Add project-specific reviewers

The six reviewers look for what any codebase can get wrong. A project can add reviewers for what only it cares about, like an architecture, a framework's conventions or a standard, and the loop runs them in the same batch, in a fresh context, whenever their condition holds.

Two steps:

1. **Install the reviewer as a sub-agent** of your agent.
2. **Name it in the project's agent instructions**, with the condition that triggers it, on the `Extra reviewers` line of the block above. The loop evaluates the condition against the PR's diff at every pass. Without a condition, it runs on every pass.

If a reviewer named there is not installed, the loop says so and carries on with the others.

### Example: `layered-rails-reviewer`

[layered-rails](https://github.com/palkan/layered-rails-skills) reviews Rails code for layered-architecture violations: business logic in controllers, callbacks to extract, god objects, dependencies pointing the wrong way.

In Claude Code:

```
/plugin marketplace add palkan/layered-rails-skills
/plugin install layered-rails@layered-rails-skills
```

On another agent, install the skill, then ask the agent to create the sub-agent:

```bash
npx skills@latest add palkan/layered-rails-skills --skill layered-rails
```

> Create a sub-agent named `layered-rails-reviewer`, whose prompt is the one of https://github.com/palkan/layered-rails-skills/blob/master/layered-rails/agents/layered-rails-reviewer.md, pointing at the `layered-rails` skill you just installed.

Then, in the project's agent instructions:

```md
## Review loop

- Extra reviewers: `layered-rails-reviewer` when the diff touches Ruby under `app/`
```
