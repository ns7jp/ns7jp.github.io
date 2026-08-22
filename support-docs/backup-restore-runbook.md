# バックアップ / リストア Runbook

ITサポート・社内SE補助で求められる「**毎日バックアップを取る** だけでなく、必要なときに戻せるかを検証する」ための運用Runbookです。
Windows ファイルサーバー（VSS）と Linux サーバー（rsync）の 2 系統を載せ、最後にリストアテスト手順までを含めています。

> 公開ポートフォリオ用の架空ホスト名（fs01 / app01）を使っています。実環境では台帳と整合を取って読み替えてください。
> 本書は手順・記録様式・実施計画です。実際の月次リストアテスト、年次DRドリル、RTO達成の実測証跡はまだありません。

---

## 1. バックアップ方針（共通）

| 項目 | 方針 |
|---|---|
| 3-2-1 原則 | **3 つのコピー**（本番 + ローカル + オフサイト）、**2 種類のメディア**、**1 つはオフサイト** |
| 保管期間 | 日次 30 世代、週次 12 世代、月次 12 世代 |
| 暗号化 | バックアップ媒体上で AES-256 暗号化 |
| 検証 | **月 1 回のリストアテスト** を実施し、台帳に記録 |
| 監視 | ジョブ成否は Prometheus / メールで通知。**3 日連続失敗で P2 起票** |
| 退役 | バックアップ媒体は破棄前に物理破壊 / `cryptsetup erase` で確実に削除 |

---

## 1.5 RTO / RPO — サービス別の復旧目標

「バックアップを取っている」だけでは不足で、「**何時間以内に戻すか (RTO)**」「**どこまで戻る前提か (RPO)**」を**サービス別に数値化**して合意します。

| 用語 | 意味 | 例 |
|---|---|---|
| **RTO** (Recovery Time Objective) | 障害発生から復旧までの目標時間 | 「ファイルサーバーは 4h 以内に書き込み可能」 |
| **RPO** (Recovery Point Objective) | 復旧時にどこまで戻る前提か（許容データ消失） | 「最大 24h 前の状態まで戻す」 |
| **MTPD** (Maximum Tolerable Period of Disruption) | これを超えると業務継続不可になる時間 | 「48h を超えると主要納品に影響」 |

### サービス別 RTO / RPO 表（Lab 想定）

| サービス | 重要度 | RTO | RPO | MTPD | 根拠 |
|---|---|---|---|---|---|
| **AD DS / DNS (ad01/ad02)** | 最重要 | 2h | 1h | 4h | 認証停止で全サービス影響、DC 2 台冗長で実質ゼロ停止前提 |
| **ファイル共有 (fs01)** | 重要 | 4h | 24h | 48h | 日次 02:00 取得、復旧後 4h 以内に主要部署が書き込み再開できる |
| **業務 DB (sqldb01)** | 重要 | 6h | 4h | 24h | 4h ごとの差分ログ + 日次フル、復旧手順は[Backup §X]、要リストアテスト |
| **Web / アプリ (app01)** | 通常 | 24h | 24h | 72h | Ansible で再構築 + S3 から復元 |
| **監視 (mon01)** | 補助 | 24h | 7d | 7d | Lab 性質上、設定は Git に履歴、TSDB は失っても許容 |
| **Grafana / Prometheus 設定** | 補助 | 4h | Git の最新 | — | Provisioning ファイルは Git で世代管理 |

### RTO / RPO を決める順序

1. **業務影響の聞き取り**: 「これが止まると何時間で誰が困るか」を業務側に確認
2. **過去の停止時間データ**: 既存のインシデント履歴から実績を読む
3. **コストとのバランス**: RTO を半分にすると運用コストはほぼ倍。重要度に応じて差をつける
4. **複数サービスの組み合わせ**: 「AD が落ちると fs01 も使えない」など依存関係を明示
5. **合意 → ドキュメント化 → 半期見直し**

> 「全部 RTO 1 時間 / RPO ゼロ」とすると、コスト・運用負荷とも非現実的になります。**重要度の差を意図的につける**のが本質です。

---

---

## 2. Windows ファイルサーバー（fs01）— VSS + Robocopy

### 2.1 構成

- **対象**: `D:\share` 配下の部門共有
- **保管先**: `\\bk01\fs01-backup` (別筐体 NAS / SMB)
- **方式**: VSS スナップショットを取得し、その時点のファイルを Robocopy で差分コピー
- **頻度**: 日次 02:00（タスクスケジューラ）

