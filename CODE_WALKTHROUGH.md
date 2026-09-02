# ns7jp.github.io コード読解ガイド

このドキュメントは、島田則幸のポートフォリオサイトを構成する各ファイルが「何を担当しているか」「どの順番で読むと理解しやすいか」を初学者向けに整理したものです。HTML / CSS / JavaScript / 画像の役割を分けて読むと、静的サイト（あらかじめ用意したファイルを、そのまま表示するサイト）全体の作りが見えやすくなります。

---

## 1. サイト全体の仕組み

> **かんたんに言うと** このサイトには、アクセスのたびにページを組み立てるサーバー側の処理がありません。置いてあるファイルの中身が、そのまま画面になります。だからファイルを1つずつ読めば、全体の仕組みが分かります。

このリポジトリは GitHub Pages（GitHubが用意した、ファイルをそのまま公開できるサービス）で公開している静的ポートフォリオサイトです。PHP（サーバー側でページを組み立てる言語）やデータベース（データをためておく仕組み）は使いません。ブラウザが HTML・CSS・JavaScript・画像を読み込んで表示します。

```text
GitHub Pages
  ↓ index.html を配信
ブラウザ
  ↓ HTML を読む
css/reset.css / css/style.css
  ↓ 見た目を整える
JavaScript（Vanilla JS、js/main.js）
  ↓ ローダー、メニュー、作品フィルター、スクロール処理を動かす
image/
  ↓ プロフィール画像・作品画像・背景画像を表示
```

HTML は「ページの構造」、CSS は「見た目」、JavaScript は「動き」、画像は「視覚情報」を担当します。図にある Vanilla JS とは、jQuery のような外部ライブラリ（他の人が作った便利な部品集）を使わない、ブラウザ標準だけの JavaScript のことです。

---

## 2. 最初に読むおすすめ順

1. `README.md`
   - サイトの目的、Linuxサーバー構築・運用向けに何を伝えるサイトか、ファイル構成を確認します。
2. `index.html`
   - トップページの構成を読みます。最初に見せたい情報と、各ページへの導線を確認します。
3. `project-brief.html`
   - 主案件の目的、担当範囲、工程、成果物、設計判断、未実測の境界を確認します。
4. `evidence-demo.html`
   - 日付・環境・commit（変更の記録に付く固有の番号）付きの、完了済み実測結果を確認します。あわせて PASS（試験に合格した）と NOT RUN（その試験は実施していない）の境界も確認します。
5. `demo.html`
   - 2026年8月18日・19日の保存済み証跡を再構成した2分15秒の補助リプレイと、元証跡への導線を確認します。
6. `me.html`
   - 経歴、資格、人物像、**学習ロードマップ** を伝えるページ構成を確認します。
7. `skills.html`
   - Linux構築・監視・自動化を先頭に、補助的なITサポート、Web制作、Python/PHPの分類を確認します。
8. `infra-lab.html`
   - Linuxサーバー案件の10番号付き成果物、構築・監視・復旧マトリクス、実測と未実測の境界を確認します。
9. `linux-lab.html`
   - Linux の一次運用（障害が起きたとき、まず最初に行う確認と応急処置）を練習する Lab ページです。systemd / journalctl / SSH / rsync のコマンド早見表を確認します。
10. `cloud-lab.html`
   - AWS（Amazonが提供するクラウドサービス）でネットワークを組むときの設計メモを確認します。VPC（自分専用の仮想ネットワーク）、Subnet（その中の区画）、Security Group（通信の許可・拒否を決める設定）、Terraform validate（構成ファイルの書き方を検査するコマンド）、Cost Guardrail（費用が増えすぎないようにする歯止め）を扱っています。
11. `works.html`
   - 主案件、証跡、補助成果、学習作品の順序とフィルター機能を確認します。
12. `resume.html`
   - A4用紙1枚にまとめた履歴書です。**想定業務 × 自分の備えマトリクス**（想定される仕事と、それに対して用意した成果物の対応表）と、学習ロードマップ（これから学ぶ順番の計画）を確認します。
