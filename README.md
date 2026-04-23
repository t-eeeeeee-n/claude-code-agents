# claude-code-agents

My personal collection of Claude Code subagents.

Each subagent lives in its own independent context, handles a focused task,
and returns only a summary — keeping the main conversation clean and focused.

## What's inside

| Agent | Purpose | When it fires |
|---|---|---|
| [`codebase-explorer`](agents/codebase-explorer.md) | Read-only codebase investigation | Questions about where something is implemented, how a feature works, or how to extend existing code |
| [`ui-design-reviewer`](agents/ui-design-reviewer.md) | Review HTML/CSS mocks against a DESIGN.md spec | After generating UI mocks, or when asked to check design compliance |

All agents in this repo share three principles:

- **Read-only** — they investigate and report, they never modify files
- **Summarize, don't dump** — return a concise synthesis, not raw file contents
- **Independent context** — delegated work does not bloat the main conversation

## Installation

```bash
# Clone somewhere you keep your tools
git clone https://github.com/<your-username>/claude-code-agents.git
cd claude-code-agents

# Install to your user Claude config
./install.sh
```

Or manually:

```bash
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
```

Restart Claude Code, then verify with `/agents` — both should appear in the
Library tab.

## Why subagents

Subagents exist to solve one specific problem: **context pollution**.

When you ask Claude Code "how does authentication work in this repo?", the
naive approach is to read 10 files, grep a few patterns, and trace through
the code — all of which accumulates in your main conversation's context.
A few such investigations in, and you have 40% of your context window
filled with stuff you will never reference again.

A subagent does the same investigation in its own context window, returns
a 500-token summary, and your main conversation stays clean. The difference
compounds over a working session.

This repository exists so I can replicate the setup across machines with one
`git clone && ./install.sh`, and so the patterns are documented somewhere
I can revisit when building new agents.

## Each agent in detail

Usage guides, verification tests, and customization notes live in
[`agents/README.md`](agents/README.md).

## Companion: ui-bootstrap

`ui-design-reviewer` pairs naturally with [ui-bootstrap](https://github.com/<your-username>/ui-bootstrap),
a workflow kit for generating UI mocks from brand-inspired `DESIGN.md` files.
The reviewer picks up where `ui-bootstrap`'s mechanical `/ui-mock-check` leaves
off — catching semantic and cross-screen issues that grep alone cannot detect.

## Roadmap

Agents I may add as needs arise:

- `pattern-reviewer` — naming and structural consistency across the codebase
- `security-reviewer` — OWASP Top 10 oriented review
- `dependency-auditor` — package.json / lock file audit
- `test-writer` — reverse-engineer tests from existing implementations

All candidates will follow the same three principles (read-only, summarize,
independent context). If you have suggestions, open an issue.

## License

MIT. Feel free to copy, adapt, and ship your own variants.
