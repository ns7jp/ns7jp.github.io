# 島田則幸のポートフォリオサイト

![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-Vanilla-F7DF1E?logo=javascript&logoColor=black)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-success?logo=github)
[![Static site check](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml)
[![Infrastructure checks](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml)

🔗 **公開サイト**: https://ns7jp.github.io/

**Linuxサーバー構築・運用を第一志望**とし、Ubuntuサーバーの設計とAnsible構成コード、Prometheus・Grafana・Loki監視、障害注入から復旧までを、実装済み・実測済みの範囲を分けて公開しています。

## 開発体制について

このポートフォリオおよび主作品 [Server Monitor](https://github.com/ns7jp/server-monitor) は、README・設計書・Runbookの下書き／推敲に加え、Ansible role、Terraform module、CI workflow、test・Lab雛形の生成やデバッグにも Claude Code / Codex を使用しています。採用する構成の最終判断、機密情報のマスク、実測／未実測の判定、面談での説明は本人が担当します。証跡は本人手元WSL2、自動CI、AI支援セッションを区別し、未確認項目は `NOT RUN` として公開します。個人制作のため、人による第三者レビュー実績とは表現しません。

## 採用担当者向け: 最短レビュー順

| 順番 | 見るもの | 何が分かるか |
|---|---|---|
| 1 | [Project Brief](https://ns7jp.github.io/project-brief.html) | Linuxサーバー構築案件の目的、担当範囲、工程、設計判断、完了条件 |
| 2 | [Evidence Digest](https://ns7jp.github.io/evidence-demo.html) | 日時・環境・commit付きの実測結果、失敗、未実施範囲 |
| 3 | [Work Readiness](https://ns7jp.github.io/work-readiness.html) | 実務想定ケース、変更・報告の型、AI利用の境界、面談で再現できる内容、次の独立VM検証 |
| 4 | [1ページ履歴書](https://ns7jp.github.io/resume.html) | 経歴、資格、構築・運用スキル、主成果物、制作体制 |
| 5 | [2分15秒 証跡リプレイ](https://ns7jp.github.io/demo.html) | 2026年8月18日・19日の実測画面とD-1ログを時系列に再構成した閲覧用デモ |
| 6 | [Full-stack E2E 23/23](https://github.com/ns7jp/server-monitor/blob/4a292026b569dd1a522c0f2913b4ad40aeccebe7/docs/evidence/2026-08-22-full-stack-e2e.md) | runtime `7622a9d`、使い捨てUbuntu 24.04 runnerでの構築・冪等性・11 containers・Docker API proxy・復旧・3 volumes復元。main `4a292026`へ統合済み |
| 7 | [Git rollback rehearsal](https://github.com/ns7jp/server-monitor/actions/runs/32611251044) | PR #77途中commitの使い捨てUbuntu runnerで、candidate `84e1492`から前版`59aa88e`へのimmutable git SHA切り戻しをPASS。PR自体は後にmerge済みですが、merge後mainでの同一試験結果とは扱いません |

### 証跡の境界

- **作成・実装済み:** 要件、設計、パラメータ、構築コード、試験仕様、引き渡し、変更・ロールバック、実機検証手順
- **2026年8月17〜19日の履歴として実測:** Ansible 4 roles、監視9 services、Grafana実データ、Lokiログ、D-1復旧（RTO 13秒）、二セグメント通信障害
- **2026年8月22日のE2Eで実測（runtime `7622a9d`）:** 使い捨てUbuntu 24.04 runnerで23/23 PASS。`site.yml`初回一括適用、2回目`changed=0`、core 10 services + CI専用webhook sinkの計11 containers、Docker API proxyのGET成功・POST拒否・固有Nginx logのAlloy経由Loki到達、認証、runner内network/UFW、synthetic alertのlocal webhook FIRING/RESOLVED、D-1自動復旧（RTO 1秒）、別名3 volumesへのchecksum付きrestore。証跡docs `cf9419b`を含むPR #75はmain merge `4a292026`へ統合済み
- **2026年8月23日のCIで実測（PR #77途中commit / [Actions run 32611251044](https://github.com/ns7jp/server-monitor/actions/runs/32611251044)）:** disposable Ubuntu runnerの`/opt/server-monitor`へimmutable git SHAでcandidate `84e149254d463a8a27a4cabcd09efa4504d1b47e`を配備・検証後、前版`59aa88ed1c8ccb7ba188909f0e079b834e9126c7`へ切り戻してPASS。revision marker、running-container manifest、app container強制置換、stale file除去、loopback bind、Loki取り込みまで一致を確認。PR #77自体は後にmerge済みですが、このrunをmerge後mainで再実行した結果とは表現しません
- **2026年8月24日のAI支援セッション環境で実測:** B-1（qemu guest上のloop deviceによるLVM）、B-2 / B-3（Docker）、B-4（network namespace）を採録。B-4は環境制約により3項目を`SKIP-ENV`とし、本人手元で面談再実演を約束するのはWSL2 + Dockerで再現できるB-2 / B-3のみ
- **2026年8月25日のCIで実測:** AlmaLinux / Rocky 9向けMoleculeのEL9シナリオをコンテナ上で確認。実機AlmaLinuxホストへの適用証跡とは扱いません
- **NOT RUN:** persistent hostでのrollback・72時間連続稼働・host再起動後、Slack実配信、AWS `apply / destroy`・実費・Security Group/NACL、D-2、独立した管理端末・引き渡し対象host・組織DNSを含むnetwork検証、production traffic

E2E runnerにはDockerが事前導入済みだったため、最小OSからDockerを導入した実績とは表現しません。local webhookのsynthetic alert試験とD-1障害注入は別の検証であり、いずれもSlack実配信を示しません。runtime実測commit、結果を転記したdocs commit、main merge commitを分け、後続の文書変更をruntime検証へ読み替えません。

公開中の2分15秒映像は、2026年8月18日・19日の画面とRTO 13秒のD-1ログを再構成した証跡リプレイで、実操作の連続録画ではありません。2026年8月22日の実terminal `demo.cast`は期限付きActions artifactに保存され、公開サイト上の常設動画ではありません。実操作を収録する手順は[収録ガイド](https://github.com/ns7jp/server-monitor/blob/main/docs/demo-capture-guide.md)に分けています。

Support Toolkitの16ガイド+README、M365 JSON 5本+PowerShell 2本、DR計画、架空Postmortem、CIS自己マッピング、`infra-evidence/*.sample.txt`は、実運用実績・実測結果とは区別しています。

公共職業訓練（2025年10月〜2026年1月）で学んだ開発基礎を起点に、主作品の Server Monitor では設計、Ansible構築、試験、Prometheus監視、障害切り分け、復旧までを一つの案件として公開しています。

この README は、Web 初学者の方にも「このサイトが何を目的に作られているのか」「どのファイルが何を担当しているのか」「HTML / CSS / JavaScript がどう分担して動いているのか」が分かるように、できるだけ順を追って説明しています。各ファイルの詳しい役割、読む順番、処理の追い方は [CODE_WALKTHROUGH.md](./CODE_WALKTHROUGH.md) にまとめています。

---

## このサイトの目的

このサイトは、単に作品リンクを並べるだけではなく、**未経験からLinuxサーバー構築・運用を目指す過程で、設計値、構成コード、試験項目、実測証跡をどう分けて管理しているかを伝えるためのサイト**です。

閲覧者には、次のような情報が伝わることを目指しています。

| 見てほしいこと | 内容 |
|----------------|------|
| 人物像 | 製造・物流現場で培った正確性、改善意識、職業訓練で学んだ内容 |
| 第一志望 | Linuxサーバーの構築・運用 |
| スキル | Linuxサーバー設計・構築、Ansible、Docker、監視・ログ、障害切り分け、復旧、補助的な開発・運用支援 |
| 制作物 | Linux Server Build & Operations Lab、Evidence Digest、Server Monitor、補助成果・学習作品 |
| 学習姿勢 | トラブルに対して原因を切り分け、調査し、修正し、手順化した過程 |
| 実務準備 | 要件・設計・パラメータ・構築・試験・引き渡し・変更/rollback・実機検証手順 |
| 連絡先 | GitHub やメールなど、連絡・確認に使える情報 |

初学者向けに言い換えると、このポートフォリオは「サーバー構築案件をWeb上で説明する引き渡しファイル」のようなものです。成果物がある項目、実際に動かした項目、まだ動かしていない項目を分けて示します。

---

## このサイトの全体像

このサイトは「静的サイト」と呼ばれる種類の Web サイトです。静的サイトとは、サーバー側で PHP や Python が毎回ページを生成するのではなく、あらかじめ用意した HTML・CSS・JavaScript・画像ファイルをブラウザがそのまま読み込んで表示するサイトです。

このサイト本体では、データベースやログイン機能は使っていません。その代わり、ページ表示の速さ、構成の分かりやすさ、スマートフォン対応、作品への導線を重視しています。

| 技術 | このサイトでの役割 |
|------|------------------|
| HTML | 見出し、文章、画像、リンク、ナビゲーションなど、ページの骨組みを作る |
| CSS | 色、余白、文字サイズ、2カラム配置、カード表示、スマホ対応、アニメーションを担当 |
| JavaScript（Vanilla） | ハンバーガーメニュー、作品フィルター、スクロール処理などの動きを担当（`js/main.js` に集約、外部ライブラリ非依存） |
| 画像・動画ファイル | ヒーロー画像、プロフィール画像、作品スクリーンショット、証跡リプレイを表示 |
| GitHub Pages | 作成した静的ファイルをインターネット上に公開 |

ブラウザで `https://ns7jp.github.io/` を開くと、GitHub Pages がこのリポジトリの `index.html` を配信し、そこから CSS・JavaScript・画像ファイルが読み込まれます。

---

## 閲覧の流れ

初めて見る人が迷わず内容を追えるよう、サイト全体は次の流れで構成しています。

1. **Top**
   Linuxサーバー構築・運用という第一志望、Server Monitorの要約、2分15秒の証跡リプレイ、構成図、実測証跡への導線を最初に表示します。

2. **About Me**
   これまでの経歴、職業訓練で学んだこと、取得資格を確認できます。

3. **Project Brief / Evidence Digest**
   Linuxサーバー構築案件の全体像と、記録済みcommitの実測結果・未実施範囲を最短で確認できます。

4. **Server Build / Skills**
   要件から引き渡しまでの10番号付き成果物と、Linux・Ansible・Docker・監視・復旧のスキルを確認できます。Windows/M365と開発技術は補助成果として区別しています。

5. **Works**
   Linux Server Build & Operations LabとServer Monitorを先頭に、Support Toolkit、業務改善・開発学習作品を詳しく紹介しています。

6. **Contact**
   メールや GitHub など、連絡先情報をまとめています。

---

## ページ構成

| ページ | ファイル | 役割 |
|--------|----------|------|
| トップページ | `index.html` | サイトの入口。自己紹介・スキル・作品ページへの導線をまとめる |
| 案件概要 | `project-brief.html` | Linuxサーバー構築案件の目的、担当範囲、工程、設計判断、完了条件を説明する |
| 証跡ダイジェスト | `evidence-demo.html` | 最新E2Eと日付付き履歴、失敗、制約、NOT RUNを環境・commit付きで示す |
| 仕事の進め方 | `work-readiness.html` | 入口業務、実務想定ケース、変更管理、協働・AI利用の境界、面談デモ、独立VM検証計画 |
| 証跡リプレイ | `demo.html` | 2026年8月18日・19日の実測画面とD-1ログを再構成した2分15秒の閲覧用デモ |
| 自己紹介ページ | `me.html` | プロフィール、経歴、職業訓練、資格、**学習ロードマップ** を説明する |
| スキルページ | `skills.html` | Linux構築・監視・自動化を先頭に、補助スキルを証跡区分付きで見せる |
| Server Build Lab | `infra-lab.html` | 要件・設計・構築・試験・監視・復旧・引き渡しを工程順に見せる |
| Linux 運用Lab | `linux-lab.html` | systemd / journalctl / cron / SSH / logrotate / rsync の運用設計メモ |
| Cloud Network Lab | `cloud-lab.html` | AWS VPC / Subnet / Security Group / Terraform validate / Cost Guardrail を見せる |
| 作品ページ | `works.html` | Linux Server Build & Operations Labを先頭に、補助成果・学習作品を紹介 |
| 履歴書 | `resume.html` | A4 1pager。**想定業務 × 自分の備えマトリクス** と **学習ロードマップ** を含む |
| 連絡先ページ | `contact.html` | メールや GitHub などの連絡先を掲載する |
| Support Toolkit | `works.html#work-support-toolkit` | 16ガイド+README、確認スクリプト、想定ケースを補助成果としてまとめる |
| サポート文書 | `support-docs/` | 16ガイド+README。架空ケース・計画・テンプレートを含み、実運用実績ではない |
| 確認スクリプト | `support-scripts/` | PowerShell 9本 + bash 1本、純関数ライブラリとPesterテスト |
| Monitoring Stack（アーカイブ） | `monitoring-stack/` | Prometheus + Grafana + node_exporter + Loki + Promtail の docker-compose 一式。**2026-03 に Promtail が EOL となり、主作品側は Grafana Alloy へ移行済み**（[monitoring-stack/README.md](./monitoring-stack/README.md)）。現行構成は [server-monitor](https://github.com/ns7jp/server-monitor) |
| Ansible Playbook | `ansible/` | Ubuntu ベースライン冪等化 (SSH / UFW / fail2ban / auditd / unattended-upgrades) |
| 出力サンプル | `infra-evidence/` | 架空・未採録の`.sample.txt`。実測証跡としては扱わない |
| 本番化差分 | `production-readiness.md` | Lab から本番運用へ足す監視、通知、認証、秘密情報、バックアップ、変更管理 |

### `index.html`

サイトの顔となるトップページです。ファーストビューでは主作品の固定背景とキャッチコピーを表示し、閲覧者に「どんな人のポートフォリオか」を最初に伝えます。その下に採用担当者向けの要約、仕事の進め方、自己紹介・スキル・主成果のプレビューを配置しています。

初学者向けに見るポイントは、`header`、`nav`、`section` などの HTML タグでページを区切り、CSS のクラス名で見た目を調整している点です。

### `me.html`

自己紹介ページです。プロフィール、経歴タイムライン、取得資格などを掲載し、製造・物流の改善経験からLinuxサーバー構築・運用へキャリア移行する背景を補足します。

### `skills.html`

スキル一覧ページです。PC・IT基礎、トラブル切り分け、サーバー監視、ドキュメント整備、HTML / CSS、Python、PHP、JavaScript、データベースなどをカテゴリ別に整理しています。単に技術名を並べるのではなく、どのような制作物やサポート業務に活かせるかが分かるようにしています。

### `works.html`

作品紹介ページです。Linux Server Build & Operations LabとServer Monitorを最初に掲載し、その後にSupport Toolkitと開発学習作品をカード形式で並べています。フィルターボタンでカテゴリ別に絞り込めます。

各作品には、次の情報を載せています。

- 成果サマリー
- 作品スクリーンショット
- 作品の概要
- 使用技術
- 学習ポイント
- 具体的な使用例
- 制作中に起きたトラブルと解決方法
- デモサイトへのリンク
- GitHub リポジトリへのリンク

### `contact.html`

連絡先ページです。メールや GitHub など、外部から確認・連絡するための情報を掲載しています。

### `support-docs/`

補助成果として「手順書整備」「ナレッジ共有」「切り分けの型」を示す想定ドキュメントです。標準業務手順4本と障害対応3本を含みます。いずれも想定環境・架空ケースであり、実運用実績ではありません。

### `support-scripts/`

PowerShellで端末情報、ネットワーク疎通、イベントログ、ディスク容量を確認するサンプル集です。削除や設定変更を含まない読み取り中心の内容にし、問い合わせ受付後の一次確認やチケット添付を想定しています。

---

## フォルダ・ファイルの役割

```text
ns7jp.github.io/
├── CODE_WALKTHROUGH.md      ... 初学者向けの詳細なコード読解ガイド
├── index.html               ... トップページ
├── project-brief.html       ... Linuxサーバー構築案件の概要
├── evidence-demo.html       ... 実測・CI・NOT RUNを分けた証跡ダイジェスト
├── work-readiness.html      ... 実務想定ケース、制作体制、面談デモ、次の独立VM検証計画
├── demo.html                ... 2分15秒の証跡リプレイ（連続操作動画ではない）
├── me.html                  ... 自己紹介ページ（学習ロードマップ含む）
├── skills.html              ... スキル一覧ページ（Win / Linux 系を別カードに分割）
├── works.html               ... 作品一覧ページ（Infra カテゴリに Lab + Support Toolkit）
├── infra-lab.html           ... Linux Server Build & Operations Lab
├── linux-lab.html           ... Linux 一次運用Lab（systemd / journalctl / SSH / rsync）
├── cloud-lab.html           ... Cloud Network Lab（AWS VPC / Terraform）
├── production-readiness.md  ... Lab を本番化する際に足す運用観点
├── contact.html             ... 連絡先ページ
├── resume.html              ... A4 1ページ履歴書 + 想定業務マトリクス + 学習ロードマップ
├── 404.html                 ... 存在しないURLにアクセスされた時のカスタム表示
├── sitemap.xml              ... 検索エンジン向けサイトマップ
├── robots.txt               ... クローラー制御
├── favicon.ico              ... ブラウザのタブに表示される小さなアイコン
├── README.md                ... この説明ファイル
│
├── css/                     ... reset.css と style.css
├── js/                      ... サイト共通スクリプト（main.js、vanilla JS）と lightbox.js
│
├── support-docs/
│   ├── pc-kitting-guide.md                    ... PCキッティング手順書
│   ├── account-offboarding-guide.md           ... 退職者アカウント停止手順書
│   ├── shared-folder-access-management.md     ... 共有フォルダ権限管理手順書
│   ├── m365-license-management.md             ... Microsoft 365ライセンス管理手順書
│   ├── ad-m365-change-case.md                 ... AD / M365 変更作業ケース
│   ├── troubleshooting-case-studies.md        ... 障害対応事例集（10ケース）
│   ├── incident-response-playbook.md          ... 重大インシデント対応プレイブック
│   ├── malware-suspected-response.md          ... マルウェア感染疑い対応フロー
│   ├── network-triage-evidence.md             ... ★ L2-L7 ネットワーク切り分け証跡集
│   ├── postmortem-example.md                  ... 共有フォルダI/O飽和のPostmortem実例（架空）
│   ├── backup-restore-runbook.md              ... RTO/RPOと未実施DRドリル計画（Win VSS + Linux rsync）
│   ├── failover-runbook.md                    ... ★ AD/ファイル/DB/VIP/DNS の副系切替手順
│   ├── slo-error-budget.md                    ... SLO / Error Budget / バーンレート アラート
│   ├── ticket-taxonomy.md                     ... ITIL 4 区分の受付フローと記入テンプレ
│   ├── office-it-physical-layer.md            ... 物理層（ラック / LAN / UPS / AP / 複合機）
│   ├── interview-faq.md                       ... 面接 想定 FAQ（自答メモ）
│   └── m365-policy-examples/                  ... Intune / 条件付きアクセス / Defender ASR JSON
│       ├── README.md
│       ├── intune-windows-compliance-policy.json
│       ├── intune-windows-configuration-profile.json
│       ├── conditional-access-baseline.json
│       ├── conditional-access-break-glass.json
│       ├── defender-attack-surface-reduction.json
│       ├── Apply-IntunePolicy.ps1
│       └── Get-PolicyAssignmentReport.ps1
│
├── support-scripts/
│   ├── Collect-PcInventory.ps1      ... 端末情報収集
│   ├── Test-NetworkTriage.ps1       ... ネットワーク一次切り分け
│   ├── Get-RecentSupportEvents.ps1  ... 警告・エラーログ抽出
│   ├── Test-DiskCapacity.ps1        ... ディスク容量確認
│   ├── Test-SecurityBaseline.ps1    ... Defender/Firewall/BitLocker/Update確認
│   ├── New-EndpointDailyReport.ps1  ... 日次CSV/HTMLレポート
│   ├── Get-StaleUserAccounts.ps1    ... AD 休眠ユーザー抽出
│   ├── Get-M365LicenseInventory.ps1 ... M365 ライセンス棚卸し（Graph SDK）
│   ├── Test-DatabaseHealth.ps1      ... ★ SQL Server 一次ヘルス + スロークエリ + バックアップ最新性
│   ├── linux-triage.sh              ... Linux 一次切り分け bash
│   ├── lib/Triage-Lib.ps1           ... 純関数化された判定ロジック
│   └── tests/Triage-Lib.Tests.ps1   ... Pester ユニットテスト（25ケース）
│
├── monitoring-stack/        ... ★ アーカイブ（学習用の初期構成。現行は server-monitor）
│   ├── docker-compose.yml
│   ├── prometheus/prometheus.yml
│   ├── prometheus/alert.rules.yml
│   ├── loki/loki-config.yml             ★ Loki 設定
│   ├── promtail/promtail-config.yml     ★ Promtail 設定
│   └── grafana/provisioning/            （Prom + Loki データソース、2 ダッシュボード）
│
├── ansible/                 ... Linux ベースライン冪等化 playbook
│   ├── playbook.yml
│   ├── inventory.ini
│   ├── cis-benchmark-mapping.md  ... ★ CIS Ubuntu 22.04 L1 への対応マッピング
│   └── templates/sshd_config.j2
│
├── cloud-lab/               ... ★ AWS VPC / Security Group / Terraform validate
│   ├── README.md
│   └── terraform/
│
├── infra-evidence/          ... 実行証跡サンプルとCI検証観点
│   ├── README.md
│   ├── network-triage.sample.txt   ... ★ L2-L7 切り分けコマンドの出力サンプル
│   └── *.sample.txt
│
├── .github/workflows/
│   ├── static-check.yml     ... HTML 構造 + リンク + 画像バジェット
│   ├── pwsh-tests.yml       ... ★ Pester + PSScriptAnalyzer
│   └── infra-check.yml      ... ★ Docker Compose / promtool / Ansible / Terraform / bash 構文検証
│
└── image/                   ... ヒーロー画像・スクリーンショット
```

★ は本ブランチで追加した成果物。

初学者向けに説明すると、HTML ファイルは「ページごとの本文」、CSS フォルダは「見た目の設定」、JavaScript フォルダは「動きの設定」、image フォルダは「表示に使う画像置き場」です。

---

## 掲載成果物

| # | 作品名 | 主な技術 | 位置づけ | 内容 | リポジトリ |
|---|--------|----------|----------|------|------------|
| ① | Linux Server Build & Operations | Ubuntu / Ansible / Docker / Prometheus / Loki / Alloy | 主成果 | 要件から引き渡しまでの10番号付き成果物と、2026年8月22日のFull-stack E2E 23/23 | [ns7jp/server-monitor](https://github.com/ns7jp/server-monitor) |
| ② | サーバー監視ダッシュボード | Python / Flask / psutil / Chart.js | 主成果 | PCやサーバーの状態をブラウザで可視化する監視ツール | [ns7jp/server-monitor](https://github.com/ns7jp/server-monitor) |
| ③ | Support Toolkit | Markdown / PowerShell / bash | 補助成果 | 16ガイド+README、10確認スクリプト、M365サンプル、架空ケース | [support-docs](./support-docs/) / [support-scripts](./support-scripts/) |
| ④ | 定型文管理アプリ | Python / Flet | 補助スキル | よく使う文章を保存し、ワンクリックでコピーするデスクトップアプリ | [ns7jp/works](https://github.com/ns7jp/works) |
| ⑤ | 付箋アプリ | Python / Tkinter | 補助スキル | 複数の付箋を作成・保存・復元できるデスクトップアプリ | [ns7jp/works](https://github.com/ns7jp/works) |
| ⑥ | SNSアプリ「Pulse」 | PHP / SQLite / JavaScript | 学習作品 | 感情ムードを選んで投稿するSNS | [ns7jp/pulse](https://github.com/ns7jp/pulse) |
| ⑦ | 掲示板アプリ | PHP / MySQL | 学習作品 | ユーザー登録、投稿、返信ができる掲示板 | [ns7jp/post](https://github.com/ns7jp/post) |
| ⑧ | サンプル企業サイト | HTML / CSS / JavaScript | 学習作品 | 架空企業のレスポンシブ対応コーポレートサイト | [ns7jp/magic](https://github.com/ns7jp/magic) |

作品ページでは、単に「何を作ったか」だけでなく、「どんな場面で使えるか」「作る中で何に困ったか」「どう解決したか」も記載しています。これは、完成物だけでなく、問題解決の過程も伝えるためです。

---

## このサイト本体で使っている技術

### HTML5

ページの構造を作るために使用しています。たとえば、サイト上部は `header`、メニューは `nav`、主要領域は `main`、各まとまりは `section`、独立したカードは `article`、下部情報は `footer` のように、意味に合ったタグを使っています。

これにより、人間が読みやすいだけでなく、検索エンジンやスクリーンリーダーにもページ構造が伝わりやすくなります。

### CSS3

サイト全体の見た目を整えるために使用しています。`style.css` には、色、フォント、余白、カード表示、画像の大きさ、スマホ対応、アニメーションなどをまとめています。

特に意識した点は次の通りです。

- Flexbox と CSS Grid によるレイアウト
- スマートフォンでも見やすいレスポンシブ対応
- CSS 変数による色や値の管理
- ホバー時の変化やフェードインなどのアニメーション
- 作品カードやスキルカードの視認性

### JavaScript（Vanilla JS）

サイトに動きを加えるために使用しています。たとえば、スマホ用ハンバーガーメニュー、作品フィルター、スクロール時のヘッダー調整などです。

以前は jQuery と背景切替プラグインに依存していましたが、CDN読み込み失敗時の不具合を避けるため、`js/main.js` を外部ライブラリ非依存のvanilla JSへ書き直しました。現在のトップ背景は主作品の1枚に固定し、複数画像の自動取得と定期切替をなくしています。

### Font Awesome

メニューやボタンに使うアイコンを表示するために使用しています。文字だけのリンクよりも、アイコンがあることで「自己紹介」「作品」「連絡先」などの意味が直感的に伝わりやすくなります。

### Google Fonts

日本語と英字の表示を整えるために使用しています。読みやすさとポートフォリオらしい雰囲気を両立するため、本文用と見出し用のフォントを使い分けています。

### GitHub Pages

このサイトは GitHub Pages で公開しています。GitHub Pages は、GitHub リポジトリに置いた HTML / CSS / JavaScript をそのまま Web サイトとして公開できるサービスです。サーバー契約やデプロイ作業を簡略化できるため、静的ポートフォリオサイトの公開に向いています。

---

## 初学者向けの学習ポイント

このリポジトリを見ると、静的サイト制作の基本的な流れを確認できます。

1. **HTML でページ構造を作る**
   どの情報を見出しにするか、どこをセクションとして分けるかを考えます。

2. **CSS で見た目を整える**
   文字サイズ、色、余白、カード、横並び、スマホ対応などを調整します。

3. **JavaScript で動きを付ける**
   メニュー開閉やスライダーなど、ユーザー操作に応じた動きを実装します。

4. **画像を整理して配置する**
   `image/` フォルダに素材をまとめ、HTML から相対パスで読み込みます。

5. **GitHub Pages で公開する**
   リポジトリを GitHub に push し、Pages 設定を行うことで Web サイトとして公開します。

6. **README で説明する**
   作品の内容、ファイル構成、使っている技術を README にまとめることで、第三者が内容を理解しやすくなります。

---

## 制作で意識したこと

- **最初の数秒で内容が伝わること**
  トップページに自己紹介・作品・連絡先への導線を置き、必要な情報へすぐ移動できるようにしました。

- **スマートフォンでも見やすいこと**
  ハンバーガーメニューやレスポンシブレイアウトを使い、画面幅が狭くても閲覧しやすい構成にしています。

- **作品の背景まで伝えること**
  作品ページでは、完成画面だけでなく、使用例・学習ポイント・トラブル解決も書き、制作過程が伝わるようにしました。

- **コードの役割が追いやすいこと**
  HTML 内にはコメントを多めに入れ、初学者でも「この部分は何のためにあるのか」を読み取りやすくしています。

- **公開サイトとして最低限の情報を整えること**
  SEO 用の meta description、OGP、favicon、Google Fonts、Font Awesome など、公開サイトとして必要になる要素も入れています。

---

## ローカルで確認する方法

このサイトは静的サイトなので、基本的には `index.html` をブラウザで開けば表示できます。ただし、画像切り替えや一部の挙動を安定して確認するには、簡易ローカルサーバーで開く方法がおすすめです。

```bash
git clone https://github.com/ns7jp/ns7jp.github.io.git
cd ns7jp.github.io
python -m http.server 8000
```

起動後、ブラウザで以下を開きます。

```text
http://localhost:8000/
```

ローカルHTML構造・リンク・アクセシビリティ／SEOガードレールは次のコマンドで確認できます。

```bash
node scripts/check-html-structure.js
node scripts/check-static-links.js
node scripts/check-site-quality.js
node scripts/test-external-link-check.js
```

公開先やGitHubなど外部URLの応答確認は、ネットワークに接続できる環境で任意実行します。外部要因で不安定になり得るためCIの必須gateにはしていません。

```bash
node scripts/check-external-links.js
```

---

## 著者

**島田則幸（Noriyuki Shimada）**

- 📧 net7jp@gmail.com
- 📂 [作品リポジトリ一覧](https://github.com/ns7jp)
- 🌐 [ポートフォリオサイト](https://ns7jp.github.io/)

## ライセンス

ライセンス方針は [LICENSE](./LICENSE) に記載しています。コード例・手順書・PowerShellサンプルは学習・ポートフォリオ確認向けに公開し、プロフィール文・履歴書内容・人物写真などの個人情報を含む素材は無断利用を避ける方針です。

---

© 2026 Noriyuki Shimada. All rights reserved.
