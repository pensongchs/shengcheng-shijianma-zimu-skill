#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${CODEX_NODE_BIN:-node}" "$SCRIPT_DIR/run.mjs" "$@"
