# バックアップ / リストア Runbook

ITサポート・社内SE補助で求められる「**毎日バックアップを取る** だけでなく **必要なときに必ず戻せる** ことを示す」運用Runbookです。
Windows ファイルサーバー（VSS）と Linux サーバー（rsync）の 2 系統を載せ、最後にリストアテスト手順までを含めています。

> 公開ポートフォリオ用の架空ホスト名（fs01 / app01）を使っています。実環境では台帳と整合を取って読み替えてください。

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

## 4. リストアテスト計画（月 1 回）

**バックアップは取得できても戻せなければゼロ**、を前提に毎月 1 回実施します。

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
