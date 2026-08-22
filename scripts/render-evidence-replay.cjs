const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const OUTPUT = path.join(ROOT, 'media', 'server-monitor-evidence-replay.mp4');
const POSTER = path.join(ROOT, 'image', 'server-monitor-evidence-replay-poster.png');
const NOTICE = 'この映像は実操作の連続録画ではありません。2026年8月18日・19日に保存した実測スクリーンショットとD-1復旧ログを、閲覧用に時系列で再構成したリプレイです。';

const imageFiles = {
  compose: path.join(ROOT, 'media', 'demo-sources', 'compose-ps_aab2fcc_20260818.png'),
  grafana: path.join(ROOT, 'media', 'demo-sources', 'grafana-server-monitor_aab2fcc_20260818.png'),
  slo: path.join(ROOT, 'media', 'demo-sources', 'grafana-slo_aab2fcc_20260818.png'),
};

for (const required of Object.values(imageFiles)) {
  if (!fs.existsSync(required)) throw new Error(`Missing source image: ${required}`);
}
fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
fs.mkdirSync(path.dirname(POSTER), { recursive: true });

const assets = Object.fromEntries(
  Object.entries(imageFiles).map(([name, file]) => [
    name,
    `data:image/png;base64,${fs.readFileSync(file).toString('base64')}`,
  ]),
);

const browserCandidates = [
  process.env.CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
].filter(Boolean);
const executablePath = browserCandidates.find(fs.existsSync);
if (!executablePath) throw new Error('Chrome or Edge was not found. Set CHROME_PATH.');