13. `contact.html`
   - 連絡先と問い合わせ導線を確認します。
14. `css/reset.css` → `css/style.css`
   - ブラウザ差のリセット、サイト全体のデザイン、レスポンシブ対応を確認します。
15. `js/main.js`
   - ローダー解除、メニュー開閉、作品フィルター、スクロール処理を担う、外部ライブラリ非依存の共通スクリプトです。
16. `image/` / `media/` と `favicon.ico`
    - 背景画像、プロフィール画像、作品画像、証跡リプレイ動画・字幕、ブラウザタブ用アイコンの役割を確認します。
17. `support-docs/` / `support-scripts/` / `monitoring-stack/` / `ansible/` / `cloud-lab/` / `infra-evidence/`
    - **HTML 以外** の成果物をまとめた場所です。手順書、PowerShell + bash のスクリプト、Pester（PowerShell用のテスト道具）、Prometheus + Loki + Promtail（サーバーの数値とログを集めて監視する道具）、Ansible playbook（サーバー設定を自動でそろえる手順ファイル）、Terraform（クラウドの構成を設定ファイルから作る道具）、M365 ポリシー JSON、実行証跡が入っています。インフラ運用ポートフォリオの本体です。
15. `support-docs/slo-error-budget.md` / `support-docs/ticket-taxonomy.md` / `support-docs/office-it-physical-layer.md` / `support-docs/m365-policy-examples/` / `support-docs/interview-faq.md`
    - **運用品質を数値で語る系**の成果物です。SLO（サービス品質の目標値）と Error Budget（目標を下回ってよい許容量）、ITIL 4（IT運用の代表的な進め方）の区分によるチケット分類、物理層 (ラック / LAN / UPS)、Intune + 条件付きアクセス + Defender ASR（いずれも会社のWindows端末を管理・保護するMicrosoftの機能）の JSON 定義、面接想定 FAQ を確認します。

---

## 3. ファイル別の説明

### `README.md`

リポジトリ全体の説明書です。サイトの目的、ページ構成、掲載作品、使用技術、ローカル確認方法をまとめています。

初学者が見るポイント:
- このサイトが Linuxサーバー構築・運用を第一志望とするポートフォリオであること
- HTML / CSS / JavaScript / 画像がどのように分担しているか
- どのファイルを読めば、どのページの内容が分かるか

---

### `index.html`

サイトの入口となるトップページです。閲覧者に最初の数秒で「Linuxサーバー構築・運用を目指す人のポートフォリオ」だと伝える役割があります。

主な構成:
- `<head>`: SEO（検索結果での見え方を整える設定）、OGP（SNSで共有されたときに出る見出しや画像の設定）、CSS、共通スクリプト（js/main.js）、フォント、アイコンを読み込む
- `.loader`: ページ読み込み中の表示
- `.res-menu`: スマホ用メニュー開閉ボタン
- `<header>` / `<nav>`: サイト共通ナビゲーション
- `.hero`: ファーストビュー。Linux Server Build & Operations の訴求
- `.quick-intro`: 自己紹介ページへの導線
- `.skills-preview`: スキルページへの導線
- `.works-preview`: 代表作品への導線
- `.contact-cta`: 連絡先ページへの導線
- `js/main.js`（全ページ共通）: ローダー、メニュー、背景画像切替、スクロール演出を実装

初学者が見るポイント:
- `class` は CSS と JavaScript の両方で使われる名前
- `meta description` や OGP は公開サイトとしての見え方を整える設定
- ヒーロー背景は主作品の1枚に固定し、複数画像の自動取得を行わない

---

### `me.html`

自己紹介ページです。経歴、職業訓練、資格、人物像を伝えます。作品だけでは伝わりにくい「どんな現場経験を持ち、なぜLinuxサーバー構築・運用を目指すのか」を補足します。

主な構成:
- `.page-hero`: サブページ共通の見出し
- プロフィールカード: 氏名、写真、自己紹介
- タイムライン: 学歴、職歴、職業訓練などの流れ
- 資格カード: Python、PHP、食品衛生管理者などの資格
- 趣味・人物面: 人柄や継続力を補足する情報
- `js/main.js`（全ページ共通）: ローダー、メニュー、ヘッダー縮小演出

