#!/bin/bash
# claude-code-agents / install.sh
#
# Installs subagents from this repo to your user Claude config directory
# (~/.claude/agents/). Safe to re-run — will overwrite existing files
# with the same name (confirmed interactively).

set -euo pipefail

# Resolve repo root regardless of where the script is called from
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="${REPO_ROOT}/agents"
CLAUDE_AGENTS_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/agents"

# ---- pre-flight checks --------------------------------------------------

if [[ ! -d "${AGENTS_SRC}" ]]; then
    echo "❌ agents/ directory not found at ${AGENTS_SRC}"
    echo "   Are you running this from the repo root?"
    exit 1
fi

# Count .md files, excluding README.md
AGENT_COUNT=$(find "${AGENTS_SRC}" -maxdepth 1 -name "*.md" ! -name "README.md" | wc -l | tr -d ' ')

if [[ "${AGENT_COUNT}" -eq 0 ]]; then
    echo "❌ No agent .md files found in ${AGENTS_SRC}"
    exit 1
fi

# ---- install ------------------------------------------------------------

mkdir -p "${CLAUDE_AGENTS_DIR}"

echo "📦 Installing ${AGENT_COUNT} agent(s) to ${CLAUDE_AGENTS_DIR}"
echo ""

for agent in "${AGENTS_SRC}"/*.md; do
    name="$(basename "${agent}")"

    # Skip the agents-level README
    if [[ "${name}" == "README.md" ]]; then
        continue
    fi

    dest="${CLAUDE_AGENTS_DIR}/${name}"

    if [[ -f "${dest}" ]]; then
        # File already exists — check if it is identical
        if cmp -s "${agent}" "${dest}"; then
            echo "  ✓ ${name} (already up to date)"
            continue
        fi
        read -r -p "  ⚠️  ${name} exists and differs. Overwrite? [y/N] " reply
        case "${reply}" in
            [yY]|[yY][eE][sS])
                cp "${agent}" "${dest}"
                echo "  ✓ ${name} (overwritten)"
                ;;
            *)
                echo "  - ${name} (skipped)"
                ;;
        esac
    else
        cp "${agent}" "${dest}"
        echo "  ✓ ${name} (installed)"
    fi
done

# ---- post-install hints -------------------------------------------------

echo ""
echo "✅ Done."
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code (or open a new session)."
echo "  2. Run /agents to verify both agents appear in the Library tab."
echo "  3. Try a test prompt. Example for codebase-explorer:"
echo ""
echo "       このリポジトリで設定ファイルの読み込みはどう実装されてる？"
echo ""
echo "Installed agents:"
ls -1 "${CLAUDE_AGENTS_DIR}" | sed 's/^/  - /'
