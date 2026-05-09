# Support Scripts — IT サポート / インフラ運用向け確認スクリプト集

ITサポート・ヘルプデスク・社内SE補助・インフラ運用で使う場面を想定した、**読み取り中心**の確認スクリプト集です。**Windows クライアントを対象とした PowerShell 8 本** と、**Linux サーバーを対象とした Bash 5 本** の両方を収録しています。

公開ポートフォリオ用のため、社内固有のサーバー名、ユーザーID、IPアドレス、認証情報は含めていません。実運用で使う場合は、自社のセキュリティポリシー、ログ取得範囲、個人情報の取り扱いルールに合わせて調整してください。

| プラットフォーム | 言語 | 対象 | 本数 |
|---|---|---|---|
| Windows 11 / Windows Server | PowerShell 5.1+ | 端末・AD・M365 | 8 |
| Linux (Ubuntu / RHEL 系) | Bash 4+ / `python3` | サーバー・エンドポイント | 5 |

両者は同じ思想で書いています。**入力は最小限の引数、出力は JSON または CSV、状態変更は一切しない**。チケット添付・引き継ぎ資料・タスクスケジューラ / cron 連携を共通の出力フォーマットで実現します。

---

## 初学者向け: このフォルダで見てほしいこと

このフォルダは「すごい自動化をする」よりも、**問い合わせを受けた後に、同じ順番で状態を確認し、結果を記録できること**を目的にしています。

PowerShell / Bash いずれも、初学者の方は次の順番で読むと理解しやすいです。

1. `README.md` で、各スクリプトが何の確認に使われるかを把握する
2. 各 `.ps1` / `.sh` ファイル先頭のコメントヘルプを読む
3. `param(...)` または `getopts` の部分を見て、実行時に変更できる値を確認する
4. `Get-...` / `Test-...` / `df` / `ip` などのコマンドが、何を取得・確認・出力しているかを見る
5. 最後に `ConvertTo-Json` / `python3` / `Export-Csv` で、結果をどの形式で保存しているかを見る

このサンプルでは、削除・設定変更・サービス再起動のような破壊的な操作は入れていません。基本は **読む、確認する、記録する** ためのスクリプトです。

---

## PowerShell の基本的な読み方

PowerShell では、コマンド名が `動詞-名詞` の形になっています。初学者は、まず動詞に注目すると処理の意味をつかみやすいです。

| 例 | ざっくりした意味 | このフォルダでの使い方 |
|---|---|---|
| `Get-...` | 情報を取得する | PC情報、イベントログ、ADユーザー、M365ライセンスを取得 |
| `Test-...` | 状態を確認する | ネットワーク疎通、ディスク容量、セキュリティ状態を確認 |
| `Select-Object` | 必要な項目だけ選ぶ | 取得結果から、チケットに必要な列だけ残す |
| `Where-Object` | 条件で絞り込む | エラーだけ、休眠アカウントだけ、警告状態だけ抽出 |
| `Sort-Object` | 並び替える | 日付の新しい順、利用率の高い順などに並べる |
| `ConvertTo-Json` | JSONに変換する | 端末状態を機械的に扱いやすい形式で保存 |
| `Export-Csv` | CSVに出力する | Excelやチケット添付で見やすい形式に保存 |

`param(...)` は「実行時に外から渡せる設定値」です。たとえば `-OutputPath` を指定すると、出力ファイル名や保存場所を変えられます。

```powershell
.\Collect-PcInventory.ps1 -OutputPath .\pc-inventory.json
```

この例では、`Collect-PcInventory.ps1` の中にある `$OutputPath` という変数へ `.\pc-inventory.json` が入ります。

---

## 収録スクリプト

### Windows 系 — PowerShell

