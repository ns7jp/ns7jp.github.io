# 島田則幸のポートフォリオサイト

![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-Vanilla-F7DF1E?logo=javascript&logoColor=black)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-success?logo=github)
[![Static site check](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml)
[![Infrastructure checks](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml)

🔗 **公開サイト**: https://ns7jp.github.io/

**Linuxサーバー構築・運用を第一志望**とし、Ubuntuサーバーの設計とAnsible構成コード、Prometheus・Grafana・Loki監視、障害注入から復旧までを、実装済み・実測済みの範囲を分けて公開しています。

## まず見る3点

| 見るもの | 状態・確認できること |
|---|---|
| [2分15秒デモ](https://ns7jp.github.io/demo.html) | 2026年8月18日・19日の実測スクリーンショットとD-1復旧ログを再構成した証跡リプレイ |
| [構成図](https://github.com/ns7jp/server-monitor/blob/main/docs/architecture.md#構成図) | Nginx、Flask、Prometheus、Grafana、Alertmanager、Lokiの役割と接続関係 |
| [実測証跡](https://github.com/ns7jp/server-monitor/blob/main/docs/evidence/README.md) | 実測済み、未実測（NOT RUN）、確認できる範囲の境界 |

## 主作品: Server Monitor

[Server Monitor](https://github.com/ns7jp/server-monitor) は、設計、構成管理、監視、試験、障害対応、引き渡しを一つの案件としてまとめたLinuxインフラ構築ラボです。

> **映像の位置付け:** この映像は実操作の連続録画ではありません。2026年8月18日・19日に保存した実測スクリーンショットとD-1復旧ログを、閲覧用に時系列で再構成したリプレイです。実操作を収録する手順は[収録ガイド](https://github.com/ns7jp/server-monitor/blob/main/docs/demo-capture-guide.md)に分けています。

- **設計・構成**: 基本・詳細設計、パラメータ、Ansibleロール、Docker Compose、試験・引き渡し資料
- **実測済み**: Ansible 4ロールのMolecule試験、Linux上の監視スタック起動、D-1復旧演習（RTO 13秒）、二セグメント障害ラボ
- **未採録**: 新規VMへの`site.yml`適用、実VMのUFW・ネットワーク確認、バックアップ復元、AWS適用

[構築案件パック](https://github.com/ns7jp/server-monitor/tree/main/docs/build-package) / [主作品の詳細](https://ns7jp.github.io/works.html#work-monitor) / [1ページ履歴書](https://ns7jp.github.io/resume.html)

## 補助成果

主作品を確認した後の二次導線として、[Linux Operation Lab](https://ns7jp.github.io/linux-lab.html)、[Windows / M365 / AD・PowerShellのSupport Toolkit](https://ns7jp.github.io/works.html#work-support-toolkit)、[Cloud Lab](https://ns7jp.github.io/cloud-lab.html)、Python・PHP・Web制作物を掲載しています。

## 開発体制について

設計方針・構成・検証観点は自分で立て、Claude Code / CodexなどのAIコーディングエージェントと協働して実装・デバッグしています。採用する成果物は実機またはCIで確認し、内容を説明できる状態にして公開します。コミット履歴とPRもGitHub上で確認できます。

サイト実装の詳しい読み方は [CODE_WALKTHROUGH.md](./CODE_WALKTHROUGH.md) に分離しています。

---

## このサイトの目的

このサイトは、単に作品リンクを並べるだけではなく、**未経験からLinuxサーバー構築・運用を目指す過程で、設計値、構成コード、試験項目、実測証跡をどう分けて管理しているかを伝えるためのサイト**です。

閲覧者には、次のような情報が伝わることを目指しています。

| 見てほしいこと | 内容 |
|----------------|------|
| 人物像 | 製造・物流現場で培った正確性、改善意識、職業訓練で学んだ内容 |
| 第一志望 | Linuxサーバーの構築・運用 |
| 主作品 | Server Monitorの設計、Ansible構成、監視、試験、障害復旧 |
| 学習姿勢 | 実装と実測を分け、トラブルを切り分け、修正し、証跡化した過程 |
| 補助成果 | Windows / M365 / AD、PowerShell、Cloud、開発作品 |
| 連絡先 | GitHub やメールなど、連絡・確認に使える情報 |

初学者向けに言い換えると、このポートフォリオは「Linuxサーバー構築・運用の学習成果をWeb上で見せる履歴書」です。設計書だけでなく、構成コード、試験結果、障害対応ログを結び付けて示しています。

---

## このサイトの全体像

このサイトは「静的サイト」と呼ばれる種類の Web サイトです。静的サイトとは、サーバー側で PHP や Python が毎回ページを生成するのではなく、あらかじめ用意した HTML・CSS・JavaScript・画像ファイルをブラウザがそのまま読み込んで表示するサイトです。

このサイト本体では、データベースやログイン機能は使っていません。その代わり、ページ表示の速さ、構成の分かりやすさ、スマートフォン対応、作品への導線を重視しています。

| 技術 | このサイトでの役割 |
|------|------------------|
| HTML | 見出し、文章、画像、リンク、ナビゲーションなど、ページの骨組みを作る |
| CSS | 色、余白、文字サイズ、2カラム配置、カード表示、スマホ対応、アニメーションを担当 |
| JavaScript（Vanilla） | ローダー、ハンバーガーメニュー、背景画像切り替え、スクロール演出などの動きを担当（`js/main.js` に集約、外部ライブラリ非依存） |
| 画像ファイル | ヒーロー画像、プロフィール画像、作品スクリーンショットを表示 |
| GitHub Pages | 作成した静的ファイルをインターネット上に公開 |

ブラウザで `https://ns7jp.github.io/` を開くと、GitHub Pages がこのリポジトリの `index.html` を配信し、そこから CSS・JavaScript・画像ファイルが読み込まれます。

---

## 閲覧の流れ

初めて見る人が迷わず内容を追えるよう、サイト全体は次の流れで構成しています。

1. **Top**
   Linuxサーバー構築・運用という第一志望、Server Monitorの要約、3分デモの公開状況、構成図、実測証跡への導線を最初に表示します。

2. **About Me**
   これまでの経歴、職業訓練で学んだこと、取得資格を確認できます。

3. **Skills**
   Linux、Ansible、Docker、監視、ネットワーク切り分けを先に示し、Windows / M365 / ADやPowerShellは補助領域として整理しています。

4. **Infra Lab**
   Linux Lab、監視スタック、Ansibleの補足資料へ進めます。Windows / M365 / AD想定の運用設計やCloud Labも二次導線から確認できます。

5. **Works**
   Server Monitorを先頭に表示し、その後にSupport Toolkitと開発作品を補助成果として紹介しています。

6. **Contact**
   メールや GitHub など、連絡先情報をまとめています。

---

## ページ構成

| ページ | ファイル | 役割 |
|--------|----------|------|
| トップページ | `index.html` | 第一志望、Server Monitor、構成図、実測証跡を最優先で示す |
| 自己紹介ページ | `me.html` | プロフィール、経歴、職業訓練、資格、**学習ロードマップ** を説明する |
| スキルページ | `skills.html` | 学習した技術とITサポート系スキルをカテゴリ別に見せる（Windows / Linux 系を別カードに分割） |
| インフラ運用Lab | `infra-lab.html` | Windows / M365 / AD を想定し、**VLAN論理構成図**、監視・証跡・一次対応・引き継ぎ基準を見せる |
| Linux 運用Lab | `linux-lab.html` | systemd / journalctl / cron / SSH / logrotate / rsync の運用設計メモ |
| Cloud Network Lab | `cloud-lab.html` | AWS VPC / Subnet / Security Group / Terraform validate / Cost Guardrail を見せる |
| 作品ページ | `works.html` | **Server Monitor**を先頭に、Infra Lab、Support Toolkit、開発作品を紹介 |
| 履歴書 | `resume.html` | A4 1pager。**想定業務 × 自分の備えマトリクス** と **学習ロードマップ** を含む |
| 連絡先ページ | `contact.html` | メールや GitHub などの連絡先を掲載する |
| Support Toolkit | `works.html#work-support-toolkit` | 手順書・PowerShell・チケット形式の対応例を、ITサポート実務に近い成果物としてまとめる |
| サポート文書 | `support-docs/` | 標準業務4本 + AD/M365変更ケース + 障害対応4本（**ネットワーク切り分け証跡**含む） + Postmortem 実例 + Backup Runbook + **フェイルオーバー Runbook** + SLO / チケット分類 / 物理層 / 面接 FAQ の計 17 本 + M365 ポリシー JSON 7 ファイル |
| 実務スクリプト | `support-scripts/` | PowerShell 9本（うち1本★DB一次対応）+ bash 1本（Linux一次切り分け）+ **Triage-Lib 純関数ライブラリ + Pester テスト** |
| Monitoring Stack | `monitoring-stack/` | Prometheus + Grafana + node_exporter + **Loki + Promtail** の docker-compose 一式 + 4 アラート + 2 ダッシュボード |
| Ansible Playbook | `ansible/` | Ubuntu ベースライン冪等化 (SSH / UFW / fail2ban / auditd / unattended-upgrades) |
| 実行証跡 | `infra-evidence/` | Static / Pester / Prometheus / Loki / Ansible / Terraform / M365 JSON の検証コマンドとサンプル出力 + **失敗→修正対比** |
| 本番化差分 | `production-readiness.md` | Lab から本番運用へ足す監視、通知、認証、秘密情報、バックアップ、変更管理 |

### `index.html`

サイトの顔となるトップページです。ファーストビューでは背景画像スライダーとキャッチコピーを表示し、閲覧者に「どんな人のポートフォリオか」を最初に伝えます。その下に採用担当者向けの1分サマリー、自己紹介・スキル・作品のプレビューを配置し、詳細ページへ移動しやすい導線を作っています。

初学者向けに見るポイントは、`header`、`nav`、`section` などの HTML タグでページを区切り、CSS のクラス名で見た目を調整している点です。

### `me.html`

自己紹介ページです。プロフィール、経歴タイムライン、取得資格などを掲載しています。作品だけでは伝わりにくい人物像や、ITサポート・社内SE補助・インフラ運用支援へキャリアチェンジする背景を補足する役割があります。

### `skills.html`

スキル一覧ページです。PC・IT基礎、トラブル切り分け、サーバー監視、ドキュメント整備、HTML / CSS、Python、PHP、JavaScript、データベースなどをカテゴリ別に整理しています。単に技術名を並べるのではなく、どのような制作物やサポート業務に活かせるかが分かるようにしています。

### `works.html`

作品紹介ページです。このポートフォリオの中心となるページで、Support Toolkit と6つの制作物をカード形式で掲載しています。フィルターボタンにより、Support Toolkit、Infrastructure、Python、PHP、HTML/CSS のようにカテゴリごとに作品を絞り込める構成です。

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

ITサポート職で評価されやすい「手順書整備」「ナレッジ共有」「切り分けの型」を示すためのドキュメントです。標準業務手順書 4 本（キッティング／退職対応／共有フォルダ権限管理／M365ライセンス管理）と、障害対応 3 本（10ケース事例集／重大インシデント対応プレイブック／マルウェア感染疑い対応フロー）の合計 7 本を掲載しています。各ドキュメントは想定環境・想定読者・チェックリスト形式で構成し、現場で参考にできる粒度を意識しました。

### `support-scripts/`

PowerShellで端末情報、ネットワーク疎通、イベントログ、ディスク容量を確認するサンプル集です。削除や設定変更を含まない読み取り中心の内容にし、問い合わせ受付後の一次確認やチケット添付を想定しています。

---

## フォルダ・ファイルの役割

```text
ns7jp.github.io/
├── CODE_WALKTHROUGH.md      ... 初学者向けの詳細なコード読解ガイド
├── index.html               ... トップページ
├── me.html                  ... 自己紹介ページ（学習ロードマップ含む）
├── skills.html              ... スキル一覧ページ（Win / Linux 系を別カードに分割）
├── works.html               ... 作品一覧ページ（Infra カテゴリに Lab + Support Toolkit）
├── infra-lab.html           ... Windows / M365 / AD Lab（VLAN論理構成図）
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
│   ├── backup-restore-runbook.md              ... RTO/RPO/DR ドリル付き（Win VSS + Linux rsync）
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
├── monitoring-stack/        ... ★ Prometheus + Grafana + node_exporter + Loki + Promtail
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

| # | 作品名 | 主な技術 | 位置付け | 内容 | リポジトリ |
|---|--------|----------|----------|------|------------|
| ① | Server Monitor | Linux / Ansible / Docker / Prometheus / Grafana / Loki | **主作品** | 設計、構成管理、監視、試験、障害注入、復旧、実測証跡を一つの案件として公開 | [ns7jp/server-monitor](https://github.com/ns7jp/server-monitor) |
| ② | Support Toolkit | Markdown / PowerShell / bash | 補助成果 | 手順書17本、確認スクリプト9本、Pester 25テスト、AD/M365変更ケース、サンプル出力3種 | [support-docs](./support-docs/) / [support-scripts](./support-scripts/) |
| ③ | 定型文管理アプリ | Python / Flet | 補助成果 | よく使う文章を保存し、ワンクリックでコピーするデスクトップアプリ | [ns7jp/works](https://github.com/ns7jp/works) |
| ④ | 付箋アプリ | Python / Tkinter | 補助成果 | 複数の付箋を作成・保存・復元できるデスクトップアプリ | [ns7jp/works](https://github.com/ns7jp/works) |
| ⑤ | 掲示板アプリ | PHP / MySQL | 補助成果 | ユーザー登録、投稿、返信ができる掲示板 | [ns7jp/post](https://github.com/ns7jp/post) |
| ⑥ | SNSアプリ「Pulse」 | PHP / SQLite / JavaScript | 補助成果 | 感情ムードを選んで投稿するSNS | [ns7jp/pulse](https://github.com/ns7jp/pulse) |
| ⑦ | サンプル企業サイト | HTML / CSS / JavaScript | 補助成果 | 架空企業のレスポンシブ対応コーポレートサイト | [ns7jp/magic](https://github.com/ns7jp/magic) |

作品ページでは、単に「何を作ったか」だけでなく、「どんな場面で使えるか」「作る中で何に困ったか」「どう解決したか」も記載しています。これは、完成物だけでなく、問題解決の過程も伝えるためです。

---

## このサイト本体で使っている技術

### HTML5

ページの構造を作るために使用しています。たとえば、サイト上部は `header`、メニューは `nav`、各まとまりは `section`、本文の大きなまとまりは `article`、下部情報は `footer` のように、意味に合ったタグを使っています。

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

サイトに動きを加えるために使用しています。たとえば、ページ読み込み時のローダー、スマホ用ハンバーガーメニュー、スクロール時の表示演出、背景画像スライダーなどです。

以前は jQuery と `jquery.bgswitcher.js`（外部プラグイン）に依存していましたが、CDN 読み込み失敗時にローダーが消えず画面が固まってしまう問題があったため、`js/main.js` に外部ライブラリ非依存の vanilla JS として書き直しました。トップページのヒーロー背景クロスフェードも、`main.js` 内で2枚のレイヤーの `opacity` を切り替えるだけの実装に置き換えています。

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
