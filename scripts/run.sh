#!/bin/bash
set -euo pipefail

PROJECT_ROOT="/Users/spmac/Documents/自媒体专用"
TOOL_DIR="$PROJECT_ROOT/outputs/字幕转时间码工具"
INPUT_PATH="${1:-}"
OUTPUT_NAME="${2:-}"

if [[ -z "$INPUT_PATH" ]]; then
  echo '用法：run.sh "/完整路径/音频或视频.mp4" "可选成品名"' >&2
  exit 1
fi

if [[ ! -f "$INPUT_PATH" ]]; then
  echo "找不到输入文件：$INPUT_PATH" >&2
  exit 1
fi

for command_name in node npm ffmpeg; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "缺少运行命令：$command_name" >&2
    exit 1
  fi
done

required_paths=(
  "$PROJECT_ROOT/package.json"
  "$PROJECT_ROOT/node_modules/@remotion/install-whisper-cpp"
  "$TOOL_DIR/transcribe.mjs"
  "$TOOL_DIR/runtime/whisper.cpp/main"
  "$TOOL_DIR/runtime/whisper.cpp/ggml-small.bin"
  "$TOOL_DIR/runtime/whisper.cpp/ggml-metal.metal"
  "$TOOL_DIR/runtime/whisper.cpp/ggml-common.h"
)

for required_path in "${required_paths[@]}"; do
  if [[ ! -e "$required_path" ]]; then
    echo "字幕工具依赖不完整，缺少：$required_path" >&2
    exit 1
  fi
done

cd "$PROJECT_ROOT"
if [[ -n "$OUTPUT_NAME" ]]; then
  npm run 字幕:转时间码 -- "$INPUT_PATH" "$OUTPUT_NAME"
else
  npm run 字幕:转时间码 -- "$INPUT_PATH"
fi