| ファイル | 用途 | 使う場面 |
|---|---|---|
| `Collect-PcInventory.ps1` | 端末情報を JSON で出力 | PC入替、問い合わせ受付時の環境把握 |
| `Test-NetworkTriage.ps1` | ゲートウェイ、DNS、外部疎通を確認 | ネットワークにつながらない時の一次切り分け |
| `Get-RecentSupportEvents.ps1` | 直近の警告・エラーログを CSV 出力 | PC不調、アプリ異常終了、再起動調査 |
| `Test-DiskCapacity.ps1` | ディスク使用率と物理ディスク状態を確認 | PC低速化、容量不足、監視前の棚卸し |
| `Test-SecurityBaseline.ps1` | Defender / Firewall / BitLocker / Windows Update の状態を一括確認 | セキュリティ監査、棚卸し前の一括チェック |
| `New-EndpointDailyReport.ps1` | 上記全スクリプトを実行し CSV/HTML サマリーを生成 | 日次点検、引き継ぎ資料作成、タスクスケジューラ連携 |
| `Get-StaleUserAccounts.ps1` | Active Directory の休眠ユーザーを検出（読み取り専用） | 退職者・長期休職者アカウントの棚卸し、内部監査 |
| `Get-M365LicenseInventory.ps1` | Microsoft Graph 経由で M365 ライセンス割当を CSV 出力 | ライセンス棚卸し、コスト最適化、部署別利用状況の把握 |

### Linux 系 — Bash

| ファイル | 用途 | 使う場面 | PowerShell 対応版 |
|---|---|---|---|
| `collect-host-inventory.sh` | ホスト基本情報 (OS / カーネル / CPU / メモリ / FS / IPv4) を JSON で出力 | サーバー受領・棚卸し・問い合わせ受付 | `Collect-PcInventory.ps1` |
| `test-network-triage.sh` | デフォルト経路・ゲートウェイ・指定宛先・DNS の到達性を確認 | サーバーから外部へ繋がらない時の一次切り分け | `Test-NetworkTriage.ps1` |
| `get-recent-support-events.sh` | journald から直近 N 時間の `warning` 以上を CSV 抽出 | サービス異常終了・OOM Kill・再起動調査 | `Get-RecentSupportEvents.ps1` |
| `test-disk-capacity.sh` | 容量・inode 使用率・SMART 健康状態を確認 (しきい値判定付き) | サーバー逼迫前の棚卸し、書き込み不可調査 | `Test-DiskCapacity.ps1` |
| `test-security-baseline.sh` | sshd 設定・ファイアウォール・fail2ban・自動更新・SELinux/AppArmor・auditd を一括確認 | サーバー受領時のベースライン、月次セキュリティ棚卸し | `Test-SecurityBaseline.ps1` |

---

## 各スクリプトの詳しい説明

### `Collect-PcInventory.ps1`

端末の基本情報を JSON ファイルに保存します。PC交換、問い合わせ受付、資産管理の入口として「このPCは何者か」を確認するためのスクリプトです。

取得する主な情報は、PC名、ログインユーザー名、メーカー、型番、ドメイン、メモリ容量、OS情報、BIOSシリアル番号、CPU、ディスク、ネットワークアダプター、直近の更新プログラムです。

初学者向けの見どころ:

- `Get-CimInstance` で Windows 管理情報を取得している
- `[ordered]@{ ... }` で、出力する項目の順番を決めている
- `ConvertTo-Json -Depth 6` で、階層のある情報をJSONに変換している

### `Test-NetworkTriage.ps1`

「ネットにつながらない」という問い合わせの一次切り分けを行います。デフォルトゲートウェイ、外部宛先への疎通、DNS名前解決を確認します。

初学者向けの見どころ:

- `Get-NetIPConfiguration` で現在使っているネットワーク設定を確認している
- `Test-Connection` は PowerShell 版の ping と考えると分かりやすい
- `Resolve-DnsName` で、名前解決ができるかを確認している
- `try { ... } catch { ... }` で、失敗しても結果として記録できるようにしている

### `Get-RecentSupportEvents.ps1`

Windows のイベントログから、直近の警告・エラーを CSV に出力します。PC不調、アプリ異常終了、再起動調査などで「何か記録が残っていないか」を確認する用途です。

初学者向けの見どころ:

- `Get-WinEvent` でイベントログを読む
- `Level = 2, 3` はエラーと警告を意味する
- メッセージが長すぎると扱いにくいため、500文字までに短くしている

### `Test-DiskCapacity.ps1`

各ドライブの使用率と物理ディスクの状態を確認します。容量不足、PC低速化、監視前の棚卸しで使う想定です。

初学者向けの見どころ:

- `Win32_LogicalDisk` は Cドライブなどの論理ドライブ情報
- `Get-PhysicalDisk` は物理ディスクの健康状態
- `$WarningPercent` 以上なら `Warning` として扱う

### `Test-SecurityBaseline.ps1`