初学者が見るポイント:
- 同じヘッダー・フッター構造を複数ページで繰り返している
- タイムラインは HTML の入れ子構造と CSS で作られている
- ページごとの内容は違っても、共通 CSS により見た目を統一している

---

### `skills.html`

スキル一覧ページです。Linux構築・監視・自動化・障害復旧を先に示し、開発技術、ITサポート、ドキュメント整備は補助スキルとして見せます。

主な構成:
- 補助的な運用支援スキル: PC基礎、問い合わせ対応、切り分け、ドキュメント化など
- Web / プログラミング: HTML/CSS、JavaScript、Python、PHP
- インフラ・監視: Flask、psutil、サーバー監視、ログ確認の入口
- ソフトスキル: 正確性、改善意識、継続学習など
- `js/main.js`（全ページ共通）: スキルカードのフェードイン演出

初学者が見るポイント:
- スキルカードは同じ HTML 構造を繰り返して作られている
- 星評価や進捗バーは CSS と HTML の組み合わせで表現している
- スキル名や自己評価ではなく「どの成果物で使い、どこまで検証したか」を示すことが大切

---

### `works.html`

作品紹介ページです。Linux Server Build & Operations LabとServer Monitorを主成果として先頭に置き、Support Toolkitと開発学習作品を補助成果として紹介します。

主な構成:
- `.filter-section`: 技術カテゴリ別の絞り込みボタン
- `.work-showcase-item`: 1作品分の紹介カード
- `data-category`: フィルター処理で使うカテゴリ情報（**スペース区切りで複数所属可**。例: `data-category="support infra"`）
- 各作品のリンク: デモサイト、GitHub リポジトリ
- `js/main.js`（全ページ共通）: フィルター、フェードイン、ヘッダー縮小演出

初学者が見るポイント:
- `data-filter` と `data-category` を対応させることで、JavaScript から絞り込みできる
- `data-category` は空白区切りで複数の値を持てる。そのため `split(/\s+/)` で値を1つずつに分け、配列（値を順番に並べた入れ物）にしてから、選ばれたカテゴリと一致するか判定している（1作品を複数カテゴリに所属させられる）
- 表示・非表示は `element.style.display` の切り替えで実装（vanilla JS、外部ライブラリ非依存）
- 主成果のサーバー構築・監視を先に読み、定型文管理、付箋、掲示板は補助スキル・学習作品として読む

---

### `infra-lab.html`

Windows / M365（Microsoft 365。会社で使うメールやOfficeのクラウドサービス）/ AD（Active Directory。社員アカウントとPCをまとめて管理する仕組み）を想定した **インフラ運用Lab**（練習用の想定環境）ページです。VLAN（1本の配線を用途ごとに分ける仮想的なネットワーク）の論理構成図、監視・証跡マトリクス、チケットフロー（問い合わせが解決するまでの流れ）を1ページで見せます。

主な構成:
- `.lab-subnav`: Windows / Linux / Monitoring Stack / Ansible のサブナビ
- `.network-diagram`: DMZ / Server / User / Guest VLAN と Microsoft 365 / Entra ID 連携の論理構成図
- `.operation-table`: 端末ヘルス / ネットワーク / 性能・ログ / AD・M365 ごとの確認観点と PowerShell リンク
- `.incident-flow`: 受付 → 切り分け → 証跡保存 → 対応・連携 → 再発防止 の5ステップ
- `.lab-links-section`: 証跡サンプル と 関連Lab (Linux / Monitoring / Ansible / Postmortem / Backup) へのリンクカード

初学者が見るポイント:
- 構成図は SVG ではなく **CSS Grid で組まれた論理図**。アクセシビリティのため `role="img"` と `aria-label` を付与
- `.lab-subnav .active` で現在ページを強調
- `<code>` で囲んだコマンド表記はそのまま等幅フォントで表示される

---

### `linux-lab.html`

