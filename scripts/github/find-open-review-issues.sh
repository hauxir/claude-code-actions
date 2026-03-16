#!/usr/bin/env bash
# Finds non-thumbsdown'd <!-- claude-review-issue --> comments from the current
# review round and outputs numbered issues + an issue_map JSON for the fix step.
#
# Required env vars: GH_TOKEN, REPO, EVENT_NAME
# For workflow_dispatch/repository_dispatch: INPUT_PR_NUMBER
# For workflow_run: WORKFLOW_RUN_HEAD_SHA

set -euo pipefail

if [ "$EVENT_NAME" = "workflow_dispatch" ] || [ "$EVENT_NAME" = "repository_dispatch" ]; then
  PR="$INPUT_PR_NUMBER"
else
  PR=$(gh pr list --repo "$REPO" --state open --json number,headRefOid \
    --jq ".[] | select(.headRefOid == \"$WORKFLOW_RUN_HEAD_SHA\") | .number" | head -1)
  [ -z "$PR" ] && { echo "skip=true" >> "$GITHUB_OUTPUT"; exit 0; }
fi

BRANCH=$(gh pr view "$PR" --repo "$REPO" --json headRefName -q '.headRefName')

if [[ "$BRANCH" != claude/* ]] && [ "$EVENT_NAME" != "workflow_dispatch" ] && [ "$EVENT_NAME" != "repository_dispatch" ]; then
  echo "skip=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

MAX_ITERATIONS=5
FIX_COUNT=$(gh api "repos/$REPO/issues/$PR/comments" \
  --jq '[.[] | select(.body | contains("<!-- claude-fix-summary -->"))] | length')
if [ "$FIX_COUNT" -ge "$MAX_ITERATIONS" ] && [ "$EVENT_NAME" != "workflow_dispatch" ] && [ "$EVENT_NAME" != "repository_dispatch" ]; then
  echo "skip=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

# Timestamp of last fix summary (or epoch if none)
LAST_FIX_TIME=$(gh api "repos/$REPO/issues/$PR/comments" \
  --jq '[.[] | select(.body | contains("<!-- claude-fix-summary -->"))] | last | .created_at // "1970-01-01T00:00:00Z"')

# All review-issue comments newer than last fix summary
ISSUE_COMMENTS=$(gh api "repos/$REPO/issues/$PR/comments" \
  | jq --arg since "$LAST_FIX_TIME" \
  '[.[] | select((.body | contains("<!-- claude-review-issue -->")) and (.created_at > $since)) | {id: (.id | tostring), body}]')

ISSUE_NUM=0
ISSUE_MAP="{}"
ISSUES_TEXT=""

while IFS= read -r row; do
  COMMENT_ID=$(echo "$row" | jq -r '.id')
  COMMENT_BODY=$(echo "$row" | jq -r '.body')

  HAS_THUMBSDOWN=$(gh api "repos/$REPO/issues/comments/$COMMENT_ID/reactions" \
    --jq 'any(.[]; .content == "-1")')

  if [ "$HAS_THUMBSDOWN" != "true" ]; then
    ISSUE_NUM=$((ISSUE_NUM + 1))
    ISSUES_TEXT="${ISSUES_TEXT}Issue #${ISSUE_NUM}:\n${COMMENT_BODY}\n\n"
    ISSUE_MAP=$(echo "$ISSUE_MAP" | jq -c --arg n "$ISSUE_NUM" --arg id "$COMMENT_ID" '. + {($n): $id}')
  fi
done < <(echo "$ISSUE_COMMENTS" | jq -c '.[]')

if [ "$ISSUE_NUM" -eq 0 ]; then
  echo "skip=true" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "pr=$PR" >> "$GITHUB_OUTPUT"
echo "branch=$BRANCH" >> "$GITHUB_OUTPUT"
echo "skip=false" >> "$GITHUB_OUTPUT"
echo "issue_map=$ISSUE_MAP" >> "$GITHUB_OUTPUT"
{ echo "issues<<ISSUES_EOF"; printf '%b\n' "$ISSUES_TEXT"; echo "ISSUES_EOF"; } >> "$GITHUB_OUTPUT"
