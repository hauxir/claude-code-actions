#!/usr/bin/env bash
# Parses fix_summary.md and posts reactions on review issue comments:
#   - 👎 (-1)  for "Issue #N: Not fixed" lines
#   - 🎉 (hooray) for "Issue #N: Fixed" lines
#
# Required env vars: GH_TOKEN, REPO, ISSUE_MAP (JSON string), SUMMARY_FILE

set -euo pipefail

while IFS= read -r line; do
  if echo "$line" | grep -qiE "^Issue #[0-9]+: Not fixed"; then
    NUM=$(echo "$line" | grep -oE '[0-9]+' | head -1)
    COMMENT_ID=$(echo "$ISSUE_MAP" | jq -r --arg n "$NUM" '.[$n] // empty')
    if [ -n "$COMMENT_ID" ]; then
      gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
        --method POST -f content='-1' || true
    fi
  elif echo "$line" | grep -qiE "^Issue #[0-9]+: Fixed"; then
    NUM=$(echo "$line" | grep -oE '[0-9]+' | head -1)
    COMMENT_ID=$(echo "$ISSUE_MAP" | jq -r --arg n "$NUM" '.[$n] // empty')
    if [ -n "$COMMENT_ID" ]; then
      gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
        --method POST -f content='hooray' || true
    fi
  fi
done < "$SUMMARY_FILE"
