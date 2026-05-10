#!/usr/bin/env bash
# Wrapper for playwright-cli to handle NODE_OPTIONS conflict
# Usage: scripts/playwright-cli.sh <command> [args...]
#
# All UI verification in this project MUST use this wrapper.
# Do NOT call playwright-cli directly or manually set NODE_OPTIONS=.

set -euo pipefail

NODE_BIN_DIR="/Users/chenck/.workbuddy/binaries/node/versions/22.12.0/bin"

if [[ ! -d "$NODE_BIN_DIR" ]]; then
  echo "ERROR: managed node not found at $NODE_BIN_DIR" >&2
  echo "Check docs/dev-env-notes.md for setup instructions" >&2
  exit 1
fi

NODE_OPTIONS="" PATH="$NODE_BIN_DIR:$PATH" playwright-cli "$@"
