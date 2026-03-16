#!/usr/bin/env bash
# Installs claude-code-actions into the current repository.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/hauxir/claude-code-actions/master/install.sh | bash
#   # or
#   git clone https://github.com/hauxir/claude-code-actions.git /tmp/cca && /tmp/cca/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If running from a clone, use that. Otherwise, download from GitHub.
if [ -d "$SCRIPT_DIR/.github" ]; then
  SRC="$SCRIPT_DIR"
else
  SRC=$(mktemp -d)
  echo "Downloading claude-code-actions..."
  git clone --depth 1 https://github.com/hauxir/claude-code-actions.git "$SRC" 2>/dev/null
  trap "rm -rf $SRC" EXIT
fi

# Ensure we're in a git repo
git rev-parse --git-dir > /dev/null 2>&1 || { echo "Error: not in a git repository"; exit 1; }
REPO_ROOT=$(git rev-parse --show-toplevel)

echo "Installing into $REPO_ROOT..."

# Copy workflows
mkdir -p "$REPO_ROOT/.github/workflows"
for f in "$SRC/.github/workflows"/*.yml; do
  name=$(basename "$f")
  if [ -f "$REPO_ROOT/.github/workflows/$name" ]; then
    echo "  SKIP .github/workflows/$name (already exists)"
  else
    cp "$f" "$REPO_ROOT/.github/workflows/$name"
    echo "  ADD  .github/workflows/$name"
  fi
done

# Copy setup-dev-env action (only if not present)
mkdir -p "$REPO_ROOT/.github/actions/setup-dev-env"
if [ ! -f "$REPO_ROOT/.github/actions/setup-dev-env/action.yml" ]; then
  cp "$SRC/.github/actions/setup-dev-env/action.yml" "$REPO_ROOT/.github/actions/setup-dev-env/action.yml"
  echo "  ADD  .github/actions/setup-dev-env/action.yml"
else
  echo "  SKIP .github/actions/setup-dev-env/action.yml (already exists)"
fi

# Copy helper scripts
mkdir -p "$REPO_ROOT/scripts/github"
for f in "$SRC/scripts/github"/*.sh; do
  name=$(basename "$f")
  cp "$f" "$REPO_ROOT/scripts/github/$name"
  chmod +x "$REPO_ROOT/scripts/github/$name"
  echo "  ADD  scripts/github/$name"
done

echo ""
echo "Done! Next steps:"
echo ""
echo "  1. Edit .github/actions/setup-dev-env/action.yml for your project's dependencies"
echo "  2. Edit .github/workflows/claude-ci-fix.yml and list your CI workflow names"
echo "  3. Add these repository secrets:"
echo "     - CLAUDE_CODE_OAUTH_TOKEN: Your Claude Code OAuth token"
echo "     - GH_PAT: A GitHub PAT with repo write access (for pushing from workflows)"
echo "  4. Commit and push the new files"
echo ""
echo "See https://github.com/hauxir/claude-code-actions for full documentation."
