import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {modelPath, readRuntimeStatus, runCommand, runtimeDir} from './runtime.mjs';

const [inputArg, outputName = '', outputDir = ''] = process.argv.slice(2);
if (!inputArg) {
  console.error('用法：node scripts/run.mjs "输入音频或视频路径" "可选成品名" "可选输出目录"');
  process.exit(1);
}

const inputPath = path.resolve(inputArg);
if (!fs.existsSync(inputPath) || !fs.statSync(inputPath).isFile()) {
  console.error(`找不到输入文件：${inputPath}`);
  process.exit(1);
}

const status = readRuntimeStatus();
if (!status.ready) {
  console.error(`字幕运行环境尚未完整安装：${status.missing.join('、')}`);
  console.error(`请先运行：node "${path.join(path.dirname(fileURLToPath(import.meta.url)), 'setup.mjs')}" --install-system-deps`);
  process.exit(2);
}

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
runCommand(process.execPath, [path.join(scriptDir, 'transcribe.mjs'), inputPath, outputName], {
  env: {
    ...process.env,
    CODEX_SUBTITLE_RUNTIME_DIR: runtimeDir,
    CODEX_SUBTITLE_MODEL_PATH: modelPath,
    CODEX_SUBTITLE_OUTPUT_DIR: outputDir,
  },
});
