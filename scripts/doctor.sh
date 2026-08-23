#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "系统：$(uname -s) $(uname -m)"
echo "Skill 目录：$(cd "$SCRIPT_DIR/.." && pwd)"
echo "运行环境：$RUNTIME_DIR"
echo "默认模型：$MODEL_NAME"

resolve_node_tools
echo "Node.js：$($NODE_BIN --version) ($NODE_BIN)"
echo "npm：$($NPM_BIN --version) ($NPM_BIN)"

if runtime_is_ready; then
  echo "运行环境检查通过"
  exit 0
fi

echo "运行环境尚未完整安装。" >&2
[[ -d "$RUNTIME_DIR/node_modules/@remotion/install-whisper-cpp" ]] || echo "缺少：Remotion Whisper npm 依赖" >&2
[[ -f "$RUNTIME_DIR/node_modules/ffmpeg-static/index.js" ]] || echo "缺少：独立 ffmpeg" >&2
[[ -f "$(get_whisper_executable)" ]] || echo "缺少：Whisper.cpp 主程序" >&2
[[ -s "$MODEL_PATH" ]] || echo "缺少：$MODEL_NAME 中文模型" >&2
exit 2
