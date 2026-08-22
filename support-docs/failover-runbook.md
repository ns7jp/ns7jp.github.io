# フェイルオーバー / 切り戻し Runbook

[Backup / Restore Runbook](./backup-restore-runbook.md) で RTO / RPO / DR ドリル**計画**まで定義しました。本ドキュメントはその次の段階、**実際に「主系を諦めて副系に切り替える」「切り戻す」手順**をサービス別にまとめたものです。

「障害時に手が動くか」が評価される領域なので、**判断基準 → 事前確認 → 切り替えコマンド → 検証 → 切り戻し** の 5 段階を毎章揃えています。コマンドはすべてサンプル値で、本番では台帳・パラメータシートと合わせて読み替えます。

> 公開ポートフォリオ用の架空ホスト名（ad01 / fs01 / sqldb01 / app01）と RFC 5737 のドキュメント用 CIDR を使用しています。

---

## 0. 切り替え判断の基準（共通）

「すぐ復旧できそうな障害でフェイルオーバーすると、戻すコストのほうが高い」状況がよくあります。**切り替える前に**以下のチェックを 3 分で済ませて、判断のブレを減らします。

| チェック | 「切り替える」側に振る目安 | 「現地で直す」側に振る目安 |
|---|---|---|
| 想定復旧時間 | RTO の **50% 以上**を使ってしまいそう | RTO の 20% 以内で直せる見込み |
| 影響範囲 | 全社 / 主要部署が完全停止 | 部分機能のみ / 一部ユーザー |
| 根本原因の見立て | ハードウェア / ストレージ / OS 起動失敗 | アプリ設定、特定プロセスのハング |
| データ整合性 | 主系のデータが破損疑いあり | データは健全、リソース不足だけ |
| 切り戻し可否 | 副系に切れば 24h 以上戻さなくて済む | 1〜2h で主系を直して戻したい |

> 迷ったら**1 段階上の責任者にエスカレーション**してから動きます。フェイルオーバーは「やる」より「やった事実を共有する」のほうが重要です。

### 切り替え時に必ず残す証跡

| 区分 | 内容 |
|---|---|
| 開始時刻 | UTC とローカル時刻を両方記録（ログ突き合わせ用） |
| 判断者 | 一次対応者 + 承認者の氏名 |
| 影響範囲 | サービス名 + 利用者 + 通知先 |
| 切替前後の状態 | コマンド出力、ヘルスチェック結果、画面ショット |
| 切戻し条件 | 「主系で X が再現しなくなり 30 分安定」など定量で |

これらは [チケット分類](./ticket-taxonomy.md) の **変更（Change）** または **重大インシデント** カテゴリで起票し、[Postmortem 例](./postmortem-example.md) と同じテンプレで事後共有します。

---

## 1. Active Directory DS — セカンダリ DC への切り替え

### 1.1 想定環境

```
ad01 (DC1, FSMO 全保有)   192.0.2.10  /  Primary
ad02 (DC2)                192.0.2.11  /  Secondary（レプリカ）
DNS                       上記 2 台で同一ゾーン保持
```

### 1.2 判断基準

| 状況 | 取る手 |
|---|---|
| ad01 が**応答するが時刻ずれ / DNS 不正**だけ | 切り替えず、復旧（時刻同期 / DNS 修復） |
| ad01 の OS は起動するが**サービスが上がらない** | **graceful な FSMO 移譲**（後述 1.3） |
| ad01 が**完全停止 / 復旧見込み数時間以上** | **FSMO seizure**（後述 1.4） |

### 1.3 graceful（ad01 が応答する場合）— FSMO 役割の移譲

PowerShell（ad02 上で実行）:

```powershell
# 1) 現在の FSMO 保有者を確認
netdom query fsmo

# 2) 5 役割をすべて ad02 へ移譲
Move-ADDirectoryServerOperationMasterRole `
    -Identity ad02 `
    -OperationMasterRole SchemaMaster, DomainNamingMaster, PDCEmulator, RIDMaster, InfrastructureMaster `
    -Confirm:$false

# 3) 結果確認
netdom query fsmo