(async () => {
  const browser = await chromium.launch({
    headless: true,
    executablePath,
    args: ['--autoplay-policy=no-user-gesture-required'],
  });
  const context = await browser.newContext({ acceptDownloads: true });
  const page = await context.newPage();
  page.on('console', (message) => console.log(message.text()));
  await page.setViewportSize({ width: 1280, height: 720 });
  await page.setContent('<canvas id="c" width="1280" height="720"></canvas>');

  await page.evaluate(({ notice }) => {
    const c = document.querySelector('#c');
    const x = c.getContext('2d');
    const gradient = x.createLinearGradient(0, 0, 1280, 720);
    gradient.addColorStop(0, '#071927');
    gradient.addColorStop(1, '#16414a');
    x.fillStyle = gradient;
    x.fillRect(0, 0, 1280, 720);
    x.fillStyle = '#d4ad57';
    x.fillRect(70, 88, 96, 5);
    x.fillStyle = '#f8fafc';
    x.font = '700 58px "Yu Gothic UI", Meiryo, sans-serif';
    x.fillText('Server Monitor', 70, 180);
    x.font = '500 34px "Yu Gothic UI", Meiryo, sans-serif';
    x.fillText('2分15秒で見る 実測証跡リプレイ', 70, 238);
    x.fillStyle = '#b6cbd4';
    x.font = '400 24px "Yu Gothic UI", Meiryo, sans-serif';
    x.fillText('構築済みサービス → 監視画面 → 障害注入 → 13秒で自動復旧', 70, 302);
    x.fillStyle = 'rgba(0, 0, 0, .42)';
    x.fillRect(70, 390, 1140, 164);
    x.fillStyle = '#f5f1e7';
    x.font = '500 23px "Yu Gothic UI", Meiryo, sans-serif';
    const words = notice.split('');
    let line = '';
    let y = 442;
    for (const char of words) {
      const candidate = line + char;
      if (x.measureText(candidate).width > 1050) {
        x.fillText(line, 112, y);
        line = char;
        y += 42;
      } else line = candidate;
    }
    x.fillText(line, 112, y);
    x.fillStyle = '#8fb8c6';
    x.font = '400 20px Montserrat, sans-serif';
    x.fillText('Evidence captured: 2026-08-18 / 2026-08-19', 70, 650);
  }, { notice: NOTICE });
  await page.locator('#c').screenshot({ path: POSTER });

  const downloadPromise = page.waitForEvent('download', { timeout: 180_000 });
  await page.evaluate(async ({ assets, notice }) => {
    const c = document.querySelector('#c');
    const x = c.getContext('2d');
    const loaded = {};
    await Promise.all(Object.entries(assets).map(([key, src]) => new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => { loaded[key] = img; resolve(); };
      img.onerror = reject;
      img.src = src;
    })));

    const W = c.width;
    const H = c.height;
    const font = '"Yu Gothic UI", Meiryo, sans-serif';
    const ease = (v) => Math.max(0, Math.min(1, v));

    function background() {
      const gradient = x.createLinearGradient(0, 0, W, H);
      gradient.addColorStop(0, '#061723');
      gradient.addColorStop(1, '#153d45');
      x.fillStyle = gradient;
      x.fillRect(0, 0, W, H);
      x.fillStyle = 'rgba(212,173,87,.13)';
      x.beginPath();
      x.arc(1120, 82, 230, 0, Math.PI * 2);
      x.fill();
    }

    function label(text) {
      x.fillStyle = '#d4ad57';
      x.font = `600 18px Montserrat, ${font}`;
      x.fillText(text.toUpperCase(), 70, 64);
      x.fillRect(70, 80, 82, 4);
    }

    function title(text, y = 138, size = 46) {
      x.fillStyle = '#f8fafc';
      x.font = `700 ${size}px ${font}`;
      x.fillText(text, 70, y);
    }

    function wrap(text, left, top, maxWidth, lineHeight, style = {}) {
      x.fillStyle = style.color || '#dbe8ec';
      x.font = `${style.weight || 400} ${style.size || 25}px ${font}`;
      let line = '';
      let y = top;
      for (const char of text.split('')) {
        if (char === '\n') {
          if (line) x.fillText(line, left, y);
          line = '';
          y += lineHeight;
          continue;
        }
        const candidate = line + char;
        if (x.measureText(candidate).width > maxWidth && line) {
          x.fillText(line, left, y);
          line = char;
          y += lineHeight;
        } else line = candidate;
      }
      if (line) x.fillText(line, left, y);
      return y;
    }

    function footer(text) {
      x.fillStyle = 'rgba(1, 8, 13, .82)';
      x.fillRect(0, 654, W, 66);
      x.fillStyle = '#eef4f5';
      x.font = `500 22px ${font}`;
      x.fillText(text, 70, 696);
    }

    function framedImage(img, left, top, width, height) {
      const sourceRatio = img.width / img.height;
      const targetRatio = width / height;
      let dw = width;
      let dh = height;
      if (sourceRatio > targetRatio) dh = width / sourceRatio;
      else dw = height * sourceRatio;
      const dx = left + (width - dw) / 2;
      const dy = top + (height - dh) / 2;
      x.fillStyle = '#03090d';
      x.fillRect(left - 8, top - 8, width + 16, height + 16);
      x.drawImage(img, dx, dy, dw, dh);
    }

    function scene(t) {
      background();
      if (t < 12) {
        label('Evidence replay');
        title('Server Monitor', 168, 62);
        wrap('2分15秒で見る 実測証跡リプレイ', 70, 230, 1120, 48, { size: 34, weight: 500 });
        x.fillStyle = 'rgba(0, 0, 0, .42)';
        x.fillRect(70, 348, 1140, 188);
        wrap(notice, 112, 404, 1050, 43, { size: 23, weight: 500, color: '#f5f1e7' });
        footer('実測日: 2026-08-18 / 2026-08-19　　公開元: github.com/ns7jp/server-monitor');
      } else if (t < 32) {
        label('01 / Running services');
        title('監視スタック9サービスをLinux上で起動');
        framedImage(loaded.compose, 70, 180, 760, 420);
        wrap('commit aab2fcc', 885, 246, 300, 42, { size: 25, weight: 700, color: '#d4ad57' });
        wrap('Docker 29.1.3\nCompose 2.40.3\napp: healthy', 885, 308, 300, 46, { size: 25 });
        footer('証跡: docker compose ps — alertmanager / alloy / app / blackbox / grafana / loki / nginx / node-exporter / prometheus');
      } else if (t < 56) {
        label('02 / Metrics and logs');
        title('GrafanaでコンテナとLinuxホストを観測');
        framedImage(loaded.grafana, 70, 172, 1140, 440);
        footer('実測値: app scrape up=1 / application CPU 4.80% / host memory 12.8%　（2026-08-18）');
      } else if (t < 78) {
        label('03 / SLO dashboard');
        title('可用性・Error Budget・Burn Rateを表示');
        framedImage(loaded.slo, 70, 172, 780, 440);
        wrap('重要な範囲', 890, 260, 280, 40, { size: 27, weight: 700, color: '#d4ad57' });
        wrap('ラボ起動後、数時間分のデータです。30日間の運用実績を示すものではありません。', 890, 316, 290, 40, { size: 23 });
        footer('確認できたこと: ダッシュボードとルールが実データから値を生成した');
      } else if (t < 108) {
        label('04 / D-1 recovery drill');
        title('appプロセス停止から13秒で自動復旧');
        const progress = ease((t - 81) / 22);
        const startX = 140;
        const endX = 1140;
        const lineY = 360;
        x.strokeStyle = '#355763';
        x.lineWidth = 12;
        x.beginPath(); x.moveTo(startX, lineY); x.lineTo(endX, lineY); x.stroke();
        x.strokeStyle = '#d4ad57';
        x.beginPath(); x.moveTo(startX, lineY); x.lineTo(startX + (endX - startX) * progress, lineY); x.stroke();
        x.fillStyle = '#e36c62'; x.beginPath(); x.arc(startX, lineY, 20, 0, Math.PI * 2); x.fill();
        x.fillStyle = '#72c68c'; x.beginPath(); x.arc(endX, lineY, 20, 0, Math.PI * 2); x.fill();
        wrap('05:38:27Z\nkill -9', 90, 424, 260, 38, { size: 23, weight: 700 });
        wrap('05:38:40Z\n/healthz 復旧', 970, 424, 240, 38, { size: 23, weight: 700 });
        x.fillStyle = '#f8fafc'; x.font = `700 72px ${font}`; x.fillText('RTO 13秒', 446, 292);
        wrap('RestartCount  0 → 1　　判定 PASS　　目標 5分以内', 326, 540, 720, 42, { size: 27, weight: 600 });
        footer('対象 commit 5dfc67d / WSL2 Ubuntu 24.04 + Docker Compose / 実行日 2026-08-19');
      } else if (t < 122) {
        label('05 / What failed first');
        title('失敗も原因・修正と一緒に残す');
        const cards = [
          ['1回目', 'docker compose killでは再起動しなかった', 'host側PIDへ kill -9 に変更'],
          ['2回目', '修正版が手元のmainへ未反映だった', 'commitと実行コードを先に確認'],
          ['最終', 'RestartCount増加とhealthz復旧を確認', 'RTO 13秒でPASS'],
        ];
        cards.forEach((card, i) => {
          const top = 190 + i * 126;
          x.fillStyle = 'rgba(5, 18, 27, .78)'; x.fillRect(70, top, 1140, 100);
          wrap(card[0], 98, top + 40, 130, 34, { size: 22, weight: 700, color: '#d4ad57' });
          wrap(card[1], 250, top + 38, 545, 34, { size: 22 });
          wrap(card[2], 810, top + 38, 360, 34, { size: 21, weight: 600, color: '#a7d7b4' });
        });
        footer('一次記録: 症状 → 原因 → 対処 → 学び　　成功結果だけに整形しない');
      } else {
        label('Scope and sources');
        title('確認できたこと／まだ確認していないこと');
        wrap('実測済み', 70, 225, 320, 40, { size: 28, weight: 700, color: '#72c68c' });
        wrap('9サービス起動\nGrafana実データ\nD-1 自動復旧 13秒', 70, 278, 430, 44, { size: 25 });
        wrap('この映像の範囲外', 640, 225, 430, 40, { size: 28, weight: 700, color: '#e9b66d' });
        wrap('Slack実配信\nAlertmanager画面採録\nAWS apply / destroy\n実操作の連続録画', 640, 278, 500, 44, { size: 25 });
        wrap('元のスクリーンショット・ログ・検証台帳はデモページから確認できます。', 70, 558, 1100, 42, { size: 24, weight: 600 });
        footer('Evidence replay — 編集済み映像だけを実測根拠にはしません');
      }
    }

    const mime = 'video/mp4;codecs=avc1.42E01E';
    if (!MediaRecorder.isTypeSupported(mime)) throw new Error(`${mime} is unsupported`);
    const stream = c.captureStream(0);
    const track = stream.getVideoTracks()[0];
    const chunks = [];
    const recorder = new MediaRecorder(stream, { mimeType: mime, videoBitsPerSecond: 500000 });
    recorder.ondataavailable = (event) => { if (event.data.size) chunks.push(event.data); };
    const stopped = new Promise((resolve, reject) => {
      recorder.onstop = resolve;
      recorder.onerror = (event) => reject(event.error);
    });
    recorder.start(1000);

    const fps = 12;
    const duration = 135;
    const startedAt = performance.now();
    let frame = 0;
    while ((performance.now() - startedAt) / 1000 < duration) {
      const t = (performance.now() - startedAt) / 1000;
      scene(t);
      track.requestFrame();
      if (frame % (fps * 15) === 0) console.log(`Rendering ${Math.round(t)} / ${duration} seconds`);
      frame += 1;
      const nextFrameAt = startedAt + frame * (1000 / fps);
      await new Promise((resolve) => setTimeout(resolve, Math.max(0, nextFrameAt - performance.now())));
    }
    recorder.stop();
    await stopped;
    const blob = new Blob(chunks, { type: 'video/mp4' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'server-monitor-evidence-replay.mp4';
    document.body.append(link);
    link.click();
  }, { assets, notice: NOTICE });

  const download = await downloadPromise;
  await download.saveAs(OUTPUT);
  await browser.close();
  const size = fs.statSync(OUTPUT).size;
  console.log(`Wrote ${OUTPUT} (${(size / 1024 / 1024).toFixed(2)} MiB)`);
  console.log(`Wrote ${POSTER}`);
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
