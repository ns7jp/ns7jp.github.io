# 島田則幸のポートフォリオサイト

![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-jQuery-F7DF1E?logo=javascript&logoColor=black)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-success?logo=github)
[![Static site check](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml)

🔗 **公開サイト**: https://ns7jp.github.io/

## 採用担当者向け: まず見ていただきたい6点

短時間で確認しやすいよう、応募先で見ていただきたい成果物を6つに絞ると次の通りです。

| 優先 | 見るもの | 確認できること |
|------|----------|----------------|
| 1 | [1ページ履歴書](https://ns7jp.github.io/resume.html) | 経歴、資格、志望領域、**想定業務 × 自分の備えマトリクス**、学習ロードマップ |
| 2 | [Infra Operation Lab](https://ns7jp.github.io/infra-lab.html) | Windows / M365 / AD 想定の **VLAN 論理構成図**、監視項目、証跡、一次対応 |
| 3 | [Linux Operation Lab](https://ns7jp.github.io/linux-lab.html) | systemd / journalctl / cron / SSH / logrotate / rsync の運用設計と早見表 |
| 4 | [Monitoring Stack](./monitoring-stack/) | Prometheus + Grafana + node_exporter の docker-compose 一式 + 4 アラート |
| 5 | [Ansible Playbook](./ansible/) | SSH強化 / UFW / fail2ban / auditd / 自動更新 の冪等ベースライン |
| 6 | [Support Toolkit](https://ns7jp.github.io/works.html#work-support-toolkit) | 9手順書、**9 スクリプト（Pester 25テスト + GitHub Actions 付き）**、Postmortem 実例、Backup Runbook |

成果の見え方としては、Infra Operation Lab で **VLAN構成図・監視項目・証跡保存・一次対応・引き継ぎ基準** を見せ、Linux Lab と Monitoring Stack と Ansible で **「確認 → 適用 → 観測」を一通り** 示し、Support Toolkit で **9手順書・9スクリプト・25 Pesterテスト・Postmortem 実例・Backup Runbook** を公開し、サーバー監視（自作）では **6カテゴリ監視・60秒履歴・プロセスTOP15・3OS対応** を示しています。

公共職業訓練（2025年10月〜2026年1月）で学んだ HTML / CSS / JavaScript / Python / PHP の成果を、**ITサポート・社内SE補助・インフラ運用支援**の応募先にも伝わる形でまとめたポートフォリオサイトです。制作した Web アプリ、業務改善向けデスクトップアプリ、サーバー監視ツールに加え、ITサポート実務を想定した **Infra Operation Lab（運用設計メモ）** と **Support Toolkit（手順書・PowerShell・チケット形式の対応例）** へアクセスできる構成にしています。

この README は、Web 初学者の方にも「このサイトが何を目的に作られているのか」「どのファイルが何を担当しているのか」「HTML / CSS / JavaScript がどう分担して動いているのか」が分かるように、できるだけ順を追って説明しています。

各ファイルの詳しい役割、読む順番、処理の追い方は [CODE_WALKTHROUGH.md](./CODE_WALKTHROUGH.md) にまとめています。

---

## このサイトの目的

このサイトは、単に作品リンクを並べるだけではなく、**未経験から ITサポート・社内SE補助・インフラ運用支援領域を目指す過程で、どの技術を学び、どのような考え方で業務改善や運用支援に役立つ作品を作ったかを伝えるためのサイト**です。

閲覧者には、次のような情報が伝わることを目指しています。

| 見てほしいこと | 内容 |
|----------------|------|
| 人物像 | 製造・物流現場で培った正確性、改善意識、職業訓練で学んだ内容 |
| スキル | Windows / Microsoft 365 / Active Directory 想定、PowerShell、ネットワーク一次切り分け、Linux・サーバー監視の基礎 |
| 制作物 | Infra Operation Lab、Support Toolkit と6作品の概要、使い方、使用技術、ITサポート業務への活かし方 |
| 学習姿勢 | トラブルに対して原因を切り分け、調査し、修正し、手順化した過程 |
| 実務準備 | PCキッティング手順書、障害対応事例集、PowerShell確認スクリプト、チケット形式の対応例 |
| 連絡先 | GitHub やメールなど、連絡・確認に使える情報 |

初学者向けに言い換えると、このポートフォリオは「自分の学習成果を Web 上で見せる履歴書」のようなものです。履歴書が職歴や資格を伝えるのに対し、このサイトでは実際に作ったページやアプリを通して、問い合わせ対応・運用確認・業務改善ツール作成に必要な基礎力を示しています。

---

## このサイトの全体像

このサイトは「静的サイト」と呼ばれる種類の Web サイトです。静的サイトとは、サーバー側で PHP や Python が毎回ページを生成するのではなく、あらかじめ用意した HTML・CSS・JavaScript・画像ファイルをブラウザがそのまま読み込んで表示するサイトです。

このサイト本体では、データベースやログイン機能は使っていません。その代わり、ページ表示の速さ、構成の分かりやすさ、スマートフォン対応、作品への導線を重視しています。

| 技術 | このサイトでの役割 |
|------|------------------|
| HTML | 見出し、文章、画像、リンク、ナビゲーションなど、ページの骨組みを作る |
| CSS | 色、余白、文字サイズ、2カラム配置、カード表示、スマホ対応、アニメーションを担当 |
| JavaScript / jQuery | ローダー、ハンバーガーメニュー、背景画像切り替え、スクロール演出などの動きを担当 |
| 画像ファイル | ヒーロー画像、プロフィール画像、作品スクリーンショットを表示 |
| GitHub Pages | 作成した静的ファイルをインターネット上に公開 |

ブラウザで `https://ns7jp.github.io/` を開くと、GitHub Pages がこのリポジトリの `index.html` を配信し、そこから CSS・JavaScript・画像ファイルが読み込まれます。

---

## 閲覧の流れ

初めて見る人が迷わず内容を追えるよう、サイト全体は次の流れで構成しています。

1. **Top**
   最初に表示されるページです。ヒーロー画像、採用担当者向け1分サマリー、短い自己紹介、主要スキル、代表作品への導線を置いています。

2. **About Me**
   これまでの経歴、職業訓練で学んだこと、取得資格を確認できます。

3. **Skills**
   Windows / M365 / AD、PowerShell、ネットワーク一次切り分け、Linux・監視基礎、開発技術などをカテゴリ別に整理しています。ITサポート対応例と詳細ドキュメントへのリンクも置いています。

4. **Infra Lab**
   Windows 11 / Microsoft 365 / Active Directory を想定した運用設計メモです。VLAN論理構成図、監視項目、証跡保存、一次対応、エスカレーション基準を1ページで確認できます。サブナビから **Linux Lab / Monitoring Stack / Ansible** へ横展開できます。

5. **Works**
   Support Toolkit と制作した6作品を詳しく紹介しています。作品画像、成果サマリー、概要、使用技術、デモまたはスクリーンショット、GitHubリンク、制作時のトラブルと解決過程を掲載しています。

6. **Contact**
   メールや GitHub など、連絡先情報をまとめています。

---

## ページ構成

| ページ | ファイル | 役割 |
|--------|----------|------|
| トップページ | `index.html` | サイトの入口。自己紹介・スキル・作品ページへの導線をまとめる |
| 自己紹介ページ | `me.html` | プロフィール、経歴、職業訓練、資格、**学習ロードマップ** を説明する |
| スキルページ | `skills.html` | 学習した技術とITサポート系スキルをカテゴリ別に見せる（Windows / Linux 系を別カードに分割） |
| インフラ運用Lab | `infra-lab.html` | Windows / M365 / AD を想定し、**VLAN論理構成図**、監視・証跡・一次対応・引き継ぎ基準を見せる |
| Linux 運用Lab | `linux-lab.html` | systemd / journalctl / cron / SSH / logrotate / rsync の運用設計メモ |
| 作品ページ | `works.html` | Support Toolkit、**Infra Operation Lab**、6作品の詳細を紹介。Infrastructure カテゴリで絞り込み可能 |
| 履歴書 | `resume.html` | A4 1pager。**想定業務 × 自分の備えマトリクス** と **学習ロードマップ** を含む |
| 連絡先ページ | `contact.html` | メールや GitHub などの連絡先を掲載する |
| Support Toolkit | `works.html#work-support-toolkit` | 手順書・PowerShell・チケット形式の対応例を、ITサポート実務に近い成果物としてまとめる |
| サポート文書 | `support-docs/` | 標準業務4本 + 障害対応3本 + **Postmortem 実例** + **Backup/Restore Runbook** の計9本 |
| 実務スクリプト | `support-scripts/` | PowerShell 8本 + bash 1本（Linux一次切り分け）+ **Triage-Lib 純関数ライブラリ + Pester テスト** |
| Monitoring Stack | `monitoring-stack/` | Prometheus + Grafana + node_exporter の docker-compose 一式 + 4 アラートルール |
| Ansible Playbook | `ansible/` | Ubuntu ベースライン冪等化 (SSH / UFW / fail2ban / auditd / unattended-upgrades) |

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
├── contact.html             ... 連絡先ページ
├── resume.html              ... A4 1ページ履歴書 + 想定業務マトリクス + 学習ロードマップ
├── 404.html                 ... 存在しないURLにアクセスされた時のカスタム表示
├── sitemap.xml              ... 検索エンジン向けサイトマップ
├── robots.txt               ... クローラー制御
├── favicon.ico              ... ブラウザのタブに表示される小さなアイコン
├── README.md                ... この説明ファイル
│
├── css/                     ... reset.css と style.css
├── js/                      ... jQuery プラグイン
│
├── support-docs/
│   ├── pc-kitting-guide.md                    ... PCキッティング手順書
│   ├── account-offboarding-guide.md           ... 退職者アカウント停止手順書
│   ├── shared-folder-access-management.md     ... 共有フォルダ権限管理手順書
│   ├── m365-license-management.md             ... Microsoft 365ライセンス管理手順書
│   ├── troubleshooting-case-studies.md        ... 障害対応事例集（10ケース）
│   ├── incident-response-playbook.md          ... 重大インシデント対応プレイブック
│   ├── malware-suspected-response.md          ... マルウェア感染疑い対応フロー
│   ├── postmortem-example.md                  ... ★ 共有フォルダI/O飽和のPostmortem実例（架空）
│   └── backup-restore-runbook.md              ... ★ Win VSS + Linux rsync のバックアップ運用
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
│   ├── linux-triage.sh              ... ★ Linux 一次切り分け bash
│   ├── lib/Triage-Lib.ps1           ... ★ 純関数化された判定ロジック
│   └── tests/Triage-Lib.Tests.ps1   ... ★ Pester ユニットテスト（25ケース）
│
├── monitoring-stack/        ... ★ Prometheus + Grafana + node_exporter の docker-compose
│   ├── docker-compose.yml
│   ├── prometheus/prometheus.yml
│   ├── prometheus/alert.rules.yml
│   └── grafana/provisioning/
│
├── ansible/                 ... ★ Linux ベースライン冪等化 playbook
│   ├── playbook.yml
│   ├── inventory.ini
│   └── templates/sshd_config.j2
│
├── .github/workflows/
│   ├── static-check.yml     ... HTML 構造 + リンク + 画像バジェット
│   └── pwsh-tests.yml       ... ★ Pester + PSScriptAnalyzer
│
└── image/                   ... ヒーロー画像・スクリーンショット
```

★ は本ブランチで追加した成果物。

初学者向けに説明すると、HTML ファイルは「ページごとの本文」、CSS フォルダは「見た目の設定」、JavaScript フォルダは「動きの設定」、image フォルダは「表示に使う画像置き場」です。

---

## 掲載成果物

| # | 作品名 | 主な技術 | ITサポート関連度 | 内容 | リポジトリ |
|---|--------|----------|------------------|------|------------|
| ① | Support Toolkit | Markdown / PowerShell | High | 手順書7本、PowerShell確認スクリプト8本、チケット形式の対応例、サンプル出力3種 | [support-docs](./support-docs/) / [support-scripts](./support-scripts/) |
| ② | サーバー監視ダッシュボード | Python / Flask / psutil / Chart.js | High | PCやサーバーの状態をブラウザで可視化する監視ツール | [ns7jp/server-monitor](https://github.com/ns7jp/server-monitor) |
| ③ | 定型文管理アプリ | Python / Flet | High | よく使う文章を保存し、ワンクリックでコピーするデスクトップアプリ | [ns7jp/works](https://github.com/ns7jp/works) |
| ④ | 付箋アプリ | Python / Tkinter | Medium | 複数の付箋を作成・保存・復元できるデスクトップアプリ | [ns7jp/works](https://github.com/ns7jp/works) |
| ⑤ | 掲示板アプリ | PHP / MySQL | Medium | ユーザー登録、投稿、返信ができる掲示板 | [ns7jp/post](https://github.com/ns7jp/post) |
| ⑥ | SNSアプリ「Pulse」 | PHP / SQLite / JavaScript | Learning | 感情ムードを選んで投稿するSNS | [ns7jp/pulse](https://github.com/ns7jp/pulse) |
| ⑦ | サンプル企業サイト | HTML / CSS / JavaScript | Learning | 架空企業のレスポンシブ対応コーポレートサイト | [ns7jp/magic](https://github.com/ns7jp/magic) |

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

### JavaScript / jQuery

サイトに動きを加えるために使用しています。たとえば、ページ読み込み時のローダー、スマホ用ハンバーガーメニュー、スクロール時の表示演出、背景画像スライダーなどです。

`jquery.bgswitcher.js` は、トップページのヒーロー背景画像を自動で切り替えるためのプラグインです。これにより、トップページに動きが出て、ポートフォリオの第一印象を強めています。

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
