#!/usr/bin/env bash
# Posts a file as a PR comment, with an optional HTML marker prepended.
#
# Required env vars:
#   GH_TOKEN, PR_NUMBER, REPO, COMMENT_FILE
# Optional env vars:
#   MARKER  (HTML comment marker to prepend, e.g. "<!-- claude-code-review -->")

set -euo pipefail

[ -f "$COMMENT_FILE" ] || { echo "::error::Claude did not write a comment file at $COMMENT_FILE"; exit 1; }

BODY="${MARKER:+$MARKER$'\n'}$(cat "$COMMENT_FILE")"

gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$BODY"
