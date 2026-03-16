#!/usr/bin/env bash
# Fetches failed CI job logs and writes them to $GITHUB_OUTPUT.
#
# Required env vars:
#   GH_TOKEN, RUN_ID, REPO

set -euo pipefail

LOGS=$(gh run view "$RUN_ID" --repo "$REPO" --log-failed 2>&1 | tail -c 50000)
{ echo "content<<LOGS_EOF"; printf '%s\n' "$LOGS"; echo "LOGS_EOF"; } >> "$GITHUB_OUTPUT"
