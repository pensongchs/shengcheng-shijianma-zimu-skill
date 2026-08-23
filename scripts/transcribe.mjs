import {spawnSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createRequire} from 'node:module';

const runtimeDir = process.env.CODEX_SUBTITLE_RUNTIME_DIR;
const inputArg = process.argv[2];
const requestedName = process.argv[3];
const model = process.env.SUBTITLE_WHISPER_MODEL || 'small';
const whisperCppVersion = '1.5.5';

if (!runtimeDir || !inputArg) {
  throw new Error('缺少运行环境或输入文件。请通过 run.sh 执行。');
}

const inputPath = path.resolve(inputArg);
if (!fs.existsSync(inputPath)) {
  throw new Error(`找不到输入文件：${inputPath}`);
}

const requireFromRuntime = createRequire(path.join(runtimeDir, 'package.json'));
const {transcribe, toCaptions} = requireFromRuntime('@remotion/install-whisper-cpp');
const ffmpegPath = requireFromRuntime('ffmpeg-static');
const whisperDir = path.join(runtimeDir, 'whisper.cpp');
const outputDir = process.env.CODEX_SUBTITLE_OUTPUT_DIR
  ? path.resolve(process.env.CODEX_SUBTITLE_OUTPUT_DIR)
  : path.join(path.dirname(inputPath), '字幕文件');

const sourceName = path.basename(inputPath, path.extname(inputPath));
const safeName = (requestedName || sourceName)
  .replace(/[\\/:*?"<>|]/g, '_')
  .replace(/\s+/g, '_')
  .replace(/^_+|_+$/g, '') || '未命名音频';

const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'codex-subtitle-timecode-'));
const wavPath = path.join(tempDir, 'audio-16k.wav');
const previousCwd = process.cwd();

const formatSrtTime = (milliseconds) => {
  const total = Math.max(0, Math.round(milliseconds));
  const hours = Math.floor(total / 3_600_000);
  const minutes = Math.floor((total % 3_600_000) / 60_000);
  const seconds = Math.floor((total % 60_000) / 1000);
  const ms = total % 1000;
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')},${String(ms).padStart(3, '0')}`;
};

const normalizeText = (text) => text
  .trim()
  .replaceAll(',', '，')
  .replaceAll('?', '？')
  .replaceAll('!', '！')
  .replaceAll(':', '：');

try {
  fs.mkdirSync(outputDir, {recursive: true});
  console.log('正在使用独立 ffmpeg 提取 16kHz 单声道音轨…');
  const ffmpegResult = spawnSync(ffmpegPath, [
    '-v', 'error',
    '-i', inputPath,
    '-vn',
    '-ac', '1',
    '-ar', '16000',
    '-c:a', 'pcm_s16le',
    wavPath,
    '-y',
  ], {stdio: 'inherit'});

  if (ffmpegResult.error || ffmpegResult.status !== 0) {
    throw ffmpegResult.error || new Error(`ffmpeg 转换失败，退出码：${ffmpegResult.status}`);
  }

  process.chdir(tempDir);
  console.log(`正在本地转写中文并生成时间码（${model} 模型，CPU 兼容模式）…`);
  const whisperCppOutput = await transcribe({
    model,
    whisperPath: whisperDir,
    whisperCppVersion,
    inputPath: wavPath,
    tokenLevelTimestamps: true,
    language: 'zh',
    additionalArgs: ['--split-on-word', '--no-gpu'],
    printOutput: true,
  });

  const {captions: rawCaptions} = toCaptions({whisperCppOutput});
  const captions = rawCaptions
    .map((caption) => ({...caption, text: normalizeText(caption.text)}))
    .filter((caption) => caption.text && caption.endMs > caption.startMs);

  if (captions.length === 0) {
    throw new Error('转写结束但没有得到有效字幕。请确认音频中包含清晰人声。');
  }

  const srt = `${captions.map((caption, index) => [
    String(index + 1),
    `${formatSrtTime(caption.startMs)} --> ${formatSrtTime(caption.endMs)}`,
    caption.text,
  ].join('\n')).join('\n\n')}\n`;

  const srtPath = path.join(outputDir, `${safeName}_自动时间码字幕.srt`);
  const jsonPath = path.join(outputDir, `${safeName}_自动动效时间轴.json`);
  fs.writeFileSync(srtPath, srt, 'utf8');
  fs.writeFileSync(jsonPath, `${JSON.stringify(captions, null, 2)}\n`, 'utf8');

  const parsed = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  if (!fs.statSync(srtPath).size || !Array.isArray(parsed) || parsed.length === 0) {
    throw new Error('输出文件自检失败。');
  }

  console.log(`完成，共 ${captions.length} 条字幕：`);
  console.log(srtPath);
  console.log(jsonPath);
  console.log('提示：正式使用前请校对人名、地名、楼盘名和专业词。');
} finally {
  process.chdir(previousCwd);
  fs.rmSync(tempDir, {recursive: true, force: true});
}
