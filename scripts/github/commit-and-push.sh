#!/usr/bin/env bash
# Commits all staged changes and pushes. No-ops if there are no changes.
#
# Optional env vars:
#   GIT_USER_NAME   (defaults to "github-actions[bot]")
#   GIT_USER_EMAIL  (defaults to "41898282+github-actions[bot]@users.noreply.github.com")

set -euo pipefail

git config user.name "${GIT_USER_NAME:-github-actions[bot]}"
git config user.email "${GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"

if [ -n "${GITHUB_TOKEN:-}" ]; then
  git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
fi

git add -A

if ! git diff --cached --quiet; then
  [ -f commit_message.txt ] || { echo "::error::Claude did not write a commit message to commit_message.txt"; exit 1; }
  git commit --no-verify -m "$(cat commit_message.txt)"

  # Retry push with rebase in case the remote branch was updated while we
  # were running (e.g. concurrent review/fix cycles or manual pushes).
  for attempt in 1 2 3; do
    if git push 2>/dev/null; then
      break
    fi
    echo "Push failed (attempt $attempt/3), rebasing on remote and retrying..."
    git pull --rebase
  done

  [ -n "${GITHUB_OUTPUT:-}" ] && echo "pushed=true" >> "$GITHUB_OUTPUT"
fi
