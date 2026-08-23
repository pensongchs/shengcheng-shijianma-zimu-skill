---
name: generate-timestamped-subtitles
description: Generate timestamped Chinese subtitles from local audio or video files and export both SRT and Remotion Caption JSON. Use when the user asks to transcribe speech with timecodes, create captions for editing software, or align Remotion text and animation to an audio track.
---

# 生成带时间码字幕

把本地音频或视频转成两份可直接使用的文件：

- `*_自动时间码字幕.srt`：用于剪映、Premiere、达芬奇等剪辑软件。
- `*_自动动效时间轴.json`：符合 Remotion `Caption` 结构，用于文字和动效对齐。

## 首次运行

本 Skill 不依赖开发者电脑上的项目或固定路径。运行环境安装在当前用户的缓存目录，重复使用时不会再次下载。

首次使用前：

1. 运行只读检查：

   ```bash
   bash "<本 Skill 目录>/scripts/doctor.sh"
   ```

2. 如果运行环境尚未安装，先告诉用户需要下载和安装的内容：
   - npm 运行依赖和独立 ffmpeg：约 80—150MB。
   - Whisper.cpp 源码与编译产物：约 100—300MB。
   - 默认中文 `small` 模型：约 466MB。
   - 总磁盘占用通常约 700MB—1GB，具体取决于平台。
3. 获得用户同意后运行：

   ```bash
   bash "<本 Skill 目录>/scripts/setup.sh" --install-system-deps
   ```

4. 如果 macOS 弹出“命令行开发者工具”安装窗口，提醒用户完成系统安装，然后再次运行同一条命令。
5. `setup.sh` 必须完成依赖安装和自检后，才能开始转写。不要仅凭文件夹存在就宣布安装成功。

## 生成字幕

1. 确认用户提供了本地音频或视频路径。没有明确成品名时沿用源文件名。
2. 运行：

   ```bash
   bash "<本 Skill 目录>/scripts/run.sh" "/完整路径/音频或视频.mp4" "可选成品名" "可选输出目录"
   ```

3. `run.sh` 会自动检查运行环境；环境不完整时会停止并提示先运行 `setup.sh`，不会输出假成品。
4. 等待转写完成，不要中途结束进程。默认中文 `small` 模型在本地运行，长音频需要一定时间。
5. 从命令输出中读取两份成品的绝对路径并交付给用户。
6. 提醒用户校对人名、地名、楼盘名和专业词；不要擅自改动时间码。

## 路径与依赖规则

- 脚本必须通过自身位置定位 Skill，禁止写死用户名、主目录或项目路径。
- macOS 运行环境默认位于 `~/Library/Caches/codex-generate-timestamped-subtitles/`。
- Linux 运行环境默认位于 `${XDG_CACHE_HOME:-~/.cache}/codex-generate-timestamped-subtitles/`。
- 默认输出到输入文件旁边的 `字幕文件/`；用户提供第三个参数时使用指定目录。
- 输入文件只读；临时 WAV 存放在系统临时目录，结束后自动清理。
- npm 依赖、ffmpeg、Whisper.cpp 和模型只在首次安装或缺失修复时下载。
- 需要安装系统级 Node.js、Git 或编译工具时必须先获得用户同意。`setup.sh --install-system-deps` 会优先使用现有包管理器补齐依赖，但不会静默安装 Homebrew、修改 shell 配置或保存管理员密码。
- 若 Codex 能提供内置 Node.js 路径，优先把该目录加入当前命令的 `PATH`，避免重复安装系统 Node.js。

## 验收

- `doctor.sh` 最终输出“运行环境检查通过”。
- 转写命令退出码为 0。
- `.srt` 和 `.json` 都已生成且非空。
- SRT 至少包含序号、`开始时间 --> 结束时间` 和字幕正文。
- JSON 可正常解析，且每条字幕包含 `text`、`startMs`、`endMs` 和 `timestampMs`。
- 输出中不存在开发者电脑的固定路径。