### 2.2 取得スクリプト

`C:\ops\Backup-FileShare.ps1`（要点のみ）:

```powershell
[CmdletBinding()]
param(
    [string]$Source      = 'D:\share',
    [string]$Destination = '\\bk01\fs01-backup',
    [string]$LogDir      = 'C:\ops\logs'
)

$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $LogDir "backup-$ts.log"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# 1) VSS スナップショット作成 (Cドライブ違い: 対象はDドライブ)
$shadow = (Get-WmiObject -List Win32_ShadowCopy).Create('D:\','ClientAccessible')
$id     = $shadow.ShadowID
$device = (Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $id }).DeviceObject
$link   = 'C:\ops\shadow-d'
cmd /c "mklink /D `"$link`" `"$device\`""  | Out-Null

try {
    # 2) Robocopy で差分コピー
    $robocopyArgs = @(
        "$link\share",
        "$Destination",
        '/MIR',          # 差分ミラー
        '/COPY:DAT',     # データ + 属性 + タイムスタンプ
        '/DCOPY:T',      # ディレクトリのタイムスタンプ
        '/R:1', '/W:5',  # リトライ少なめ
        '/NP',           # 進捗非表示
        '/LOG:' + $log
    )
    robocopy @robocopyArgs
    $rc = $LASTEXITCODE
    if ($rc -ge 8) { throw "Robocopy failed with exit code $rc" }
}
finally {
    # 3) シンボリックリンクとシャドウコピーを必ず削除
    cmd /c "rmdir `"$link`"" | Out-Null
    (Get-WmiObject Win32_ShadowCopy | Where-Object { $_.ID -eq $id }).Delete() | Out-Null
}

Write-Host "Backup completed: $log"
```

### 2.3 タスク登録

```powershell
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\ops\Backup-FileShare.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 02:00
Register-ScheduledTask -TaskName 'FS01 Daily Backup' -Action $action -Trigger $trigger `
    -RunLevel Highest -User 'SYSTEM' -Description '日次フルパス差分バックアップ'
```

### 2.4 リストア手順（個別ファイル）

1. 共有フォルダのプロパティ > **以前のバージョン**（または `\\bk01\fs01-backup` から直接） からファイルを特定
2. 別フォルダにコピーして **内容を確認**（直接上書きしない）
3. 利用者と確認のうえ、元の場所へ復元
4. 復元日時、ファイル数、依頼者をチケットに記録

### 2.5 リストア手順（共有フォルダごと壊れた場合）

1. 影響範囲を切り出し、利用者に **アクセス停止** を通知（共有を一時的に隠す）
2. 破損データを `D:\share-broken-YYYYMMDD` へ退避（消さない）
3. `\\bk01\fs01-backup` からの最新世代を Robocopy で `/MIR` ではなく **コピー** で復元
4. **抜き取り 10 ファイル** を利用者と一緒に開いて内容確認
5. アクセス権を再付与し、利用者へ復旧連絡
6. 退避フォルダは 30 日後に削除（カレンダーで予約）

---

## 3. Linux サーバー（app01）— rsync + systemd timer

### 3.1 構成

- **対象**: `/etc` `/var/www` `/srv/data`
- **保管先**: `/mnt/backup/app01/`（別ディスク）→ 週次で `s3://backup-coldline/app01/` へ rclone 同期
- **方式**: `rsync --link-dest` によるハードリンク世代管理
- **頻度**: 日次 03:00（systemd timer）

### 3.2 取得スクリプト

`/usr/local/sbin/daily-backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

HOST=$(hostname)
DATE=$(date +%Y-%m-%d)
DST=/mnt/backup/$HOST/$DATE
LATEST=/mnt/backup/$HOST/latest
LOG=/var/log/daily-backup.log

mkdir -p "$DST"

rsync -aHAX --delete --numeric-ids \
      --link-dest="$LATEST" \
      /etc /var/www /srv/data \
      "$DST"/ 2>&1 | tee -a "$LOG"

ln -snf "$DST" "$LATEST"

# 30日より古い世代を削除（ハードリンクなので実容量は最小限）
find /mnt/backup/$HOST -maxdepth 1 -type d -name '20*' -mtime +30 -exec rm -rf {} +

# 月初は S3 (cold tier) へオフサイト同期
if [ "$(date +%d)" = "01" ]; then
    rclone sync /mnt/backup/$HOST/latest s3:backup-coldline/$HOST/ --log-file="$LOG"
fi
```