Linux サーバー一次運用のLabです。`infra-lab.html` のサブナビから遷移します。

主な構成:
- `.lab-subnav`: Windows / Linux / Cloud / Monitoring / Ansible 間のサブナビ（active が `linux-lab.html` に切り替わる）
- `.operation-table`: 負荷 / メモリ / ディスク / サービス / ログ / ネット / 認証 / FW の確認コマンド早見表
- `.lab-architecture-grid`: SSH鍵 / 権限 / cron / logrotate の運用メモを 2x2 カードで配置
- `.lab-link-card` 内の `<pre>`: rsync + systemd timer のコード例（コードブロック装飾はインライン）

初学者が見るポイント:
- 同じ `infra-lab-content` スタイルを共有し、ページ間の見た目を統一
- コードブロックはダーク背景のインラインスタイル。CSS変数に頼らないため移植性が高い
- bash スクリプト本体（`support-scripts/linux-triage.sh`）は別ファイルにし、ページからリンクで誘導

---

### `resume.html`

A4用紙1ページの履歴書です（印刷して PDF にできます）。`<meta name="robots" content="noindex">` を書くと、検索エンジンの一覧（検索インデックス）に登録されなくなります。この指定により、履歴書ページが検索結果に出ないようにしています。

主な構成:
- `.resume-toolbar`: 印刷ボタンとサイトへ戻るリンク
- `.resume-header`: 氏名、志望領域、連絡先
- `.resume-summary`: 3行サマリー
- `.resume-body`: 2カラムで EDUCATION / CERTIFICATIONS / SKILLS / SELECTED WORKS
- `.resume-readiness`: **想定業務 × 自分の備えマトリクス**（行=想定業務、列=用意している成果物）
- `.resume-roadmap`: 4ステップの学習ロードマップ
- `@media print`: 印刷時にツールバー非表示、A4ポートレート

初学者が見るポイント:
- レイアウトCSSは `<head>` 内の `<style>` に同居しており、ファイル単独でも完結
- `width: 210mm / min-height: 297mm` で A4 サイズを再現
- 印刷時の挙動は `@page` ルールでマージンも制御

---

### `contact.html`

連絡先ページです。メール、GitHub、所在地などの情報と、採用担当者向けのメッセージを掲載します。

主な構成:
- 連絡先カード: メール、GitHub など
- メッセージ: ポートフォリオ確認者への案内
- FAQ: よくある確認事項
- `js/main.js`（全ページ共通）: ローダー、メニュー、ヘッダー縮小、フォーム風入力欄のフォーカス演出

初学者が見るポイント:
- 連絡先はリンクとしてクリックできる形にしている
- アイコンは Font Awesome のクラスで表示している
- フォーカス演出は、入力欄に `.focused` クラスを付け外しして実現している

---

### `css/reset.css`

ブラウザごとの標準スタイル差をそろえる CSS です。見出しやリスト、余白などを一度リセットしてから、`style.css` でデザインを組み立てます。

初学者が見るポイント:
- `margin` / `padding` を 0 にして、意図しない余白を消している
- `font-size: 62.5%` により、`1rem = 10px` 相当になり、文字や余白の大きさを計算しやすくしている（rem は、基準の文字サイズを1として数える単位）
- `reset.css` は土台、`style.css` は実際のデザインという役割分担

---

### `css/style.css`

サイト全体の見た目を定義するメイン CSS です。全ページ共通のヘッダー、フッター、カード、ボタン、サブページ、作品カード、レスポンシブ対応などをまとめています。

主な構成:
- `:root`: 色、影、アニメーション速度などの CSS 変数
- Base / Typography: 全体の文字、リンク、見出し
- Loader / Header / Mobile Menu: 共通パーツ
- Hero / Intro / Skills / Works / Contact: トップページ用
- Page Hero / Profile / Timeline / Skills Page / Works Page / Contact Page: サブページ用
- Animations: フェードインやスライドアップ
- Responsive Design: スマホ・タブレット向けの上書き