Defender、Firewall、BitLocker、Windows Update の状態をまとめて確認します。これはセキュリティ設定を変更するスクリプトではなく、現在の状態を読み取って記録するスクリプトです。

初学者向けの見どころ:

- 各チェックを `try/catch` で分け、取得できない項目があっても全体を止めない
- `OK` / `Warning` / `Unknown` のように、人が見て判断しやすい状態名へ変換している
- 最後に全体の総合判定を作っている

### `New-EndpointDailyReport.ps1`

端末確認系のスクリプトをまとめて実行し、日次レポートを作ります。個別スクリプトの結果を読み込み、CSV と HTML のサマリーにまとめます。

初学者向けの見どころ:

- `& "$PSScriptRoot\..."` で、同じフォルダ内の別スクリプトを呼び出している
- JSON / CSV を読み戻して、要約行を作っている
- HTMLを文字列として組み立て、ブラウザで見やすい一覧を作っている

### `Get-StaleUserAccounts.ps1`

Active Directory から、長期間ログインしていないユーザーを抽出します。退職者・長期休職者・不要アカウントの棚卸しを想定しています。

初学者向けの見どころ:

- 実行には RSAT の ActiveDirectory モジュールが必要
- `LastLogonDate` は厳密な最終ログオンではなく、棚卸し向けの近似値
- このスクリプトは読み取り専用で、アカウント無効化や削除は行わない

### `Get-M365LicenseInventory.ps1`

Microsoft Graph PowerShell SDK を使って、Microsoft 365 のライセンス割当状況を CSV に出力します。ライセンスの余り、不足、部署別利用状況を把握するためのサンプルです。

初学者向けの見どころ:

- `Connect-MgGraph` で Microsoft 365 テナントへ接続する
- `Get-MgSubscribedSku` で契約しているライセンス種別を取得する
- `Get-MgUser` でユーザーごとのライセンス割当を取得する
- 利用率から `NearlyFull` / `Underutilized` / `Normal` を判定している

### `collect-host-inventory.sh`

Linux ホストの基本情報を JSON で出力します。`Collect-PcInventory.ps1` の Linux 対応版です。サーバー受領時の構成記録、問い合わせ対象サーバーの環境把握、棚卸しの初期スナップショットに使えます。

取得する主な情報は、ホスト名、`/etc/os-release` の OS / バージョン、カーネル、稼働時間、CPU 名・論理コア数、メモリ容量、各マウントポイントの容量、IPv4 アドレス、直近インストールパッケージです。

初学者向けの見どころ:

- `set -euo pipefail` でエラー / 未定義変数 / パイプ失敗を即時検知する安全モードに切り替える
- `/etc/os-release` を `.` (source) で読み込み、ディストリ間で共通の OS 情報を取得する
- `command -v` でコマンドの存在を確認し、無い場合は静かにスキップする
- 値はすべて環境変数で `python3` ヘルパに渡し、`json.dumps` で安全にエスケープする

### `test-network-triage.sh`

Linux サーバーの一次切り分けを行います。`Test-NetworkTriage.ps1` の Linux 対応版です。デフォルト経路、ゲートウェイ、指定宛先 (8.8.8.8 / GitHub / Microsoft 等) への ICMP、DNS 名前解決を順番に確認します。

初学者向けの見どころ:

- `ip route show default` でデフォルト経路を取り、`awk` で `via` / `dev` を抽出する
- `ping -c N -W timeout` の出力末尾 `rtt ... = min/avg/max/...` から平均応答時間を抽出する
- `getent hosts NAME` で `nsswitch` 経由の名前解決を確認する (`/etc/hosts` も DNS も両方カバー)
- 確認結果はゲートウェイ / 各ターゲット / DNS と分け、JSON のキーで意味が伝わるようにする

### `get-recent-support-events.sh`

systemd の `journald` から、過去 N 時間の警告以上のログを CSV 抽出します。`Get-RecentSupportEvents.ps1` の Linux 対応版です。

初学者向けの見どころ:

- `journalctl --priority=warning --since "N hours ago"` で抽出範囲を絞る
- `--output=json` を使うと 1 行 1 レコードの JSON で取れて、`python3` で安全に解析できる
- `__REALTIME_TIMESTAMP` はマイクロ秒の epoch なので 1,000,000 で割って ISO 8601 に整形する
- メッセージは 500 文字までに切り、CSV を読みやすく保つ

