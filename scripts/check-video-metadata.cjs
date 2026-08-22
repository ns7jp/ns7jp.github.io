const fs = require('node:fs');
const path = require('node:path');

const file = path.resolve(__dirname, '..', 'media', 'server-monitor-evidence-replay.mp4');
const data = fs.readFileSync(file);

if (data.toString('ascii', 4, 8) !== 'ftyp') throw new Error('Not an ISO BMFF/MP4 file');
if (data.length >= 10 * 1024 * 1024) throw new Error(`Video is too large: ${data.length} bytes`);

const mvhdType = data.indexOf(Buffer.from('mvhd'));
if (mvhdType < 0) throw new Error('mvhd box was not found');
const version = data.readUInt8(mvhdType + 4);
let timescale;
let durationTicks;
if (version === 0) {
  timescale = data.readUInt32BE(mvhdType + 16);
  durationTicks = data.readUInt32BE(mvhdType + 20);
} else if (version === 1) {
  timescale = data.readUInt32BE(mvhdType + 24);
  durationTicks = Number(data.readBigUInt64BE(mvhdType + 28));
} else {
  throw new Error(`Unsupported mvhd version: ${version}`);
}

// MediaRecorder writes a fragmented MP4 whose mvhd duration is zero. In that
// case, use the media timescale and the final tfdt + trun sample durations.
if (!timescale || !durationTicks) {
  const mdhdType = data.indexOf(Buffer.from('mdhd'));
  if (mdhdType < 0) throw new Error('mdhd box was not found');
  const mdhdVersion = data.readUInt8(mdhdType + 4);
  if (mdhdVersion === 0) timescale = data.readUInt32BE(mdhdType + 16);
  else if (mdhdVersion === 1) timescale = data.readUInt32BE(mdhdType + 24);
  else throw new Error(`Unsupported mdhd version: ${mdhdVersion}`);

  durationTicks = 0;
  let searchFrom = 0;
  while (true) {
    const trunType = data.indexOf(Buffer.from('trun'), searchFrom);
    if (trunType < 0) break;
    const flags = (data[trunType + 5] << 16) | (data[trunType + 6] << 8) | data[trunType + 7];
    const sampleCount = data.readUInt32BE(trunType + 8);
    let cursor = trunType + 12;
    if (flags & 0x000001) cursor += 4; // data offset
    if (flags & 0x000004) cursor += 4; // first-sample flags
    if (!(flags & 0x000100)) throw new Error('trun has no per-sample duration');

    let fragmentDuration = 0;
    for (let index = 0; index < sampleCount; index += 1) {
      fragmentDuration += data.readUInt32BE(cursor);
      cursor += 4;
      if (flags & 0x000200) cursor += 4; // sample size
      if (flags & 0x000400) cursor += 4; // sample flags
      if (flags & 0x000800) cursor += 4; // composition time offset
    }

    const tfdtType = data.lastIndexOf(Buffer.from('tfdt'), trunType);
    if (tfdtType < 0) throw new Error('tfdt box was not found before trun');
    const tfdtVersion = data.readUInt8(tfdtType + 4);
    const baseDecodeTime = tfdtVersion === 1
      ? Number(data.readBigUInt64BE(tfdtType + 8))
      : data.readUInt32BE(tfdtType + 8);
    durationTicks = Math.max(durationTicks, baseDecodeTime + fragmentDuration);
    searchFrom = trunType + 4;
  }
}

const duration = durationTicks / timescale;

const tkhdType = data.indexOf(Buffer.from('tkhd'));
if (tkhdType < 4) throw new Error('tkhd box was not found');
const tkhdStart = tkhdType - 4;
const tkhdSize = data.readUInt32BE(tkhdStart);
const tkhdEnd = tkhdStart + tkhdSize;
const width = data.readUInt32BE(tkhdEnd - 8) / 65536;
const height = data.readUInt32BE(tkhdEnd - 4) / 65536;

if (duration < 130 || duration > 140) throw new Error(`Unexpected duration: ${duration}s`);
if (width !== 1280 || height !== 720) throw new Error(`Unexpected dimensions: ${width}x${height}`);
if (!data.includes(Buffer.from('avc1'))) throw new Error('Expected an H.264/AVC video track');

console.log(JSON.stringify({
  file: path.relative(path.resolve(__dirname, '..'), file),
  duration_seconds: Number(duration.toFixed(3)),
  width,
  height,
  codec: 'H.264/AVC',
  size_bytes: data.length,
}, null, 2));
