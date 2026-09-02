# 島田則幸のポートフォリオサイト

![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-Vanilla-F7DF1E?logo=javascript&logoColor=black)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-success?logo=github)
[![Static site check](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml)
[![Infrastructure checks](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml)

🔗 **公開サイト**: https://ns7jp.github.io/

**Linuxサーバー構築・運用を第一志望**としています。このサイトでは、Ubuntuサーバーの設定、動作確認、監視、ログ確認、障害からの復旧を学んだ過程を公開しています。「作ったもの」「実際に動かして確認したもの」「まだ試していないもの」を分けて記載します。

## 開発体制について

このポートフォリオと主作品 [Server Monitor](https://github.com/ns7jp/server-monitor) では、文章、プログラム、テストの作成補助にClaude Code / Codexを使用しました。どの方法を採用するかを決めるのは本人です。出てきた結果を確認し、未実施の項目をそのまま書き残すのも本人です。面談で内容を説明する責任も、本人が持ちます。個人制作であり、人による第三者レビューは受けていません。

## はじめに見てほしいページ

| 順番 | 見るもの | 何が分かるか |
|---|---|---|
| 1 | [3分で分かる制作概要](https://ns7jp.github.io/project-brief.html) | 何を作り、どこまで自分で取り組んだか |
| 2 | [未経験者向け学習ルート](https://ns7jp.github.io/learning-path.html) | 前提から復旧・引き渡しまでの8段階、合格条件、障害演習 |
| 3 | [動作確認の記録](https://ns7jp.github.io/evidence-demo.html) | いつ、どの環境で、何を確認したか。失敗と未実施の範囲も掲載 |
| 4 | [仕事の進め方](https://ns7jp.github.io/work-readiness.html) | 入社後に取り組みたい仕事、相談・報告の仕方、AIを使った範囲 |
| 5 | [1ページ履歴書](https://ns7jp.github.io/resume.html) | 経歴、資格、構築・運用スキル、主成果物、制作体制 |

## 実施状況

> **かんたんに言うと** 「どこまで自分の手で確かめたか」を4つに分けた一覧です。上の3つは確認できたこと、いちばん下の「未実施」はまだ試していないことです。

- **本人のPCで確認:** Windows上のLinux環境（WSL2）で、監視、ログ確認、サービスの復旧、ネットワーク障害の原因調査を練習しました。
- **GitHub上の自動テストで確認:** テストのたびに作り直す一時的なUbuntu環境で、構築から復旧までの23項目すべてに合格しました。前の版へ戻すテストも行いました。
- **AI支援の練習環境で確認:** 仮想環境や、コンテナ（アプリを動かすのに必要なものを一式まとめた軽い箱）を使った追加演習です。独立した実機での構築実績ではありません。
- **未実施:** 次の項目は、まだ試していません。独立サーバーでの72時間稼働、再起動後の確認、Slack（業務用チャットツール）への実通知、AWS（Amazonが提供するクラウドサービス）環境の作成・削除、別サーバーへの復元、本番通信などです。

自動テストに使ったUbuntuには、Docker（アプリを箱に詰めて動かす仕組み）があらかじめ入っていました。そのため、何も入っていないOSへDockerを自分で導入した実績とは表現しません。詳しい実行条件と、検証したコードの版（コミットID）は以下に残しています。

<details>
<summary>コミットIDを含む詳しい技術記録</summary>

- [構築から復旧までの一連テスト（E2E）23項目](https://github.com/ns7jp/server-monitor/blob/4a292026b569dd1a522c0f2913b4ad40aeccebe7/docs/evidence/2026-08-22-full-stack-e2e.md): テストは、使い捨ての一時的なUbuntu環境で実施しました。実行したコードは `7622a9d` です。記録を含む変更は、公開用の本流であるmainブランチ（変更をまとめていく中心の枝）の `4a292026` へ取り込み済みです。
- [前の版へ戻すテスト](https://github.com/ns7jp/server-monitor/actions/runs/32611251044): PR（プルリクエスト。変更をまとめて取り込んでもらうための申請）#77の途中のコード `84e1492` から、前の版 `59aa88e` へ戻せることを確認しました。PR #77自体は、後にmainへ取り込みました。ただしこの結果は、取り込んだ後のmainで同じテストをもう一度実行したものではありません。
- 2026年8月24日の追加演習はAI支援の仮想・コンテナ環境で行いました。面談で再現できると約束するのは、本人のWSL2 + Dockerで実行できるB-2 / B-3のみです。
- 2026年8月25日はAlmaLinux / Rocky Linux 9系向けのAnsible設定をコンテナ上で確認しました。実機AlmaLinuxサーバーでの結果ではありません。
- 公開中の2分15秒映像は、2026年8月18日・19日の画面と復旧ログを再構成したものです。実操作を最初から最後まで連続録画した映像ではありません。収録方法は[収録ガイド](https://github.com/ns7jp/server-monitor/blob/main/docs/demo-capture-guide.md)に分けています。

</details>

出発点は、公共職業訓練（2025年10月〜2026年1月）で学んだ開発の基礎です。そこから主作品のServer Monitorでは、計画、設定、動作確認、監視、問題の原因調査、復旧までを、一つの流れとして学んでいます。

このREADMEは、Web初学者にも「このサイトの目的」「各ファイルの役割」「HTML / CSS / JavaScriptの分担」が分かるように説明しています。詳しい読み方は[CODE_WALKTHROUGH.md](./CODE_WALKTHROUGH.md)にまとめています。

---

## このサイトの目的

このサイトは、単に作品リンクを並べるだけのものではありません。**未経験からLinuxサーバー構築・運用を目指す過程で、設定、プログラム、動作確認の記録をどう整理しているかを伝えるためのサイト**です。

閲覧者には、次のような情報が伝わることを目指しています。

| 見てほしいこと | 内容 |
|----------------|------|
| 人物像 | 製造・物流現場で培った正確性、改善意識、職業訓練で学んだ内容 |
| 第一志望 | Linuxサーバーの構築・運用 |
| スキル | Linuxサーバーの設定、構築の自動化、監視、ログ確認、問題の原因調査、復旧、開発・運用の補助 |
| 制作物 | Linuxサーバー構築・運用演習、動作確認の記録、Server Monitor、その他の学習作品 |
| 学習姿勢 | トラブルに対して原因を切り分け、調査し、修正し、手順化した過程 |
| 実務準備 | 目的確認、設計、設定、動作確認、引き渡し、前の版へ戻す手順、実機での確認手順 |
| 連絡先 | GitHub やメールなど、連絡・確認に使える情報 |

初学者向けに言い換えると、このポートフォリオは「サーバー構築の学習内容をWeb上で説明するファイル」のようなものです。作成した項目、実際に動かした項目、まだ試していない項目を分けて示します。

---

## このサイトの全体像

> **かんたんに言うと** このサイトは、あらかじめ作っておいたページを、そのまま見せるだけの作りです。アクセスのたびにページを組み立てる仕組みや、会員登録の仕組みは使っていません。

このサイトは「静的サイト」と呼ばれる種類の Web サイトです。静的サイトとは、あらかじめ用意した HTML・CSS・JavaScript・画像ファイルを、ブラウザがそのまま読み込んで表示するサイトです。アクセスのたびにサーバー側の PHP や Python がページを組み立てる方式とは違います。

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

1. **トップ**
   Linuxサーバー構築・運用という第一志望、主な学習成果、構成図、動作確認の記録への案内を最初に表示します。

2. **自己紹介**
   これまでの経歴、職業訓練で学んだこと、取得資格を確認できます。

3. **制作概要 / 動作確認の記録**
   Linuxサーバー構築演習の全体像と、実際に確認した結果、まだ試していない範囲を確認できます。

4. **サーバー構築 / スキル**
   要件の確認から引き渡しまでを、1から10まで番号を付けた10個の成果物として並べています。あわせて、Linux、Ansible（設定作業を自動化する道具）、Docker、監視、復旧のスキルを確認できます。Windows と M365（Microsoft 365）、および開発技術は、補助成果として区別しています。

5. **作品**
   Linux Server Build & Operations LabとServer Monitorを先頭に、Support Toolkit、業務改善・開発学習作品を詳しく紹介しています。

6. **連絡先**
   メールや GitHub など、連絡先情報をまとめています。

---

## ページ構成

| ページ | ファイル | 役割 |
|--------|----------|------|
| 学習ルート | `learning-path.html` | 未経験者が安全確認、設計、最小OS、手動構築、自動化、監視、障害対応、別ホスト復元を順番に学ぶ入口 |
| トップページ | `index.html` | サイトの入口。サーバー構築を「決める・作る・確かめる・守る」の4語で説明し、自己紹介・スキル・作品への導線をまとめる |
| 制作概要 | `project-brief.html` | Linuxサーバー構築学習の目的、取り組んだ範囲、流れ、作成資料、未実施の項目を説明する |
| 動作確認の記録 | `evidence-demo.html` | 一連の動作テスト、失敗と修正、未実施の範囲を、日時・環境・コードの版とともに示す |
| 仕事の進め方 | `work-readiness.html` | 入社後に取り組みたい仕事、作業前の確認、相談、動作確認、記録、報告、今後の学習計画 |
| 動作確認動画 | `demo.html` | 2026年8月18日・19日の画面と復旧ログを編集した2分15秒の動画 |
| 自己紹介ページ | `me.html` | プロフィール、経歴、職業訓練、資格、**学習ロードマップ** を説明する |
| スキルページ | `skills.html` | Linux構築・監視・自動化を先頭に、補助スキルを証跡区分付きで見せる |
| Active Directoryキーワード集 | `ad-keywords.html` | AD DS、DNS、Kerberos、OU/GPO、AGDLP、複製、FSMO、確認コマンド、障害対応を覚え方と安全な演習付きで解説する |
| SQL文・キーワード集 | `sql-keywords.html` | SQLの取得、集計、結合、変更、テーブル定義、権限、トランザクション、性能確認、障害対応を初心者向けに解説する |
| Excel基礎演習案件パック | `excel-exercise-pack.html` | ★ 「受・見・決・動・確・残」の合言葉で覚える、想定案件14件の演習パック。表の整形・入力規則・関数（SUM/IF/VLOOKUP/COUNTIFS）・データ整理・ピボットテーブル・印刷設定・シート保護・マクロを、数式例と模範解答付きで解説する |
| サーバー構築の学習 | `infra-lab.html` | 目的確認、設計、設定、動作確認、監視、復旧、引き継ぎを順に見せる |
| Linuxの基本確認 | `linux-lab.html` | 「重・空・動・記・通・入・壁」の覚え方と、負荷、空き容量、サービス、ログ、通信、ログイン、ファイアウォールの確認例 |
| CUIコマンド操作マニュアル | `cui-manual.html` | 端末の開き方、コマンドの読み方、パス、補完、履歴、パイプ、終了コード、安全確認、一次切り分けを段階演習付きで解説する |
| CLI操作演習案件パック | `cli-exercise-pack.html` | ★ 「受・見・決・動・確・残」の合言葉で覚える、想定チケット14件の演習パック。ファイル・プロセス・サービス・権限・ネットワーク・容量・Windows対比・総合演習を、難易度3段階と模範解答付きで解説する |
| Windowsコマンド集 | `windows-commands.html` | CMDとPowerShellの違い、「端・場・通・動・記・権」の覚え方、結果の読み方、安全上の注意、3つの練習 |
| AWSネットワークの学習用設計 | `cloud-lab.html` | AWS上でネットワークを分け、接続できる範囲を制限する設計例。AWSへの作成は未実施 |
| 作品ページ | `works.html` | Linux Server Build & Operations Labを先頭に、補助成果・学習作品を紹介 |
| 履歴書 | `resume.html` | A4 1ページ。経歴、資格、想定業務への備え、主な学習成果、AIを使った範囲を掲載 |
| 連絡先ページ | `contact.html` | メールや GitHub などの連絡先を掲載する |
| Support Toolkit | `works.html#work-support-toolkit` | 16ガイド+README、確認スクリプト、想定ケースを補助成果としてまとめる |
| サポート文書 | `support-docs/` | 16ガイド+README。架空ケース・計画・テンプレートを含み、実運用実績ではない |
| 確認スクリプト | `support-scripts/` | PowerShell 9本 + bash 1本、純関数ライブラリとPesterテスト |
| Monitoring Stack（アーカイブ） | `monitoring-stack/` | Prometheus + Grafana + node_exporter + Loki + Promtail の docker-compose 一式。**2026-03 に Promtail が EOL となり、主作品側は Grafana Alloy へ移行済み**（[monitoring-stack/README.md](./monitoring-stack/README.md)）。現行構成は [server-monitor](https://github.com/ns7jp/server-monitor) |
| 自動構築の設定 | `ansible/` | Ubuntuの基本設定を自動化。同じ手順を繰り返しても不要な変更が出ないように作成 |
| 出力サンプル | `infra-evidence/` | 架空・未採録の`.sample.txt`。実測した証跡（実際に動かした証拠）としては扱わない |
| 本番化差分 | `production-readiness.md` | Lab から本番運用へ足す監視、通知、認証、秘密情報、バックアップ、変更管理 |
| 初心者向け教材 | `learning-docs/` | 環境準備、最初の30分、基礎用語集、エラーFAQ、8段階ハンズオン、成果物例、質問テンプレート、障害演習、修了ルーブリック |

### `index.html`

サイトの顔となるトップページです。ファーストビュー（ページを開いた直後に、スクロールしなくても見える範囲）には、主作品の固定背景と短い紹介文を表示しています。これにより、閲覧者へ「どんな人のポートフォリオか」を最初に伝えます。その下に採用担当者向けの要約、仕事の進め方、自己紹介・スキル・主成果のプレビューを配置しています。

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

PowerShellで端末情報、ネットワーク疎通、イベントログ、ディスク容量を確認するサンプル集です。削除や設定変更は行わず、読み取りだけの内容にしています。問い合わせを受けた直後の一次確認（原因の当たりを付ける最初の調査）や、チケット（問い合わせを記録する管理票）への添付に使うことを想定しています。

---

## フォルダ・ファイルの役割

```text
ns7jp.github.io/
├── CODE_WALKTHROUGH.md      ... 初学者向けの詳細なコード読解ガイド
├── index.html               ... トップページ
├── project-brief.html       ... Linuxサーバー構築学習の概要
├── evidence-demo.html       ... 本人PC・自動テスト・未実施を分けた動作確認の記録
├── work-readiness.html      ... 仕事の進め方、制作体制、面談で説明できる内容、今後の学習計画
├── demo.html                ... 2分15秒の証跡リプレイ（連続操作動画ではない）
├── me.html                  ... 自己紹介ページ（学習ロードマップ含む）
├── skills.html              ... スキル一覧ページ（Win / Linux 系を別カードに分割）
├── ad-keywords.html         ... 初心者向けActive Directoryキーワード集（確認手順・演習付き）
├── sql-keywords.html         ... 初心者向けSQL文・キーワード集（安全手順・演習付き）
├── excel-exercise-pack.html ★ Excel基礎演習案件パック（想定案件14件、難易度3段階、数式例・模範解答付き）
├── works.html               ... 作品一覧ページ（Infra カテゴリに Lab + Support Toolkit）
├── infra-lab.html           ... Linux Server Build & Operations Lab
├── linux-lab.html           ... Linux 一次運用Lab（systemd / journalctl / SSH / rsync）
├── cui-manual.html          ... 未経験者向けCUIコマンド操作マニュアル（Linux / Windows共通）
├── cli-exercise-pack.html   ★ CLI操作演習案件パック（想定チケット14件、難易度3段階、模範解答付き）
├── windows-commands.html     ... Windows 一次確認コマンド集（CMD / PowerShell）
├── cloud-lab.html           ... Cloud Network Lab（AWS VPC / Terraform）
├── production-readiness.md  ... Lab を本番化する際に足す運用観点
├── contact.html             ... 連絡先ページ
├── resume.html              ... A4 1ページ履歴書 + 想定業務への備え + AI利用の説明
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
│   ├── Test-NetworkTriage.ps1       ... ネットワークの原因調査を補助
│   ├── Get-RecentSupportEvents.ps1  ... 警告・エラーログ抽出
│   ├── Test-DiskCapacity.ps1        ... ディスク容量確認
│   ├── Test-SecurityBaseline.ps1    ... Defender/Firewall/BitLocker/Update確認
│   ├── New-EndpointDailyReport.ps1  ... 日次CSV/HTMLレポート
│   ├── Get-StaleUserAccounts.ps1    ... AD 休眠ユーザー抽出
│   ├── Get-M365LicenseInventory.ps1 ... M365 ライセンス棚卸し（Graph SDK）
│   ├── Test-DatabaseHealth.ps1      ... ★ SQL Server 一次ヘルス + スロークエリ + バックアップ最新性
│   ├── linux-triage.sh              ... Linuxの状態とログを確認するbash
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
├── ansible/                 ... Linuxの基本設定を自動化するplaybook
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

★ 印は、このブランチ（作業用に枝分かれさせた作業場所）で新しく追加した成果物を表します。

初学者向けに説明すると、HTML ファイルは「ページごとの本文」、CSS フォルダは「見た目の設定」、JavaScript フォルダは「動きの設定」、image フォルダは「表示に使う画像置き場」です。

---

## 掲載成果物

| # | 作品名 | 主な技術 | 位置づけ | 内容 | リポジトリ |
|---|--------|----------|----------|------|------------|
| ① | Linux Server Build & Operations | Ubuntu / Ansible / Docker / Prometheus / Loki / Alloy | 主成果 | 要件から引き渡しまでの番号付き成果物10件と、2026年8月22日の通し試験（Full-stack E2E）23項目中23項目合格 | [ns7jp/server](https://github.com/ns7jp/server) |
| ② | サーバー監視ダッシュボード | Python / Flask / psutil / Chart.js | 主成果 | PCやサーバーの状態をブラウザで可視化する監視ツール | [ns7jp/server](https://github.com/ns7jp/server) |
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

これにより、人が読みやすくなるだけではありません。検索エンジンや、スクリーンリーダー（画面の文字を読み上げるソフト）にも、ページの構造が伝わりやすくなります。

### CSS3

サイト全体の見た目を整えるために使用しています。`style.css` には、色、フォント、余白、カード表示、画像の大きさ、スマホ対応、アニメーションなどをまとめています。

特に意識した点は次の通りです。

- Flexbox と CSS Grid という2つの仕組みを使い、要素の並べ方を組み立てています
- レスポンシブ対応（画面幅に合わせて配置が変わる作り）にして、スマートフォンでも見やすくしています
- CSS 変数を使い、色や余白の値を1か所でまとめて管理しています
- ホバー（マウスを重ねた状態）での変化や、ふわりと現れる動きを付けています
- 作品カードやスキルカードが見分けやすくなるよう、配色と余白を調整しています

### JavaScript（Vanilla JS）

サイトに動きを加えるために使用しています。たとえば、スマホ用ハンバーガーメニュー（横三本線を押すと開くメニュー）、作品フィルター（カテゴリを選んで作品を絞り込む機能）、画面を下へ動かしたときのヘッダー調整などです。

以前は jQuery と背景切替プラグインを使っていました。しかしこれらは CDN（外部の配信サーバー）から読み込むため、読み込みに失敗すると動きが壊れます。それを避けるため、`js/main.js` を外部ライブラリに頼らない素のJavaScript（vanilla JS）へ書き直しました。現在のトップ背景は主作品の1枚に固定し、複数画像の自動取得と定期切替をなくしています。

### Font Awesome

メニューやボタンに使うアイコンを表示するために使用しています。文字だけのリンクよりも、アイコンがあることで「自己紹介」「作品」「連絡先」などの意味が直感的に伝わりやすくなります。

### Google Fonts

日本語と英字の表示を整えるために使用しています。読みやすさとポートフォリオらしい雰囲気を両立するため、本文用と見出し用のフォントを使い分けています。

### GitHub Pages

このサイトは GitHub Pages で公開しています。GitHub Pages は、GitHub リポジトリに置いた HTML / CSS / JavaScript をそのまま Web サイトとして公開できるサービスです。サーバーを借りる契約や、デプロイ（作ったファイルを公開用の場所へ配置する作業）を簡略化できます。そのため、静的なポートフォリオサイトの公開に向いています。

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
   `image/` フォルダに素材をまとめ、HTML から相対パス（今のファイルから見た位置での指定）で読み込みます。こうしておくと、置き場所が分かりやすくなり、公開したときにも画像リンクが切れにくくなります。

5. **GitHub Pages で公開する**
   手元のファイルを GitHub へ push（アップロードして反映）し、GitHub Pages の公開設定を行うと、Web サイトとして公開されます。

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
  検索結果に表示される説明文（SEO 用の meta description）、SNSで共有したときの表示設定（OGP）、ブラウザのタブに出る小さなアイコン（favicon）、Google Fonts、Font Awesome など、公開サイトとして必要になる要素も入れています。

---

## ローカルで確認する方法

> **かんたんに言うと** 公開中のサイトには触らず、自分のパソコンの中だけでこのサイトを表示して確かめる手順です。

このサイトは静的サイトなので、基本的には `index.html` をブラウザで開けば表示できます。ただし、画像の切り替えなど一部の動きは、それだけでは正しく確認できないことがあります。そこで、自分のパソコンの中に簡易サーバーを立てて開く方法をおすすめします。次の3行は、上から順に「サイトのファイル一式を自分のパソコンへ複製する」「そのフォルダへ移動する」「そのフォルダを配信する簡易サーバーを起動する」ための操作です。

```bash
git clone https://github.com/ns7jp/ns7jp.github.io.git
cd ns7jp.github.io
python -m http.server 8000
```

起動後、ブラウザで以下を開きます。

```text
http://localhost:8000/
```

公開する前に、HTMLの構造、リンク切れ、アクセシビリティ（誰でも使えるようにする配慮）、SEO（検索エンジンへ正しく伝えるための設定）を、自分のパソコンの中で点検できます。目的は、表示の崩れやリンク切れを公開前に見つけることです。次のコマンドを順に実行します。すべて通れば「HTMLの構造とサイト内の相対リンク（同一ページ内のアンカーを含む）は壊れていない」と説明できます（外部URLへの到達確認はここには含まれません。外部URLの到達確認には、この後で説明するcheck-external-links.jsの実行が必要です）。

```bash
node scripts/check-html-structure.js
node scripts/check-static-links.js
node scripts/check-site-quality.js
node scripts/test-external-link-check.js
```

公開先やGitHubなど、外部URLがきちんと応答するかの確認は、ネットワークに接続できる環境で必要に応じて実行します。この確認は相手側のサーバーの状態でも失敗します。そのため、CI（GitHub上で自動的に実行する検査）の必ず通すべき合格条件には入れていません。

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

ライセンス方針は [LICENSE](./LICENSE) に記載しています。コード例・手順書・PowerShellサンプルは、学習とポートフォリオの確認に使ってもらうために公開しています。一方で、プロフィール文・履歴書の内容・人物写真など、個人情報を含む素材については、無断利用を避ける方針です。

---

© 2026 Noriyuki Shimada. All rights reserved.
