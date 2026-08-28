---
name: generate-timestamped-subtitles
description: Generate timestamped Chinese subtitles from local audio or video files and export both SRT and Remotion Caption JSON. Use when the user asks to transcribe speech with timecodes, create captions for editing software, or align Remotion text and animation to an audio track.
---

# 生成带时间码字幕

把本地音频或视频转成两份可直接使用的文件：

- `*_自动时间码字幕.srt`：用于剪映、Premiere、达芬奇等剪辑软件。
- `*_自动动效时间轴.json`：符合 Remotion `Caption` 结构，用于文字和动效对齐。

## 首次运行

运行环境安装在当前电脑用户的系统缓存目录，并由脚本根据 macOS、Windows 或 Linux 自动定位。重复使用时不会再次下载完整模型。

首次使用前：

1. 运行只读检查：

   ```text
   node "<本 Skill 目录>/scripts/doctor.mjs"
   ```

2. 先用只读方式检查本机是否已有 `ggml-*.bin` 模型。优先检查用户明确提供的位置、当前项目和当前用户常用缓存目录；不要为了搜索模型修改、复制或移动任何文件。
3. 如果找到已有模型，复用其完整路径：

   ```text
   node "<本 Skill 目录>/scripts/setup.mjs" --model-path "<本机已有 ggml-*.bin 的完整路径>" --install-system-deps
   ```

4. 如果未找到模型，先告诉用户需要下载和安装的内容：
   - npm 运行依赖和独立 ffmpeg：约 80—150MB。
   - Whisper.cpp 源码与编译产物：约 100—300MB。
   - 默认中文 `small` 模型：约 466MB。
   - 总磁盘占用通常约 700MB—1GB，具体取决于平台。
5. 只有用户明确同意下载模型后，才能运行：

   ```text
   node "<本 Skill 目录>/scripts/setup.mjs" --download-model --install-system-deps
   ```

6. 没有 `--download-model` 时，脚本发现模型缺失会直接停止；不得擅自补上该开关。
7. macOS/Linux 使用本地编译的 Whisper.cpp；Windows 自动下载官方预编译程序。macOS 如果弹出“命令行开发者工具”安装窗口，提醒用户完成系统安装，然后再次运行同一条命令。
8. `setup.mjs` 必须完成 npm 依赖、独立 ffmpeg、Whisper.cpp、已有模型接入和自检后，才能开始转写。不要仅凭文件夹存在就宣布安装成功。

## 生成字幕

1. 确认用户提供了本地音频或视频路径。没有明确成品名时沿用源文件名。
2. 运行：

   ```text
   node "<本 Skill 目录>/scripts/run.mjs" "<当前电脑上的音频或视频完整路径>" "可选成品名" "可选输出目录"
   ```

3. `run.mjs` 会自动检查运行环境；环境不完整时会停止并提示先运行 `setup.mjs`，不会输出假成品。
4. 等待转写完成，不要中途结束进程。默认中文 `small` 模型在本地运行，长音频需要一定时间。
5. 从命令输出中读取两份成品的绝对路径并交付给用户。
6. 提醒用户校对人名、地名、楼盘名和专业词；不要擅自改动时间码。

## 路径与依赖规则

- 脚本必须通过自身位置定位 Skill，禁止写死用户名、主目录或项目路径。
- macOS 默认使用当前用户的 `Library/Caches/codex-generate-timestamped-subtitles/`。
- Windows 默认使用当前用户的 `LOCALAPPDATA/codex-generate-timestamped-subtitles/`。
- Linux 默认使用当前用户的 `XDG_CACHE_HOME` 或 `.cache/codex-generate-timestamped-subtitles/`。
- 默认输出到输入文件旁边的 `字幕文件/`；用户提供第三个参数时使用指定目录。
- 输入文件只读；临时 WAV 存放在系统临时目录，结束后自动清理。
- 已有模型只以原路径读取，不复制、不移动、不改名、不重复下载。
- 模型缺失时默认停止；只有用户明确授权后才能通过 `--download-model` 下载。
- npm 使用本 Skill 运行环境中的专用缓存目录，不依赖当前用户的全局 npm 缓存权限。
- 需要安装系统级 Node.js、Git 或编译工具时必须先获得用户同意。`setup.mjs --install-system-deps` 只补齐当前平台确实需要的依赖，不修改 shell 配置，也不保存管理员密码。
- 运行入口统一为 Node.js；Windows 不需要 Git Bash。若 Codex 能提供内置 Node.js，优先直接使用该运行时，避免重复安装系统 Node.js。

## 验收

- `doctor.mjs` 最终输出“运行环境检查通过”，并显示当前实际使用的模型路径。
- 转写命令退出码为 0。
- `.srt` 和 `.json` 都已生成且非空。
- SRT 至少包含序号、`开始时间 --> 结束时间` 和字幕正文。
- JSON 可正常解析，且每条字幕包含 `text`、`startMs`、`endMs` 和 `timestampMs`。
- 输出路径只来自当前电脑的输入文件、用户指定目录或当前用户缓存目录。