初学者が見るポイント:
- `var(--primary-color)` のような CSS 変数で、色をまとめて管理している
- JavaScript が付ける `.show`、`.show2`、`.scrolled`、`.visible` に対応する見た目がある
- `@media` の中は、画面幅が狭いときの調整

---

### `js/main.js`

> **かんたんに言うと** クリックやスクロールなど「利用者の操作に反応する部分」を、全ページ分まとめて置いてあるファイルです。

全ページ共通の動きを1ファイルにまとめた vanilla JS（外部ライブラリ非依存）です。以前は jQuery 本体と背景画像切替プラグインを、CDN（外部の配信サーバー）から読み込んで使っていました。しかし、CDNからの読み込みに失敗すると不具合が起きます。それを避けるため、外部ライブラリなしで書き直しました。現在はヒーロー背景をCSSの1枚に固定し、JavaScriptでの画像切替は行いません。

初学者が見るポイント:
- `document.querySelector` / `addEventListener` など、ブラウザに最初から備わっている DOM API（JavaScriptからページの部品を取り出したり操作したりする命令のまとまり）だけで実装している
- `window.setTimeout(hideLoader, 4000)` は、`load` イベントが発火しない・遅れる環境でもローダーが固まったままにならないための保険
- 1つのファイルに集約したことで、9ページ分に同じコードをコピペしなくて済む

---

### `favicon.ico`

ブラウザのタブやブックマークに表示される小さなアイコンです。コードとして読むものではありませんが、HTML の `<link rel="shortcut icon" href="favicon.ico">` から読み込まれます。

---

### `image/`

サイト内で使う画像素材のフォルダです。トップページ背景、プロフィール、スキル、作品スクリーンショット、連絡先ページなどで使われます。

初学者が見るポイント:
- HTML の `src="image/..."` や CSS の背景画像指定から参照される
- 画像ファイル名と参照パスが一致しないと表示されない
- 作品スクリーンショットは、ポートフォリオで成果物を直感的に伝える重要な素材

---

### `support-docs/`

ITサポートと社内SE（社内のIT担当）の補助を想定した資料をまとめた場所です。内訳は、16本のガイドと README（リポジトリの説明書）、M365 のサンプルJSON 5本、補助のPowerShell 2本です（詳細は [support-docs/README.md](./support-docs/README.md)）。想定手順・架空ケースであり、実運用実績ではありません。

- 標準業務 4本（キッティング / オフボーディング / 共有フォルダ権限 / M365 ライセンス）
- 障害対応 4本（10ケース事例集 / 重大インシデント・プレイブック / マルウェア対応 / ネットワーク切り分け証跡）
- 事後分析・運用 6本（架空Postmortemサンプル / Backup・Restore計画 / フェイルオーバーRunbook / SLO・Error Budget / チケット分類 / 物理層設計）
- その他 3本（AD/M365 変更ケース / 面接想定 FAQ / M365 ポリシー README）

初学者が見るポイント:
- すべて Markdown ファイル。GitHub 上でそのまま読める
- 「型」と「実例」をペアで持つ（プレイブック ↔ Postmortem、運用方針 ↔ Runbook）
- Front matter は無く、純粋な Markdown のみ

---

### `support-scripts/`

PowerShell + bash + Pester を収めたスクリプト集。

- ルート: PowerShell 9本 + `linux-triage.sh`
- `lib/Triage-Lib.ps1`: しきい値判定・状態集約・メッセージ切り詰めなどの **純関数ヘルパー**
- `tests/Triage-Lib.Tests.ps1`: Pester 5 系のユニットテスト（25ケース）
- `samples/`: JSON / CSV / HTML のサンプル出力

初学者が見るポイント:
- すべて **読み取り中心** のスクリプトである。誤って実行しても被害が出ないように、削除・設定変更・サービス再起動は含めていない
- 動詞-名詞 (`Get-` / `Test-` / `Collect-` / `New-`) で意味を表す PowerShell の命名規則
- `lib/` と `tests/` を分けて、ロジックだけテスト可能にしている

---

### `monitoring-stack/`