### `test-disk-capacity.sh`

容量・inode 使用率・SMART 健康状態を確認し、しきい値を超える項目を `Warning` で出力します。`Test-DiskCapacity.ps1` の Linux 対応版です。

初学者向けの見どころ:

- `df -B1 --output=...` でバイト単位の正確な値を取り、Python で GB に丸める
- `df --output=itotal,iused,iavail,ipcent,...` で inode 使用率を別系統で確認する (容量が空でも inode が枯渇すると書き込めない)
- `smartctl -H` がある環境では物理ディスクの健康状態を追加で確認する
- しきい値判定 (`OK` / `Warning`) は呼び出し時に `-w` / `-i` で上書き可能

### `test-security-baseline.sh`

Linux サーバーのセキュリティベースラインを一括確認します。`Test-SecurityBaseline.ps1` の Linux 対応版です。

確認するポイント:

- `sshd_config` の `PermitRootLogin` / `PasswordAuthentication` / `Port`
- ホストファイアウォール (`ufw` / `firewalld` / `iptables`) の状態とルール数
- `fail2ban` のインストール状況とサービス稼働
- 自動セキュリティ更新 (`unattended-upgrades` / `dnf-automatic`)
- 強制アクセス制御 (SELinux `getenforce` / AppArmor `aa-status`)
- `auditd` の稼働状態
- パッケージキャッシュの最終更新からの経過日数

各項目は `OK` / `Warning` / `Unknown` で判定し、最後に総合判定を出します。設定変更は一切行わず、現状把握のみです。

---

## 実行例

PowerShell を管理者権限で開き、必要に応じて実行ポリシーを一時的に緩和します。

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

端末情報を収集します。

```powershell
.\Collect-PcInventory.ps1 -OutputPath .\pc-inventory.json
```

ネットワークの一次切り分けを行います。

```powershell
.\Test-NetworkTriage.ps1 -Targets 8.8.8.8,github.com -DnsName microsoft.com
```

直近24時間の警告・エラーイベントをCSVに出力します。

```powershell
.\Get-RecentSupportEvents.ps1 -Hours 24 -OutputPath .\support-events.csv
```

ディスク容量を確認します。

```powershell
.\Test-DiskCapacity.ps1 -WarningPercent 80
```

セキュリティ基準（Defender / Firewall / BitLocker / Windows Update）を一括確認します。

```powershell
.\Test-SecurityBaseline.ps1 -OutputPath .\security-baseline.json
```

上記すべてを実行し、CSV / HTML の日次レポートを生成します（タスクスケジューラ連携を想定）。

```powershell
.\New-EndpointDailyReport.ps1 -OutputDir .\reports\2026-05-07
```

Active Directory の 90 日以上未ログインのアカウントを CSV で抽出します（読み取り専用）。

```powershell
# RSAT-AD-PowerShell が必要。ドメイン参加端末で実行する。
.\Get-StaleUserAccounts.ps1 -InactiveDaysThreshold 90 `
    -SearchBase "OU=Users,DC=corp,DC=local" `
    -OutputPath .\stale-accounts.csv
```

Microsoft 365 のライセンス割当一覧を取得します（Microsoft Graph PowerShell SDK が必要）。

```powershell
# 初回のみ: Install-Module Microsoft.Graph -Scope CurrentUser
# 実行時にブラウザでサインイン (User.Read.All / Organization.Read.All)
.\Get-M365LicenseInventory.ps1 -OutputDir .\m365-inventory
```

### Linux 系 (Bash)

実行権限を付与してからシェルで実行します。出力は標準出力か `-o` で指定したファイルに JSON / CSV で書き出します。

```bash
chmod +x ./support-scripts/*.sh
```

ホスト基本情報を JSON に保存します。

```bash
./support-scripts/collect-host-inventory.sh -o ./host-inventory.json
```

ネットワークの一次切り分けを行います。

```bash
./support-scripts/test-network-triage.sh \
    -t 8.8.8.8,github.com,microsoft.com \
    -d microsoft.com \
    -o ./network-triage.json
```

過去 24 時間の警告・エラーイベント (journald) を CSV 抽出します。

```bash
./support-scripts/get-recent-support-events.sh -H 24 -n 200 -o ./support-events.csv
```

容量・inode 使用率・SMART を確認します。