# 4) クライアント側 DNS 設定で ad02 を優先になっているか確認
Resolve-DnsName _ldap._tcp.dc._msdcs.corp.local | Select-Object NameTarget
```

**検証**:

- `nltest /sc_query:corp.local` で対象 DC を表示
- 任意のクライアントで `gpupdate /force` が成功すること
- ファイルサーバー（fs01）上で認証が通り続けること

**切り戻し**: ad01 復旧後、同じ `Move-ADDirectoryServerOperationMasterRole` を ad01 を `-Identity` にして実行。レプリケーション完了（`repadmin /showrepl`）を待ってから順次戻す。

### 1.4 seizure（ad01 が完全停止 / 復旧不可）

> **重要**: seize は「強制奪取」です。実行後に ad01 を**そのままドメインに戻すと深刻な不整合**が起きるので、ad01 は OS 再構築前提で扱います。

```text
ntdsutil
> roles
> connections
>> connect to server ad02
>> quit
> seize schema master
> seize naming master
> seize PDC
> seize RID master
> seize infrastructure master
> quit
> quit
```

**事後処理**:

1. ad01 の AD オブジェクトを `ntdsutil metadata cleanup` で削除
2. DNS の `_msdcs` ゾーンから ad01 の SRV を削除
3. レプリケーション健全性を `repadmin /replsummary` で確認
4. 復旧した ad01 は別ホスト名でクリーンインストールしてからドメインに参加

### 1.5 RTO / RPO（目安）

- graceful FSMO 移譲: **15〜30 分**（影響軽微）
- seizure + メタデータクレンジング: **2〜4 時間**（事後の AD 整合性確認含む）

---

## 2. ファイルサーバー — 副 NAS への切り替え

### 2.1 想定環境

```
fs01 (Primary)   192.0.2.20    \\fs01\share         本番共有
fs02 (Secondary) 192.0.2.21    \\fs02\share-stby    DFS-R で同期
DFS Namespace    \\corp.local\share -> fs01 が ターゲット A、fs02 が ターゲット B
```

DFS Namespace + DFS Replication で副系に同期している前提です。**DFS Namespace が無い場合**は、共有名を変更してクライアントに通知する手間が増えます（後述）。

### 2.2 判断基準

| 状況 | 取る手 |
|---|---|
| fs01 のディスク 1 本故障（RAID 維持） | 切り替えず、現地交換 |
| fs01 のディスクアレイ全損 / OS 起動不可 | **DFS Namespace の優先ターゲット切替**（2.3） |
| fs01 が物理損壊 / 数日復旧不可 | **DFS Namespace 切替 + クライアント側でドライブ再マウント案内**（2.3 + 2.5） |

### 2.3 DFS Namespace 優先ターゲット切替（推奨）

```powershell
# 1) 現在のターゲット状態
Get-DfsnFolderTarget -Path '\\corp.local\share'
# Path  TargetPath          State    ReferralPriorityClass   ReferralPriorityRank
# ----  ----------          -----    --------------------    --------------------
# ...   \\fs01\share        Online   GlobalHigh              0
# ...   \\fs02\share-stby   Online   GlobalLow               0

# 2) fs01 を Offline、fs02 を High に格上げ
Set-DfsnFolderTarget -Path '\\corp.local\share' -TargetPath '\\fs01\share'      -State Offline
Set-DfsnFolderTarget -Path '\\corp.local\share' -TargetPath '\\fs02\share-stby' -ReferralPriorityClass GlobalHigh

# 3) クライアント側のキャッシュをクリア（必要な場合）
#    -> Win+R: dfsutil /pktflush  または再ログオン
```

**検証**:

- 任意の Windows クライアントから `\\corp.local\share` を開き、**fs02 側のファイルが見える**ことを確認
- `Get-SmbOpenFile -CimSession fs02` でアクセスが来ているか確認
- 書き込みテスト用のダミーファイルを置く（戻し時に消す）

### 2.4 DFS-R のレプリケーション健全性

切り替え**前**に確認しておくべきこと:

```powershell
# 同期遅延（バックログ）を確認。0 が理想
Get-DfsrBacklog `
    -GroupName 'fs-group' `
    -FolderName 'share' `
    -SourceComputerName fs01 `
    -DestinationComputerName fs02
```

バックログが大きい状態で切り替えると、**直近の変更が副系に未反映**で消える可能性があります。RPO の数値と照らして許容できるか判断します。

### 2.5 DFS Namespace が無い場合

各クライアントの設定に依存するため、原則として DFS NS の導入を本番化候補にしておきます。一時しのぎなら:

```powershell
# クライアント側で fs01 を fs02 にエイリアス（hosts）
# 192.0.2.20  fs01 fs01.corp.local    <-- 削除
# 192.0.2.21  fs01 fs01.corp.local    <-- 追加
notepad C:\Windows\System32\drivers\etc\hosts

