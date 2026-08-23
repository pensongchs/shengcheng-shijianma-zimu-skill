#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

INSTALL_SYSTEM_DEPS=false
if [[ "${1:-}" == "--install-system-deps" ]]; then
  INSTALL_SYSTEM_DEPS=true
fi

install_node_prerequisite() {
  if resolve_node_tools >/dev/null 2>&1; then
    return
  fi

  if [[ "$INSTALL_SYSTEM_DEPS" != true ]]; then
    resolve_node_tools
    exit 2
  fi

  case "$(uname -s)" in
    Darwin)
      if command -v brew >/dev/null 2>&1; then
        echo "正在通过 Homebrew 安装 Node.js…"
        brew install node
      else
        echo "未找到 Node.js 和 Homebrew。请让 Codex 优先使用应用自带的 Node.js 路径；如果仍不可用，再从 nodejs.org 安装 Node.js LTS。" >&2
        exit 2
      fi
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y nodejs npm
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y nodejs npm
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm nodejs npm
      else
        echo "无法识别当前 Linux 包管理器，请安装 Node.js 20 LTS 或更高版本后重试。" >&2
        exit 2
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      if command -v winget.exe >/dev/null 2>&1; then
        winget.exe install --id OpenJS.NodeJS.LTS --exact --accept-source-agreements --accept-package-agreements
      else
        echo "未找到 Node.js。请从 nodejs.org 安装 Node.js LTS 后重新打开 Codex。" >&2
        exit 2
      fi
      ;;
  esac

  hash -r
  resolve_node_tools
}

install_macos_prerequisites() {
  local missing=()
  git --version >/dev/null 2>&1 || missing+=(git)
  make --version >/dev/null 2>&1 || missing+=(make)

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return
  fi

  if [[ "$INSTALL_SYSTEM_DEPS" != true ]]; then
    echo "缺少 macOS 编译工具：${missing[*]}" >&2
    echo "获得用户同意后，用 --install-system-deps 重新运行。" >&2
    exit 2
  fi

  echo "正在启动 Apple 命令行开发者工具安装…"
  xcode-select --install >/dev/null 2>&1 || true
  echo "请在系统弹窗中完成安装，然后再次运行本脚本。" >&2
  exit 2
}

install_linux_prerequisites() {
  local missing=()
  git --version >/dev/null 2>&1 || missing+=(git)
  make --version >/dev/null 2>&1 || missing+=(make)
  command -v c++ >/dev/null 2>&1 || missing+=(c++)

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return
  fi

  if [[ "$INSTALL_SYSTEM_DEPS" != true ]]; then
    echo "缺少 Linux 编译工具：${missing[*]}" >&2
    echo "获得用户同意后，用 --install-system-deps 重新运行。" >&2
    exit 2
  fi

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y git build-essential
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y git gcc-c++ make
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm git base-devel
  else
    echo "无法识别当前 Linux 包管理器，请安装 Git、Make 和 C++ 编译器后重试。" >&2
    exit 2
  fi
}

install_node_prerequisite

case "$(uname -s)" in
  Darwin) install_macos_prerequisites ;;
  Linux) install_linux_prerequisites ;;
  MINGW*|MSYS*|CYGWIN*) ;;
  *) echo "暂不支持的平台：$(uname -s)" >&2; exit 2 ;;
esac

mkdir -p "$RUNTIME_DIR"
cp "$SCRIPT_DIR/runtime-package.json" "$RUNTIME_DIR/package.json"

echo "正在安装本地运行依赖和独立 ffmpeg…"
"$NPM_BIN" install --prefix "$RUNTIME_DIR" --omit=dev --no-audit --no-fund

export CODEX_SUBTITLE_RUNTIME_DIR="$RUNTIME_DIR"
export SUBTITLE_WHISPER_MODEL="$MODEL_NAME"
"$NODE_BIN" "$SCRIPT_DIR/setup.mjs"

bash "$SCRIPT_DIR/doctor.sh"
