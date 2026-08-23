import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';

const runtimeDir = process.env.CODEX_SUBTITLE_RUNTIME_DIR;
const model = process.env.SUBTITLE_WHISPER_MODEL || 'small';
const whisperCppVersion = '1.5.5';

if (!runtimeDir) {
  throw new Error('缺少 CODEX_SUBTITLE_RUNTIME_DIR。请通过 setup.sh 运行安装。');
}

const requireFromRuntime = createRequire(path.join(runtimeDir, 'package.json'));
const {
  downloadWhisperModel,
  installWhisperCpp,
} = requireFromRuntime('@remotion/install-whisper-cpp');

const whisperDir = path.join(runtimeDir, 'whisper.cpp');
const executableName = process.platform === 'win32' ? 'main.exe' : 'main';
const executablePath = path.join(whisperDir, executableName);
const modelPath = path.join(whisperDir, `ggml-${model}.bin`);

if (fs.existsSync(whisperDir) && !fs.existsSync(executablePath)) {
  console.log('发现未完成的 Whisper.cpp 安装，正在清理专用缓存后重试…');
  fs.rmSync(whisperDir, {recursive: true, force: true});
}

console.log(`正在准备 Whisper.cpp ${whisperCppVersion}…`);
await installWhisperCpp({
  to: whisperDir,
  version: whisperCppVersion,
  printOutput: true,
});

if (!fs.existsSync(modelPath) || fs.statSync(modelPath).size === 0) {
  console.log(`正在下载 Whisper ${model} 中文模型…`);
  await downloadWhisperModel({
    model,
    folder: whisperDir,
    printOutput: true,
  });
} else {
  console.log(`模型已存在：${modelPath}`);
}

const ffmpegPath = requireFromRuntime('ffmpeg-static');
for (const requiredPath of [executablePath, modelPath, ffmpegPath]) {
  if (!requiredPath || !fs.existsSync(requiredPath)) {
    throw new Error(`安装后自检失败，缺少：${requiredPath || 'ffmpeg-static 可执行文件'}`);
  }
}

console.log('依赖安装完成并通过自检。');