```bash
./support-scripts/test-disk-capacity.sh -w 80 -i 80 -o ./disk-capacity.json
```

セキュリティベースライン (sshd / firewall / fail2ban / 自動更新 / SELinux または AppArmor / auditd) を一括確認します。

```bash
./support-scripts/test-security-baseline.sh -o ./security-baseline.json
```

---

## cron / systemd timer 連携例

Linux 側で `test-disk-capacity.sh` を毎朝 08:00 に実行する例 (cron):

```bash
# crontab -e に追加
0 8 * * * /opt/support-scripts/test-disk-capacity.sh -o /var/log/support/disk-$(date +\%F).json
```

systemd timer で同じことをやる場合 (`/etc/systemd/system/disk-check.service` と `disk-check.timer`):

```ini
# disk-check.service
[Unit]
Description=Daily disk capacity baseline

[Service]
Type=oneshot
ExecStart=/opt/support-scripts/test-disk-capacity.sh -o /var/log/support/disk-%Y%m%d.json
```

```ini
# disk-check.timer
[Unit]
Description=Run disk-check daily

[Timer]
OnCalendar=*-*-* 08:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

---

## タスクスケジューラ連携例

`New-EndpointDailyReport.ps1` を毎朝自動実行する場合のタスク登録コマンド例です。実行アカウントや出力先は環境に合わせて調整してください。

```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\support-scripts\New-EndpointDailyReport.ps1`" -OutputDir `"C:\reports`""
$trigger = New-ScheduledTaskTrigger -Daily -At 08:00
Register-ScheduledTask -TaskName "Endpoint Daily Report" `
    -Action $action -Trigger $trigger -RunLevel Highest -Description "毎朝の端末ヘルスレポート"
```

## 必要モジュール / 前提

### Windows 系

| スクリプト | 必要なもの | 想定実行アカウント |
|---|---|---|
| 端末系 6本 | Windows PowerShell 5.1 以上 | 管理者権限（Get-WinEvent等） |
| `Get-StaleUserAccounts.ps1` | RSAT-AD-PowerShell（または DC 上） | ドメインユーザーの読み取り権限 |
| `Get-M365LicenseInventory.ps1` | Microsoft.Graph PowerShell SDK | User.Read.All / Organization.Read.All / Directory.Read.All |

### Linux 系

| スクリプト | 必要なもの | 想定実行アカウント |
|---|---|---|
| `collect-host-inventory.sh` | Bash 4+, `python3`, `iproute2` (`ip`) | 一般ユーザーで OK (パッケージ履歴は dpkg/rpm の読み取り権限が必要) |
| `test-network-triage.sh` | Bash 4+, `python3`, `iproute2`, `iputils-ping` | 一般ユーザーで OK |
| `get-recent-support-events.sh` | Bash 4+, `python3`, `systemd-journald` | 自分のログのみなら一般ユーザー、システム全体は `systemd-journal` グループ |
| `test-disk-capacity.sh` | Bash 4+, `python3`, GNU `coreutils` (df), 任意で `smartctl` | 一般ユーザーで OK (SMART は root) |
| `test-security-baseline.sh` | Bash 4+, `python3`, 任意で `ufw` / `firewalld` / `aa-status` / `getenforce` | sshd_config を完全に読むには root |

> いずれの Bash スクリプトも JSON 整形に `python3` を利用しています。Ubuntu / RHEL / Debian / Fedora には標準で含まれているため追加インストールは不要です。

## 作成で意識したこと

- 端末・サーバーの状態を、Windows と Linux で同じ思想・同じ出力フォーマット (JSON / CSV) で確認できること
- 出力をそのままチケットや引き継ぎ資料へ貼り付けやすくすること
- 削除、設定変更、サービス再起動などの破壊的操作を含めないこと
- 結果に「確認日時」「ホスト名」「判定」を含め、後から追えるようにすること
- 個別スクリプトと統合スクリプトを分け、単体実行と日次自動レポート (タスクスケジューラ / cron / systemd timer) の両方に対応すること

---

## 関連ドキュメント

- [PC キッティング手順書](../support-docs/pc-kitting-guide.md)
- [障害対応事例集](../support-docs/troubleshooting-case-studies.md)
- [ポートフォリオサイト > Skills](https://ns7jp.github.io/skills.html#support-cases)
