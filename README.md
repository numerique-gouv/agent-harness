# agent-harness

Reusable skills for [Claude Code](https://code.claude.com), extracted from the harness a team runs daily on a spec-driven Rails project and stripped of everything specific to it. They follow the open [Agent Skills](https://agentskills.io) format — one folder per skill, a `SKILL.md` and the files it points to. Each is small, readable, and meant to be adapted.

## /review-loop

Runs `review → fix → review → fix…` on an open pull request until a pass confirms no blocking finding.

- **Independent reviewers.** Each pass hands the PR's full diff to reviewer sub-agents, each in a fresh context: a correctness reviewer and a simplifier on every pass; reviewers of error handling, tests, comments and type design when the diff touches them; and any reviewer the project adds, on the condition it sets.
- **Fixes by the author.** The agent that wrote the code confirms or rejects each finding against the cited code, classifies it blocking or not, and fixes it with the most mechanical change possible. A behavioural fix counts as verified only once its test has been seen going red without it.
- **CI in the background.** The companion skill [`ci-watch`](skills/ci-watch/SKILL.md) watches the PR's checks while the review runs; a red check is one more blocking finding.
- **A written trail.** Every pass is recorded in one review file per PR — reviewers launched, findings fixed, false positives rejected and why — and rejected findings are handed to the next pass's reviewers so they are not raised again.
- **Guardrails against looping.** Bounces, oscillations and ratchets between passes are detected and escalated rather than patched once more; five passes without convergence stop the loop with its cost.

Ask your agent to run it on a PR ("run review-loop on this PR"), or type `/review-loop` where your agent has slash commands.

**[Install `/review-loop`](docs/install_review_loop.md)** — the skills, the reviewers, and how to configure it for a project.
