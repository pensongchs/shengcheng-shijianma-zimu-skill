---
name: generate-timestamped-subtitles
description: Generate timestamped Chinese subtitles from local audio or video files by reusing the installed Whisper.cpp tool. Use when the user asks to transcribe speech with timecodes, create or export SRT captions, make subtitles for CapCut/Premiere/DaVinci Resolve, generate a Remotion Caption JSON timeline, or align video text and animation to spoken audio. Supports common media files readable by ffmpeg and outputs both .srt and .json files.
---

# 生成带时间码字幕

把本地音频或视频转成两份可直接使用的文件：

- `*_自动时间码字幕.srt`：用于剪映、Premiere、达芬奇等剪辑软件。
- `*_自动动效时间轴.json`：符合 Remotion `Caption` 结构，用于文字和动效对齐。

## 执行流程

1. 确认用户提供了本地音频或视频路径。没有明确成品名时沿用源文件名。
2. 运行本 Skill 的脚本：

   ```bash
   bash /Users/spmac/.codex/skills/generate-timestamped-subtitles/scripts/run.sh "/完整路径/音频或视频.mp4" "可选成品名"
   ```

3. 等待转写完成，不要中途结束进程。中文 `small` 模型在本地运行，长音频需要一定时间。
4. 从命令输出中读取两份成品的绝对路径，并把路径直接交付给用户。
5. 提醒用户校对人名、地名、楼盘名和专业词；不要擅自改动时间码。

## 运行约束

- 复用 `/Users/spmac/Documents/自媒体专用/outputs/字幕转时间码工具/`，不要复制约 467MB 的模型或另装一套 Whisper。
- 默认输出到 `/Users/spmac/Documents/自媒体专用/outputs/字幕文件/`。
- 输入文件只读；临时 WAV 和中间文件由原工具在系统临时目录创建并自动清理。
- 运行前由脚本检查源文件、Node、npm、ffmpeg、模型、Whisper 主程序和项目依赖。
- 如果校验失败，报告缺少的具体依赖，不要自动下载模型、安装软件或修改系统配置。
- 自动字幕用于建立时间轴；涉及专有名词时必须人工复核文本。

## 验收

- 命令退出码为 0。
- `.srt` 和 `.json` 都已生成且非空。
- SRT 至少包含序号、`开始时间 --> 结束时间` 和字幕正文。
- JSON 可正常解析，且每条字幕包含文本与毫秒级起止时间。