# DNS 側で対応する場合は A レコードを fs01 -> 192.0.2.21 に書き換えて TTL を短縮
```

DNS で対応する場合は **TTL 短縮 → 切替 → 戻し** の手順（§5）に合流します。

### 2.6 切り戻し

1. fs01 復旧後、DFS-R の逆方向同期（fs02 → fs01）が完了するまで待つ（`Get-DfsrBacklog` が 0）
2. 業務時間外に DFS Namespace の優先ターゲットを元に戻す
3. クライアントを 1 台ずつアクセス確認

---

## 3. データベース — レプリカ昇格

### 3.1 SQL Server Always On 可用性グループ

```text
sqldb01-p (Primary)   192.0.2.30
sqldb01-s (Secondary) 192.0.2.31
AG 名: AG_BIZ          リスナー: sqldb01-lsnr -> 自動で primary を指す
```

#### 同期コミットの自動フェイルオーバー（クォーラム健全前提）

```sql
-- リスナー経由なので、アプリは接続文字列の変更不要で副系に流れる。
-- 状況確認:
SELECT
    ar.replica_server_name,
    ars.role_desc,
    ars.synchronization_health_desc,
    ars.operational_state_desc
FROM sys.dm_hadr_availability_replica_states ars
JOIN sys.availability_replicas ar
  ON ar.replica_id = ars.replica_id
WHERE ar.group_id = (SELECT group_id FROM sys.availability_groups WHERE name='AG_BIZ');
```

#### 手動フェイルオーバー（メンテナンス時）

```sql
-- secondary 側で実行
ALTER AVAILABILITY GROUP AG_BIZ FAILOVER;
```

#### 切り戻し

旧 primary が同期完了 (`SYNCHRONIZED`) になってから、再度 `FAILOVER` を実行。

### 3.2 PostgreSQL ストリーミングレプリケーション

```text
pg01 (Primary)   192.0.2.40
pg02 (Standby)   192.0.2.41    streaming replication
```

#### 昇格コマンド（pg02 上で）

```bash
# 1) 主系の死活を確認
psql -h 192.0.2.40 -U replica -c 'SELECT 1' || echo "primary unreachable"

# 2) 副系の遅延を確認（バイト単位）
sudo -u postgres psql -c 'SELECT pg_wal_lsn_diff(pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn());'

# 3) 昇格
sudo -u postgres pg_ctl promote -D /var/lib/postgresql/16/main