Prometheus + Grafana（集めた数値をグラフで見せる道具）+ node_exporter（サーバーの状態を数値として出す道具）を組み合わせた、最小構成の監視環境です。docker-compose（複数のコンテナをまとめて起動する仕組み）で動かします。

- `docker-compose.yml`: 3 コンテナの構成
- `prometheus/prometheus.yml` + `prometheus/alert.rules.yml`: スクレイプ設定とアラート
- `grafana/provisioning/`: 起動時に Prometheus データソースとダッシュボードを自動登録

初学者が見るポイント:
- `docker compose up -d` だけで起動する Lab 構成
- 認証情報は Lab 用の弱いものなので、本番転用しないこと
- アラートルールは CPU / メモリ / ディスク / exporter ダウン の 4 つだけにし、最小から始める設計

---

### `ansible/`

Ubuntu サーバーの基本設定（ベースライン）を、冪等（同じ操作を何度実行しても結果が変わらない性質）にそろえるための Playbook です。

- `playbook.yml`: SSH 強化 / UFW / fail2ban / auditd / unattended-upgrades / TZ
- `inventory.ini`: Lab 用インベントリ
- `templates/sshd_config.j2`: Ansible 管理下の sshd_config

初学者が見るポイント:
- `--check --diff` を付けて実行すると、実際には変更を加えずに「何がどう変わるか」だけを先に確認できる。本番のサーバーを壊さないための手順である
- `tags` を全タスクに付与し、SSH のみ / firewall のみの段階適用が可能
- `handlers` で「変更があったときだけサービス再起動」する

---

### `.github/workflows/`

GitHub Actions の CI 設定。

- `static-check.yml`: HTML 構造 + ローカルリンク + 画像バジェット（既存）
- `pwsh-tests.yml`: `support-scripts/` 変更時に Pester + PSScriptAnalyzer を pwsh で実行（新規）

初学者が見るポイント:
- `paths:` で、関連ファイルが変わったときだけ CI を走らせている
- ubuntu-latest 上の `pwsh` で PowerShell スクリプトをテストできる
- 静的解析 (PSScriptAnalyzer) はエラーがあれば失敗、警告のみは通す方針

---

## 4. 代表的な処理の追い方

> **かんたんに言うと** ここからは「画面で何かが起きたとき、どのファイルのどの部分が順番に動くのか」を矢印でたどった図です。上から下へ順に読んでください。

### ローダー

```text
HTML の .loader
  ↓ ページ読み込み完了（または4秒経過した場合の保険タイマー）
js/main.js の window.addEventListener('load', hideLoader)
  ↓
loader.style.opacity を 0 にしてフェードアウト
  ↓
ローダーが消えてページ本体が見える
```

### ハンバーガーメニュー

```text
.res-menu をクリック
  ↓
nav に .show を付け外し
.res-menu に .show2 を付け外し
  ↓
CSS がメニュー表示とアイコン切替を反映
```

### ヒーロー背景

```text
index.html の .hero-slider
  ↓
css/style.css が主作品の固定背景画像を表示
  ↓
複数画像の自動取得・タイマー切替を行わず初期表示を安定させる
```

### 作品フィルター

```text
works.html の .filter-btn
  ↓ クリック
data-filter の値を取得
  ↓
.work-showcase-item[data-category="..."] だけ表示
```

### スクロール演出

```text
window の scroll
  ↓
100px以上なら header に .scrolled
要素が画面に入ったら .visible
  ↓
CSS の見た目変更・フェードインが反映される
```

---

## 5. 学習時に意識するとよいこと

- HTML はページ構造を作る
- CSS は見た目とレスポンシブ対応を作る
- JavaScript（Vanilla JS）はユーザー操作に反応する動きを作る
- `class` は CSS と JavaScript の橋渡しになる
- `data-*` 属性は JavaScript に追加情報を渡すときに便利
- GitHub Pages では、静的ファイルを push するだけで公開サイトに反映できる
- Linuxサーバー構築・運用向けポートフォリオでは、作品の見た目だけでなく「設計」「構築手順」「試験」「監視」「復旧」「引き渡し」を証跡付きで説明することが重要