### 3.3 systemd unit / timer

```ini
# /etc/systemd/system/daily-backup.service
[Unit]
Description=Daily rsync backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/daily-backup.sh
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7

# /etc/systemd/system/daily-backup.timer
[Unit]
Description=Run daily-backup.sh at 03:00

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
```

有効化:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now daily-backup.timer
systemctl list-timers daily-backup.timer
```

### 3.4 リストア手順（個別ファイル）

```bash
# 1) 対象世代の一覧
ls /mnt/backup/app01/
# 2) 復元先を仮置きする
mkdir -p /tmp/restore
rsync -aHAX /mnt/backup/app01/2026-05-10/var/www/index.html /tmp/restore/
# 3) 中身を確認してから本番へ
diff /var/www/index.html /tmp/restore/index.html | less
sudo cp /tmp/restore/index.html /var/www/index.html
```

### 3.5 リストア手順（全損失）

1. 新規ホストを Ansible playbook で初期化（[ansible/playbook.yml](../ansible/playbook.yml)）
2. S3 からの最新を取得
   ```bash
   rclone copy s3:backup-coldline/app01/ /mnt/restore/
   ```
3. `/etc` は **そのままコピーしない**。差分を必ず `diff -r` で確認しながら個別反映
4. `/var/www` `/srv/data` はディレクトリ単位で復元 → サービス起動 → 動作確認
5. リストア完了をインシデント Postmortem に記録

---

## 4. リストアテスト計画（月 1 回） / DR ドリル（年 1 回）

**バックアップは取得できても戻せなければゼロ**、を前提に、月次リストアテストと年次 DR ドリルを組み合わせます。

### 4.1 月次リストアテスト

| 月 | 対象 | 担当 | 確認内容 | 結果記録先 |
|---|---|---|---|---|
| 第 1 月曜 14:00 | fs01 — ランダム 3 ファイル | 運用 A | 復元ファイル数、所要時間、開けるか | 運用台帳 §4.1 |
| 第 1 月曜 15:00 | app01 — `/var/www` 一括 | 運用 B | チェックサム一致、サービス再起動後の応答 | 運用台帳 §4.2 |
| 半期 1 回 | app01 — **本番相当 VM へ完全リストア** | 運用 A + B | サイト 200 / DB クエリ / ジョブ完走 | 運用台帳 §4.3（最重要） |

### テスト記録テンプレート

```
- 実施日時 : 2026-05-05 14:00 - 14:42
- 担当者   : 運用 A
- 対象     : fs01 / share/Dept-Sales/proposal-A.docx 他 2 件
- 方式     : \\bk01\fs01-backup の前日世代から復元
- 所要時間 : 28 分（うち承認確認 18 分）
- 結果     : OK — ファイル開封 / ハッシュ一致確認済
- 課題     : 復元先パスを利用者に毎回確認している。次回までに台帳テンプレに記入欄を追加
```

### 4.2 年次 DR (Disaster Recovery) ドリル

「サーバールーム全損」「クラウドリージョン障害」のような**最悪シナリオ**を想定し、年 1 回フルスケールで実施します。

#### シナリオ A: サーバールーム全損（火災・水害想定）

| 時刻 | 役割 | 行動 | 確認項目 |
|---|---|---|---|
| T+0:00 | IC（インシデントコマンダー） | DR 宣言 → 各役割召集 | 召集完了所要時間 |
| T+0:15 | Tech Lead | オフサイトバックアップ（S3 / 別建屋 NAS）の最新性確認 | RPO 24h 以内に戻れるか |
| T+0:30 | Infra A | 仮環境（クラウド VM / 予備機）で AD DS を復旧 | RTO 2h を測定 |
| T+1:00 | Infra B | ファイル共有を予備機にリストア | RTO 4h を測定 |
| T+2:00 | Comms | 影響範囲ユーザーへ第 1 報 | 主要連絡先のリーチ確認 |
| T+4:00 | Infra A+B | 業務 DB 復旧（差分ログまで適用） | RPO 4h を測定 |
| T+6:00 | 全員 | 利用者 3 名で復旧確認 | 業務継続可能か |
| T+8:00 | Scribe | タイムライン + 課題リスト確定 | RTO/RPO 実績 vs 目標 |

#### シナリオ B: 主要 AD DC 1 台が長時間停止

| 時刻 | 行動 | 確認項目 |
|---|---|---|
| T+0:00 | DC02 を意図的に停止 | 認証フェイルオーバー所要時間 |
| T+0:05 | クライアント側からログオン / GPO 適用テスト | 業務影響なし確認 |
| T+0:30 | DC02 を復旧 → レプリケーション再開 | レプリ完了時間 |
| T+1:00 | repadmin /showrepl で同期確認 | エラー無し |

#### シナリオ C: ランサムウェア / バックアップ含む暗号化

| 時刻 | 行動 | 確認項目 |
|---|---|---|
| T+0:00 | 暗号化検出（Defender アラート） | 検知ラグ |
| T+0:15 | 影響範囲ホストをネットワーク隔離 | 隔離手順の所要時間 |
| T+0:30 | オフサイトバックアップの隔離世代を確認 | エアギャップ / Immutable Backup の有効性 |
| T+4:00 | クリーン環境で最新の健全世代から復元 | RTO 達成可否 |
| T+24:00 | フォレンジック / 通報 / 顧客連絡 | コミュニケーションプラン |

> 暗号化攻撃に備え、**直近 30 日のバックアップは Object Lock / Immutable Storage** にして書き換え不可にする想定です。

### 4.3 DR ドリル 振り返りテンプレート（以下は架空の記入例）

```
- 実施日       : 2026-11-08（年次）
- 区分         : 架空の記入例（未実施）
- シナリオ     : A. サーバールーム全損（仮想)
- 参加者       : 運用 A / 運用 B / 業務代表 / 経営層オブザーバー
- 所要時間     : 8h 35m（計画 8h）

