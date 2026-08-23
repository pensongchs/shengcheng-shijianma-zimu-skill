#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_runtime_dir() {
  if [[ -n "${CODEX_SUBTITLE_RUNTIME_DIR:-}" ]]; then
    printf '%s\n' "$CODEX_SUBTITLE_RUNTIME_DIR"
    return
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    printf '%s\n' "$HOME/Library/Caches/codex-generate-timestamped-subtitles"
  else
    printf '%s\n' "${XDG_CACHE_HOME:-$HOME/.cache}/codex-generate-timestamped-subtitles"
  fi
}

RUNTIME_DIR="$(get_runtime_dir)"
WHISPER_DIR="$RUNTIME_DIR/whisper.cpp"
MODEL_NAME="${SUBTITLE_WHISPER_MODEL:-small}"
MODEL_PATH="$WHISPER_DIR/ggml-$MODEL_NAME.bin"

resolve_node_tools() {
  if [[ -n "${CODEX_NODE_BIN:-}" && -x "$CODEX_NODE_BIN" ]]; then
    NODE_BIN="$CODEX_NODE_BIN"
  elif command -v node >/dev/null 2>&1; then
    NODE_BIN="$(command -v node)"
  elif [[ -x /opt/homebrew/bin/node ]]; then
    NODE_BIN=/opt/homebrew/bin/node
  elif [[ -x /usr/local/bin/node ]]; then
    NODE_BIN=/usr/local/bin/node
  else
    NODE_BIN=""
  fi

  if [[ -n "${CODEX_NPM_BIN:-}" && -x "$CODEX_NPM_BIN" ]]; then
    NPM_BIN="$CODEX_NPM_BIN"
  elif command -v npm >/dev/null 2>&1; then
    NPM_BIN="$(command -v npm)"
  elif [[ -x /opt/homebrew/bin/npm ]]; then
    NPM_BIN=/opt/homebrew/bin/npm
  elif [[ -x /usr/local/bin/npm ]]; then
    NPM_BIN=/usr/local/bin/npm
  else
    NPM_BIN=""
  fi

  if [[ -z "$NODE_BIN" || -z "$NPM_BIN" ]]; then
    echo "缺少 Node.js 或 npm。请先让 Codex 查找内置 Node.js；没有可用版本时再安装 Node.js 20 或更高版本。" >&2
    return 1
  fi

  local node_major
  node_major="$($NODE_BIN -p 'Number(process.versions.node.split(".")[0])')"
  if [[ "$node_major" -lt 18 ]]; then
    echo "Node.js 版本过低：$($NODE_BIN --version)。需要 Node.js 18 或更高版本。" >&2
    return 1
  fi

  export PATH="$(dirname "$NODE_BIN"):$(dirname "$NPM_BIN"):$PATH"
}

get_whisper_executable() {
  if [[ "$(uname -s)" == "MINGW"* || "$(uname -s)" == "MSYS"* || "$(uname -s)" == "CYGWIN"* ]]; then
    printf '%s\n' "$WHISPER_DIR/main.exe"
  else
    printf '%s\n' "$WHISPER_DIR/main"
  fi
}

runtime_is_ready() {
  local whisper_executable
  whisper_executable="$(get_whisper_executable)"
  [[ -f "$RUNTIME_DIR/package.json" ]] || return 1
  [[ -d "$RUNTIME_DIR/node_modules/@remotion/install-whisper-cpp" ]] || return 1
  [[ -f "$RUNTIME_DIR/node_modules/ffmpeg-static/index.js" ]] || return 1
  [[ -x "$whisper_executable" || -f "$whisper_executable" ]] || return 1
  [[ -s "$MODEL_PATH" ]] || return 1
  return 0
}
