# CIS Benchmark 対応マッピング — Ubuntu 22.04 LTS

[Ansible Playbook (`playbook.yml`)](./playbook.yml) で実施しているハードニング項目を、**Center for Internet Security (CIS) Benchmarks** の管理項目番号に紐付けた対応表です。

「Linux を強化しました」では監査側に伝わりにくいため、**業界標準のどの項目に対応しているか**を明示することで、社内 SE・運用受託・監査対応の文脈で会話できる状態にしています。

> 参照基準: **CIS Ubuntu Linux 22.04 LTS Benchmark v1.0.0**（2022-09 公開、執筆時点で最新の安定版）
> 対象スコープ: **Level 1 — Server** プロファイル（過度な機能停止を伴わない最低限ライン）
> 評価対象: 本リポジトリの `ansible/playbook.yml`（21 タスク + 4 ハンドラ）

CIS Benchmark 本体は[CIS の Web サイト](https://www.cisecurity.org/benchmark/ubuntu_linux)で無償ダウンロード可能（要登録）。各項目の正確な原文と Audit / Remediation 手順は本家を参照してください。本ドキュメントは「どの Ansible タスクがどの CIS 項目に対応するか」のマッピングのみを目的とします。

---

## 0. 達成度サマリ

| セクション | 該当章 | 充足 | 部分 | 未対応 | Level 1 達成率 |
|---|---|---|---|---|---|
| 1. Initial Setup | §1 | 3 | 1 | 4 | 約 50% |
| 2. Services | §2 | 1 | 0 | 1 | — |
| 3. Network Configuration | §3 | 2 | 0 | 2 | 約 50% |
| 4. Logging and Auditing | §4 | 4 | 1 | 1 | 約 75% |
| 5. Access, Authentication and Authorization | §5 | 8 | 2 | 1 | 約 80% |
| 6. System Maintenance | §6 | 1 | 0 | 2 | — |
| **計** | — | **19** | **4** | **11** | **約 65% (Level 1 主要項目ベース)** |

> 「主要項目」とは、CIS Benchmark で **L1 / Automated** にマークされている統制のうち、本 playbook のスコープ（初期構築時のベースライン）と重なる範囲を指します。kernel module の無効化、ファイルシステム個別マウントオプションなど、**運用想定で意図的に外した項目**は未対応に分類しています。

---

## 1. Initial Setup

### 1.1 Filesystem Configuration

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 1.1.1.x | `cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, `udf`, `usb-storage` などのカーネルモジュール無効化 | ✗ | **未対応**（Lab 用途のため業務影響を避けて省略。本番では `modprobe.d` で disable） |
| 1.1.2 〜 1.1.7 | `/tmp`, `/var`, `/var/tmp`, `/var/log`, `/var/log/audit`, `/home`, `/dev/shm` を別マウントし `nodev`, `nosuid`, `noexec` を付与 | ✗ | **未対応**（パーティション設計はインストール時の選択。playbook 外） |

### 1.3 Filesystem Integrity

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 1.3.1 | AIDE のインストール | ✗ | **未対応**（auditd で代替。本番では AIDE を追加候補） |

### 1.4 Secure Boot Settings

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 1.4.1 | GRUB のオーナーが root | △ | **OS デフォルト依存**（Ansible では明示制御していない） |
| 1.4.2 | シングルユーザーモードに認証 | ✗ | **未対応** |

### 1.5 Additional Process Hardening

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 1.5.1 | core dump 制限 | ✗ | **未対応**（本番化候補） |
| 1.5.2 | ASLR (`kernel.randomize_va_space=2`) | ◯ | **OS デフォルトで有効**（Ubuntu 22.04 標準値） |

### 1.6 Mandatory Access Control

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 1.6.1.x | AppArmor 有効化 | ◯ | **OS デフォルトで有効**（Ubuntu 22.04 で `apparmor` がデフォルト起動） |

### 1.7 / 1.8 Warning Banners / GDM

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 1.7.x | `/etc/issue.net` バナー設定 | ◯ | `templates/sshd_config.j2` で `Banner /etc/issue.net` を指定（バナー本文は別途配備が必要） |
| 1.8.x | GDM 関連 | n/a | **対象外**（サーバープロファイルなので GUI 無し） |

---

## 2. Services

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 2.1.x | inetd, NIS, RPC など**不要サービス**の停止 | ✗ | **playbook では未操作**（Ubuntu Server 標準で未インストール。明示停止は本番化候補） |
| 2.2.x | サービス時刻同期（chrony / systemd-timesyncd） | ◯ | playbook §7 で **`systemd-timesyncd` を enable + start** |
| 2.3.x | サービスクライアント（telnet / rsh など）の削除 | ✗ | **未対応**（Ubuntu Server 標準で未インストール） |

---

## 3. Network Configuration

### 3.1 Disable unused network protocols

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 3.1.1 | IPv6 を不要なら無効 | ✗ | **未対応**（IPv6 は有効のまま。明示停止は環境次第） |
| 3.1.2 | DCCP, SCTP, RDS, TIPC モジュール無効化 | ✗ | **未対応**（本番化候補） |

### 3.4 Configure Firewall

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 3.4.1.1 | UFW がインストールされている | ◯ | `pre_tasks` の必須パッケージで `ufw` をインストール |
| 3.4.1.2 | iptables-persistent が両立していない | ◯ | **未インストール**（UFW のみ採用） |
| 3.4.2.1 | UFW デフォルト拒否ポリシー | ◯ | playbook §4 で **`incoming: deny`, `outgoing: allow`** を設定 |
| 3.4.2.x | 必要ポートのみ許可 | ◯ | playbook §4 で **22 / 80 / 443 のみ allow** |
| 3.4.2.x | UFW を有効化 | ◯ | playbook §4 で **`state: enabled, logging: low`** |

---

## 4. Logging and Auditing

### 4.1 Configure System Accounting (auditd)

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 4.1.1.1 | auditd のインストール | ◯ | `pre_tasks` の必須パッケージで `auditd` |
| 4.1.1.2 | auditd の自動起動 | ◯ | playbook §6 で **`enabled: true, state: started`** |
| 4.1.2.x | audit ログのサイズ / リテンション | △ | **デフォルト値**を使用（明示設定は本番化候補） |
| 4.1.3 | ログイン / sudo / passwd / shadow / sudoers の監査 | ◯ | playbook §6 の `99-baseline.rules` で `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`, `/var/log/auth.log` を watch + `execve` （euid=0）を記録 |

### 4.2 Configure Logging (journald / rsyslog)

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 4.2.1.x | journald を **persistent** に | ◯ | playbook §6 で **`Storage=persistent`** を `journald.conf` に書き込み + `restart journald` |
| 4.2.2.x | rsyslog のリモート送信 | ✗ | **未対応**（中央集約は [Loki + Promtail](../monitoring-stack/) で代替。SIEM 連携は本番化候補） |
| 4.2.3 | logrotate のパーミッション | ◯ | `pre_tasks` で `logrotate` をインストール（OS デフォルト設定を使用） |

---

## 5. Access, Authentication and Authorization

### 5.1 Configure time-based job schedulers (cron)

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 5.1.x | `/etc/crontab`, `/etc/cron.*` のパーミッション 600 / 700 | △ | **OS デフォルト依存** |
| 5.1.8 | `cron.allow` / `at.allow` の制限 | ✗ | **未対応** |

### 5.2 Configure SSH Server

| CIS # | 項目 | 対応 | sshd_config.j2 / playbook |
|---|---|---|---|
| 5.2.1 | `/etc/ssh/sshd_config` の所有者 / モード | ◯ | playbook §3 で **owner=root, mode=0644** |
| 5.2.2 | sshd の構文検証 | ◯ | playbook §3 で **`validate: /usr/sbin/sshd -t -f %s`** |
| 5.2.3 | `Protocol 2` のみ | ◯ | **OpenSSH 7.x 以降は Protocol 1 廃止**（sshd_config.j2 で明示せず） |
| 5.2.4 | `LogLevel VERBOSE` 以上 | ◯ | sshd_config.j2 で **`LogLevel VERBOSE`** |
| 5.2.5 | `X11Forwarding no` | ◯ | sshd_config.j2 で **`X11Forwarding no`** |
| 5.2.6 | `MaxAuthTries` を 4 以下 | ◯ | sshd_config.j2 で **`MaxAuthTries 3`** |
| 5.2.7 | `IgnoreRhosts yes` | △ | **OpenSSH デフォルト yes** |
| 5.2.8 | `HostbasedAuthentication no` | △ | **OpenSSH デフォルト no** |
| 5.2.9 | `PermitRootLogin no` | ◯ | sshd_config.j2 で **`PermitRootLogin no`** |
| 5.2.10 | `PermitEmptyPasswords no` | ◯ | sshd_config.j2 で **`PermitEmptyPasswords no`** |
| 5.2.11 | `PermitUserEnvironment no` | ✗ | **未明示**（sshd_config.j2 に追加候補） |
| 5.2.13 | 暗号アルゴリズム / MAC / KexAlgorithms の制限 | ✗ | **未対応**（OpenSSH デフォルト依存。本番化候補） |
| 5.2.14 | `ClientAliveInterval` / `ClientAliveCountMax` | ◯ | sshd_config.j2 で **300 / 2** |
| 5.2.15 | `LoginGraceTime` を 60 秒以下 | ◯ | sshd_config.j2 で **30** |
| 5.2.17 | `Banner` の設定 | ◯ | sshd_config.j2 で **`Banner /etc/issue.net`** |
| 5.2.18 | `MaxSessions` を 10 以下 | ◯ | sshd_config.j2 で **4** |
| — | `PasswordAuthentication no` | ◯ | sshd_config.j2 で **`PasswordAuthentication no`**（鍵認証のみ） |

### 5.3 Configure PAM (password complexity / lockout)

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 5.3.1 | `libpam-pwquality` のインストール | ✗ | **未対応**（鍵認証のみ運用で省略。パスワード認証併用なら必須） |
| 5.3.2 | 連続失敗時のアカウントロックアウト | ✗ | **未対応**（fail2ban で代替） |

### 5.4 User Accounts and Environment

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 5.4.1 | パスワード有効期限 PASS_MAX_DAYS | ✗ | **未対応** |
| 5.4.2 | 不要なシステムアカウントのロック | ✗ | **未対応** |
| 5.4.3 | デフォルトグループ 0 のアカウントは root のみ | △ | **OS デフォルト依存** |
| 5.4.4 | デフォルト umask 027 | ✗ | **未対応**（本番化候補） |
| 5.4.5 | シェルタイムアウト TMOUT | ✗ | **未対応** |

---

## 6. System Maintenance

### 6.1 System File Permissions

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 6.1.x | `/etc/passwd`, `/etc/shadow`, `/etc/group` などのオーナー / パーミッション | △ | **OS デフォルト依存**（auditd で変更検知のみ実施） |

### 6.2 User and Group Settings

| CIS # | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| 6.2.x | 重複 UID / GID / ユーザー名 / グループ名のチェック | ✗ | **未対応**（変更検知は監視で代替） |

### + 自動更新

| 追加 | 項目 | 対応 | Ansible タスク / 備考 |
|---|---|---|---|
| — | `unattended-upgrades` で**セキュリティパッチを自動適用** | ◯ | playbook §1 で **`/etc/apt/apt.conf.d/20auto-upgrades`** を書き込み |

> CIS Benchmark には「自動更新を有効にする」項目は**直接は含まれていません**（パッチ運用は組織判断とされる）。ただし [JPCERT/CC のセキュアな初期設定ガイド](https://www.jpcert.or.jp/) や [NIST SP 800-53 SI-2](https://csrc.nist.gov/) では推奨されているため、Lab では明示的に有効化しています。

---

## 7. Level 2 への差分（参考）

Level 2 は「**機密性・可用性に厳密な環境向け**」のプロファイルで、業務影響と引き換えに防御を強める項目群です。Lab では未対応ですが、規制対象環境（医療 / 金融 / 自治体）への展開を視野に入れる場合は以下が必要になります。

| 領域 | Level 2 で追加される代表項目 |
|---|---|
| Filesystem | `/tmp`, `/var/tmp`, `/var/log` 等の**独立パーティション化** + `nodev/nosuid/noexec` |
| Kernel | DCCP / SCTP / RDS / TIPC / `usb-storage` 等のモジュール完全無効化 |
| Network | IPv6 完全無効、`ICMP redirect`, `Source Route` の無効化 |
| SSH | 暗号アルゴリズム / MAC / KexAlgorithms の**ホワイトリスト指定** |
| Audit | 監査ログの**リモート送信** + 改ざん検知 |
| AIDE | ファイル完全性チェックの定期実行 |
| Password | パスワード複雑度（最低長 14、英大小数記号混在）、履歴 5 世代 |

---

## 8. 自動監査の参考

CIS Benchmark への準拠**チェック**は、以下のような OSS ツールで自動化できます。本 playbook の対応範囲を超える領域です（本番化候補）:

| ツール | 用途 | コマンド例 |
|---|---|---|
| [**OpenSCAP**](https://www.open-scap.org/) | SCAP コンテンツに基づく Lv1/Lv2 監査レポート | `oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level1_server ...` |
| [**Lynis**](https://cisofy.com/lynis/) | 軽量 OSS の総合監査（CIS だけでなく PCI/HIPAA も） | `sudo lynis audit system` |
| [**Chef InSpec**](https://www.inspec.io/) | プロファイルベースの監査（CIS Benchmark プロファイル公式提供） | `inspec exec cis-ubuntu-22.04-benchmark` |

`infra-check.yml` への追加候補として、`Lynis` の実行を `--quiet --report-file` モードで回し、`hardening index` を Markdown に貼り付ける運用が現実的です。

---

## 9. 凡例

| 記号 | 意味 |
|---|---|
| ◯ | playbook で**明示的に対応** |
| △ | **OS デフォルト**で要件を満たす（playbook では再宣言していない） |
| ✗ | **未対応**（playbook のスコープ外。本番化候補） |
| n/a | サーバープロファイル対象外（GUI 等） |

---

## 関連

- [`playbook.yml`](./playbook.yml) — 本マッピングの対象 Ansible Playbook
- [`templates/sshd_config.j2`](./templates/sshd_config.j2) — SSH ハードニング設定
- [Production Readiness](../production-readiness.md) — 「本番化で足すもの」での Vault / SSO / SIEM
- [Linux Operation Lab](../linux-lab.html) — systemd / journalctl / SSH の運用設計メモ
- [Infra Evidence](../infra-evidence/) — Ansible syntax-check / ansible-lint の検証証跡