[ 計測結果 ]
- AD 復旧 RTO  : 計画 2h / 実績 1h 48m  ✅
- fs01 復旧 RTO: 計画 4h / 実績 4h 22m  ⚠ (22 分超過)
- DB 復旧 RTO  : 計画 6h / 実績 5h 30m  ✅
- DB 復旧 RPO  : 計画 4h / 実績 3h 50m  ✅

[ 顕在化した課題 ]
- fs01 のリストア中に NAS 認証ハマり (15 分) → 次回までに Runbook §3.5 に明記
- 連絡網: 業務代表の代理連絡先が更新されていなかった → 半期棚卸しに追加
- DB 差分ログ取得時に圧縮ジョブが競合 → スケジュール調整

[ 次回改善 ]
- 11/30: Runbook §3.5 改訂、連絡網棚卸し
- 12/15: 部分ドリル（fs01 のみ）でリトライ計測
- 来年同月: フル DR ドリル再実施
```

### 4.4 DR ドリルで意識する点

- **本番運用と同等の心理状態**を再現する: 「これは訓練です」とアナウンスしつつ、実際にチケットを切り、計測する
- **完璧な成功を目的にしない**: 失敗や予想外の発生こそ価値。それが Runbook 更新ネタになる
- **業務側の参加**: 復旧完了の判定は業務側が行う。技術的 OK ≠ 業務 OK
- **記録の徹底**: タイムスタンプ・誰が何を判断したかを Scribe（書記）が淡々と残す
- **改善計画の起票**: 振り返りで出た課題を次のドリルまでに完了する KGI を設定

---

## 5. 失敗が起きやすい箇所と対策

| よくある失敗 | 対策 |
|---|---|
| バックアップは取れているが、**実は対象から除外されていた**（PST など） | 除外パターンを四半期棚卸し（[postmortem-example.md](./postmortem-example.md) 参照） |
| バックアップ先が **同筐体** で、本番ディスク障害時に道連れ | 別筐体 / 別建屋 / クラウド の **3-2-1** 原則を必ず守る |
| **アクセス権が消える**（Robocopy で `/COPY:DAT` を `/COPY:DATSOU` にしていない等） | リストアテストで NTFS ACL の復元まで確認 |
| バックアップユーザーが **管理者特権を保持し続け** 侵害時に水平展開される | 専用サービスアカウント + 最小権限 + 別パスワードボールト |
| 監視が無く **3 日連続失敗に気付かない** | systemd の `OnFailure=` でメール通知、Prometheus に `backup_last_success_timestamp` を出力 |

---

## 関連リンク

- [Linux Lab](../linux-lab.html) — rsync + systemd timer の解説
- [Ansible Playbook](../ansible/) — 新規ホストのベースライン
- [Monitoring Stack](../monitoring-stack/) — バックアップ成否を Prometheus で観測
- [Postmortem 例](./postmortem-example.md) — 共有フォルダ I/O 飽和の事後分析
- [重大インシデント対応プレイブック](./incident-response-playbook.md)
