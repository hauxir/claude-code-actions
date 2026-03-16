#!/usr/bin/env bash
# Posts each issue file in $ISSUES_DIR as a separate PR comment.
#
# Required env vars: GH_TOKEN, PR_NUMBER, REPO
# Optional: ISSUES_DIR (default: $GITHUB_WORKSPACE/review_issues)

set -euo pipefail

ISSUES_DIR="${ISSUES_DIR:-$GITHUB_WORKSPACE/review_issues}"
MARKER="<!-- claude-review-issue -->"

if [ -f "$ISSUES_DIR/no_issues.md" ] || ! ls "$ISSUES_DIR"/issue_*.md 2>/dev/null | grep -q .; then
  gh pr comment "$PR_NUMBER" --repo "$REPO" --body "No issues found."
  exit 0
fi

for issue_file in "$ISSUES_DIR"/issue_*.md; do
  [ -f "$issue_file" ] || continue
  BODY="$MARKER"$'\n'"$(cat "$issue_file")"
  gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$BODY"
done
