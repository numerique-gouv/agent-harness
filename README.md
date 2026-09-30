# agent-harness

Reusable skills for coding agents, extracted from the harness a team runs daily on a spec-driven Rails project and stripped of everything specific to it. They follow the open [Agent Skills](https://agentskills.io) format — one folder per skill, a `SKILL.md` and the files it points to — so any agent that reads skills can use them. Each is small, readable, and meant to be adapted.

## Installation

Pick one route: installing through two of them leaves you with every skill twice.

<details open>
<summary><strong>Any agent, with the <code>skills</code> CLI</strong></summary>

[`skills`](https://github.com/vercel-labs/skills) installs into Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode, Claude Code and [many more](https://github.com/vercel-labs/skills#supported-agents). It asks which skills and which agents; take all three skills, since `review-loop` calls the other two.

```bash
npx skills@latest add numerique-gouv/agent-harness
```

Non-interactively, for given agents:

```bash
npx skills@latest add numerique-gouv/agent-harness --skill '*' -a codex -a cursor
```

Add `-g` to install for your user rather than for the current project. Pull later changes with `npx skills update`.

</details>

<details>
<summary><strong>Claude Code, as a plugin</strong></summary>

A managed, read-only bundle that updates when this repository does. From inside a session:

```
/plugin marketplace add numerique-gouv/agent-harness
/plugin install agent-harness@numerique-gouv
```

</details>

<details>
<summary><strong>By hand</strong></summary>

Copy the folders under `skills/` into the directory your agent reads skills from:

| Agent | Project | User |
| --- | --- | --- |
| Codex | `.agents/skills/` | `~/.codex/skills/` |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| Gemini CLI | `.agents/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| OpenCode | `.agents/skills/` | `~/.config/opencode/skills/` |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |

```bash
git clone https://github.com/numerique-gouv/agent-harness
cp -r agent-harness/skills/* .agents/skills/
```

</details>

### Prerequisites

- The [`gh`](https://cli.github.com) CLI, authenticated on the repository.
- An agent that can start sub-agents, or whose CLI runs non-interactively (`codex exec`, `gemini -p`, `claude -p`…): `review-loop` gives each reviewer a fresh context, and stops rather than reviewing its own work.

## Skills

| Skill | What it does |
| --- | --- |
| [`review-loop`](skills/review-loop/SKILL.md) | Review → fix on an open PR until a pass confirms no blocking finding, then rewrites the history. Fresh-context reviewers, fixes by the author, CI watched in the background |
| [`ci-watch`](skills/ci-watch/SKILL.md) | Watches a PR's CI in the background, reads its verdict and iterates until green; stops on the same check failing twice or on an infrastructure failure |
| [`rewrite-history`](skills/rewrite-history/SKILL.md) | Rewrites a branch into a short, readable list of commits: backup tag, identical tree, every commit parses, `--force-with-lease` |

`review-loop` calls the other two; they also work on their own. Ask your agent to run one by name ("run review-loop on this PR"), or use its slash command where it has one.

## Adapting `review-loop` to a project

It reads the project's agent instructions (`AGENTS.md`, `CLAUDE.md`…) for four things, all optional:

```md
## Review loop

- Test command: `make test`
- Specifications implemented: <links> — a violation of a normative rule is a blocking finding
- Extra reviewers: `layered-rails-reviewer` when the diff touches Ruby under `app/`
- Review files: `.scratch/reviews/`
```

Review files are working notes, one per PR; ignore their directory in git.

Reviewers are described by role, with a brief each, in [`reviewers.md`](skills/review-loop/reviewers.md). Where a dedicated reviewer of the same role is installed — the [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) agents, for instance — the loop uses it instead.
