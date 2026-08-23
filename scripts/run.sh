#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

INPUT_PATH="${1:-}"
OUTPUT_NAME="${2:-}"
OUTPUT_DIR="${3:-}"

if [[ -z "$INPUT_PATH" ]]; then
  echo '用法：run.sh "/完整路径/音频或视频.mp4" "可选成品名" "可选输出目录"' >&2
  exit 1
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "找不到输入文件：$INPUT_PATH" >&2
  exit 1
fi

resolve_node_tools

if ! runtime_is_ready; then
  echo "字幕运行环境尚未安装或不完整。" >&2
  echo "请先运行：bash \"$SCRIPT_DIR/setup.sh\" --install-system-deps" >&2
  exit 2
fi

export CODEX_SUBTITLE_RUNTIME_DIR="$RUNTIME_DIR"
export CODEX_SUBTITLE_OUTPUT_DIR="$OUTPUT_DIR"
"$NODE_BIN" "$SCRIPT_DIR/transcribe.mjs" "$INPUT_PATH" "$OUTPUT_NAME"
