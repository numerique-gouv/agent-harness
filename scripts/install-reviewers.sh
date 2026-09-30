#!/bin/sh
# Installs the six reviewers of Anthropic's pr-review-toolkit (Apache-2.0) as
# sub-agents of the given coding agent. Only the prompt bodies are taken
# upstream: their frontmatter targets Claude Code, so each agent's is written here.
#
#   install-reviewers.sh <codex|cursor|gemini|opencode> [--global]
set -eu

UPSTREAM_REF=2a8ad9f74633d10e3d9bb0660a03bfc6e50584b1
UPSTREAM="https://raw.githubusercontent.com/anthropics/claude-plugins-official/$UPSTREAM_REF/plugins/pr-review-toolkit/agents"

usage() {
  echo "usage: install-reviewers.sh <codex|cursor|gemini|opencode> [--global]" >&2
  exit 2
}

[ $# -ge 1 ] || usage
AGENT=$1
SCOPE=project
[ "${2:-}" = "--global" ] && SCOPE=global

case "$AGENT:$SCOPE" in
  codex:project)    DIR=.codex/agents ;;
  codex:global)     DIR=$HOME/.codex/agents ;;
  cursor:project)   DIR=.cursor/agents ;;
  cursor:global)    DIR=$HOME/.cursor/agents ;;
  gemini:project)   DIR=.gemini/agents ;;
  gemini:global)    DIR=$HOME/.gemini/agents ;;
  opencode:project) DIR=.opencode/agents ;;
  opencode:global)  DIR=$HOME/.config/opencode/agents ;;
  *) usage ;;
esac

describe() {
  case "$1" in
    code-reviewer)         echo "Reviews a diff for correctness bugs, security flaws and breaches of the project's written guidelines." ;;
    code-simplifier)       echo "Reviews a diff for code more complex than it needs to be, preserving behaviour." ;;
    comment-analyzer)      echo "Reviews comments and docstrings for accuracy against the code and long-term maintainability." ;;
    pr-test-analyzer)      echo "Reviews a pull request's tests for coverage of the behaviour it introduces." ;;
    silent-failure-hunter) echo "Reviews a diff for silent failures, swallowed errors and fallbacks that hide a real failure." ;;
    type-design-analyzer)  echo "Reviews new types for the invariants they express and enforce, and their encapsulation." ;;
  esac
}

body() {
  awk 'fence >= 2 { print; next } /^---[[:space:]]*$/ { fence++ }' "$1"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$DIR"

for name in code-reviewer code-simplifier comment-analyzer pr-test-analyzer silent-failure-hunter type-design-analyzer; do
  curl -fsSL "$UPSTREAM/$name.md" -o "$TMP/$name.md"
  body "$TMP/$name.md" > "$TMP/$name.body"
  [ -s "$TMP/$name.body" ] || { echo "empty prompt for $name: upstream format changed" >&2; exit 1; }
  description=$(describe "$name")

  case "$AGENT" in
    codex)
      if grep -q "'''" "$TMP/$name.body"; then
        echo "$name: prompt contains ''' and cannot be written as a TOML literal string" >&2
        exit 1
      fi
      {
        printf 'name = "%s"\n' "$name"
        printf 'description = "%s"\n' "$description"
        printf 'sandbox_mode = "read-only"\n'
        printf "developer_instructions = '''\n"
        cat "$TMP/$name.body"
        printf "'''\n"
      } > "$DIR/$name.toml"
      ;;
    cursor)
      { printf -- '---\nname: %s\ndescription: %s\nreadonly: true\n---\n' "$name" "$description"; cat "$TMP/$name.body"; } > "$DIR/$name.md"
      ;;
    gemini)
      { printf -- '---\nname: %s\ndescription: %s\n---\n' "$name" "$description"; cat "$TMP/$name.body"; } > "$DIR/$name.md"
      ;;
    opencode)
      { printf -- '---\ndescription: %s\nmode: subagent\npermission:\n  edit: deny\n---\n' "$description"; cat "$TMP/$name.body"; } > "$DIR/$name.md"
      ;;
  esac
  echo "installed $name in $DIR"
done