# 4) アプリの接続先を pg02 へ切り替え（DNS or HAProxy or アプリ設定）
```

#### 切り戻し（旧 primary の再構成）

```bash
# 旧 primary を新 primary（昇格後の pg02）からベースバックアップで作り直す
sudo systemctl stop postgresql
sudo rm -rf /var/lib/postgresql/16/main/*
sudo -u postgres pg_basebackup \
    -h 192.0.2.41 -U replica \
    -D /var/lib/postgresql/16/main -P -R
sudo systemctl start postgresql
```

`-R` オプションで `standby.signal` と接続情報が自動生成されます。

### 3.3 RTO / RPO

| 方式 | RTO | RPO | 注意 |
|---|---|---|---|
| SQL Server AG（同期コミット + 自動 FO） | < 30 秒 | 0 | クォーラム健全とリスナー設定が前提 |
| SQL Server AG（手動 FO） | 5〜15 分 | 0 | データ整合性確認時間込み |
| PostgreSQL Streaming（手動昇格） | 10〜30 分 | < 5 秒（遅延次第） | 旧 primary は再構成が必須 |

---

## 4. VIP / ロードバランサ — Keepalived (VRRP)

### 4.1 想定環境

```text
lb01 (Master)    192.0.2.60     keepalived priority 150
lb02 (Backup)    192.0.2.61     keepalived priority 100
VIP              192.0.2.65     利用者はここに接続
```

### 4.2 自動切替の確認

```bash
# lb01 側
$ ip -br addr show eth0
eth0    UP    192.0.2.60/24 192.0.2.65/32

# lb01 を停止 / メンテモードに
$ sudo systemctl stop keepalived

# lb02 側に VIP が移ったか
$ ip -br addr show eth0
eth0    UP    192.0.2.61/24 192.0.2.65/32

# クライアントから VIP への疎通
$ ping -c 3 192.0.2.65
```

### 4.3 ARP / MAC 更新の確認

VRRP の VIP は **MAC アドレスが切替時に変わる** ため、上位スイッチや L3 機器の ARP キャッシュ更新が遅いと数秒〜30 秒の通信断が発生します。`arping -U` で更新を促す設定が keepalived 標準で入っていることを確認します:

```bash
$ grep -E 'garp_master|advert' /etc/keepalived/keepalived.conf
    garp_master_delay 1
    garp_master_repeat 2
    advert_int 1
```

### 4.4 切り戻し

```bash
# lb01 を再起動 → priority が高いので自動で master に戻る
sudo systemctl start keepalived
```

priority 制御に頼らず**手動で戻したい**場合は、`nopreempt` を設定して preempt を無効化し、業務時間外に明示的に切り戻します。

---

## 5. DNS 切替 — TTL 短縮 → 切替 → 戻し

データベースやアプリ側の HA 機構が無いとき、最終手段として **DNS A レコードを書き換えて副系に振る**運用があります。「いつでも使える」反面、TTL の扱いを誤ると数時間〜1日影響が残ります。

### 5.1 順序

```text
[ T-24h ]  TTL を 86400 → 300 に短縮 (このコミットだけ先に流す)
   |
   |  24h 経過 (旧 TTL のキャッシュが世間から消える)
   |
[ T-0  ]  A レコードを 192.0.2.20 → 192.0.2.21 に変更
   |
[ T+1h ]  クライアント側で実 IP を確認 (PowerShell: Resolve-DnsName fs01.example.com)
   |
[ T+24h ] 安定確認後、TTL を 300 → 86400 に戻す
```

### 5.2 Route 53 の例（AWS）

```bash
# 1) TTL を短縮（json は別ファイル）
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890 \
    --change-batch file://short-ttl.json

# 2) 24h 後にレコード本体を切替
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890 \
    --change-batch file://failover-to-secondary.json
```

### 5.3 オンプレ AD DNS の例

```powershell
# TTL は -TimeToLive で指定 (秒数)
Set-DnsServerResourceRecord `
    -ZoneName 'corp.local' `
    -OldInputObject $old `
    -NewInputObject ($old | ForEach-Object {
        $_.TimeToLive = [TimeSpan]::FromMinutes(5); $_
    })
```

### 5.4 注意点

- 一部のリゾルバ（家庭用ルータ、古い社内 DNS）は**TTL を無視して長く保持**する。完全反映に丸一日見るのが安全
- レコード変更直後は `dig +trace example.com` で**世界中から見える値**、`dig @192.0.2.10 example.com` で**社内 DNS から見える値**の両方を確認

---

## 6. DR ドリル計画への接続

[Backup / Restore Runbook §10](./backup-restore-runbook.md) の年次 DR ドリルでは、本ドキュメントの手順を**実行可能性ベース**で年 1 回検証します。

| ドリル項目 | 本ドキュメントの章 | 想定所要時間 | 合格基準 |
|---|---|---|---|
| AD FSMO 移譲 | §1.3 | 30 分 | クライアント認証が継続 |
| ファイルサーバー DFS NS 切替 | §2.3 | 45 分 | 業務ユーザーがファイル開け、書き込みできる |
| DB レプリカ昇格 | §3 | 60 分 | アプリの読み書きが副系で動作 |
| VIP フェイルオーバー | §4 | 15 分 | クライアントの実通信断 30 秒以内 |
| DNS 切替 | §5 | 24 時間（観測） | TTL 短縮後の伝播完了 |

ドリル後の Postmortem は [postmortem-example.md](./postmortem-example.md) と同じ書式で起票します。

---

## 関連

- [Backup / Restore Runbook](./backup-restore-runbook.md) — 取得・復元手順、RTO / RPO 表、DR ドリル計画
- [障害対応事例集](./troubleshooting-case-studies.md) — 切り替え判断の補助情報
- [チケット分類](./ticket-taxonomy.md) — 変更 / 重大インシデント の起票テンプレ
- [架空Postmortemサンプル](./postmortem-example.md) — ドリル後の振り返り書式
- [Production Readiness](../production-readiness.md) — DFS NS / Route 53 / Keepalived 等の本番導入差分
- [Network Triage Evidence](./network-triage-evidence.md) — 切替後の疎通確認に使う一次切り分け
