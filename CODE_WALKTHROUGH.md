# ns7jp.github.io コード読解ガイド

このドキュメントは、島田則幸のポートフォリオサイトを構成する各ファイルが「何を担当しているか」「どの順番で読むと理解しやすいか」を初学者向けに整理したものです。HTML / CSS / JavaScript / 画像の役割を分けて読むと、静的サイト全体の作りが見えやすくなります。

---

## 1. サイト全体の仕組み

このリポジトリは GitHub Pages で公開している静的ポートフォリオサイトです。PHP やデータベースは使わず、ブラウザが HTML・CSS・JavaScript・画像を読み込んで表示します。

```text
GitHub Pages
  ↓ index.html を配信
ブラウザ
  ↓ HTML を読む
css/reset.css / css/style.css
  ↓ 見た目を整える
JavaScript / jQuery
  ↓ ローダー、メニュー、背景スライダー、スクロール演出を動かす
image/
  ↓ プロフィール画像・作品画像・背景画像を表示
```

HTML は「ページの構造」、CSS は「見た目」、JavaScript は「動き」、画像は「視覚情報」を担当します。

---

## 2. 最初に読むおすすめ順

1. `README.md`
   - サイトの目的、ITサポート向けに何を伝えるサイトか、ファイル構成を確認します。
2. `index.html`
   - トップページの構成を読みます。最初に見せたい情報と、各ページへの導線を確認します。
3. `me.html`
   - 経歴、資格、人物像を伝えるページ構成を確認します。
4. `skills.html`
   - ITサポート、インフラ運用、Web制作、Python/PHP などのスキル分類を確認します。
5. `works.html`
   - 作品紹介カード、フィルター機能、ITサポートに関連する作品の見せ方を確認します。
6. `contact.html`
   - 連絡先と問い合わせ導線を確認します。
7. `css/reset.css` → `css/style.css`
   - ブラウザ差のリセット、サイト全体のデザイン、レスポンシブ対応を確認します。
8. `js/jquery.bgswitcher.js`
   - トップページの背景画像を切り替える jQuery プラグインの役割を確認します。
9. `image/` と `favicon.ico`
   - 背景画像、プロフィール画像、作品スクリーンショット、ブラウザタブ用アイコンの役割を確認します。

---

## 3. ファイル別の説明

### `README.md`

リポジトリ全体の説明書です。サイトの目的、ページ構成、掲載作品、使用技術、ローカル確認方法をまとめています。

初学者が見るポイント:
- このサイトが ITサポート・社内SE補助・インフラ運用支援向けのポートフォリオであること
- HTML / CSS / JavaScript / 画像がどのように分担しているか
- どのファイルを読めば、どのページの内容が分かるか

---

### `index.html`

サイトの入口となるトップページです。閲覧者に最初の数秒で「ITサポート・インフラ運用支援を目指す人のポートフォリオ」だと伝える役割があります。

主な構成:
- `<head>`: SEO、OGP、CSS、jQuery、背景切替プラグイン、フォント、アイコンを読み込む
- `.loader`: ページ読み込み中の表示
- `.res-menu`: スマホ用メニュー開閉ボタン
- `<header>` / `<nav>`: サイト共通ナビゲーション
- `.hero`: ファーストビュー。IT Support / Infra Support の訴求
- `.quick-intro`: 自己紹介ページへの導線
- `.skills-preview`: スキルページへの導線
- `.works-preview`: 代表作品への導線
- `.contact-cta`: 連絡先ページへの導線
- 末尾の `<script>`: ローダー、メニュー、背景画像切替、スクロール演出を実装

初学者が見るポイント:
- `class` は CSS と JavaScript の両方で使われる名前
- `meta description` や OGP は公開サイトとしての見え方を整える設定
- `bgswitcher()` は `js/jquery.bgswitcher.js` で提供される背景画像切替機能

---

### `me.html`

自己紹介ページです。経歴、職業訓練、資格、人物像を伝えます。作品だけでは伝わりにくい「どんな現場経験を持ち、なぜ ITサポート領域を目指すのか」を補足します。

主な構成:
- `.page-hero`: サブページ共通の見出し
- プロフィールカード: 氏名、写真、自己紹介
- タイムライン: 学歴、職歴、職業訓練などの流れ
- 資格カード: Python、PHP、食品衛生管理者などの資格
- 趣味・人物面: 人柄や継続力を補足する情報
- 末尾の `<script>`: ローダー、メニュー、ヘッダー縮小演出

初学者が見るポイント:
- 同じヘッダー・フッター構造を複数ページで繰り返している
- タイムラインは HTML の入れ子構造と CSS で作られている
- ページごとの内容は違っても、共通 CSS により見た目を統一している

---

### `skills.html`

スキル一覧ページです。技術スキルだけでなく、ITサポート・インフラ運用・ドキュメント整備・トラブル対応につながる項目も見せるページです。

主な構成:
- ITサポートスキル: PC基礎、問い合わせ対応、切り分け、ドキュメント化など
- Web / プログラミング: HTML/CSS、JavaScript、Python、PHP
- インフラ・監視: Flask、psutil、サーバー監視、ログ確認の入口
- ソフトスキル: 正確性、改善意識、継続学習など
- 末尾の `<script>`: スキルカードのフェードイン演出

初学者が見るポイント:
- スキルカードは同じ HTML 構造を繰り返して作られている
- 星評価や進捗バーは CSS と HTML の組み合わせで表現している
- ITサポート向けの訴求では、単なる技術名より「どう業務に使えるか」が大切

---

### `works.html`

作品紹介ページです。6つの作品を、画像・概要・学習ポイント・使用例・トラブルと解決方法・技術タグで紹介します。

主な構成:
- `.filter-section`: 技術カテゴリ別の絞り込みボタン
- `.work-showcase-item`: 1作品分の紹介カード
- `data-category`: フィルター処理で使うカテゴリ情報
- 各作品のリンク: デモサイト、GitHub リポジトリ
- 末尾の `<script>`: フィルター、フェードイン、ヘッダー縮小演出

初学者が見るポイント:
- `data-filter` と `data-category` を対応させることで、JavaScript から絞り込みできる
- `fadeIn()` / `fadeOut()` は jQuery の表示・非表示アニメーション
- ITサポート寄りには、サーバー監視、定型文管理、付箋、掲示板など「業務改善・運用支援」と結びつけて読む

---

### `contact.html`

連絡先ページです。メール、GitHub、所在地などの情報と、採用担当者向けのメッセージを掲載します。

主な構成:
- 連絡先カード: メール、GitHub など
- メッセージ: ポートフォリオ確認者への案内
- FAQ: よくある確認事項
- 末尾の `<script>`: ローダー、メニュー、ヘッダー縮小、フォーム風入力欄のフォーカス演出

初学者が見るポイント:
- 連絡先はリンクとしてクリックできる形にしている
- アイコンは Font Awesome のクラスで表示している
- フォーカス演出は、入力欄に `.focused` クラスを付け外しして実現している

---

### `css/reset.css`

ブラウザごとの標準スタイル差をそろえる CSS です。見出しやリスト、余白などを一度リセットしてから、`style.css` でデザインを組み立てます。

初学者が見るポイント:
- `margin` / `padding` を 0 にして、意図しない余白を消している
- `font-size: 62.5%` により、`1rem = 10px` 相当で計算しやすくしている
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

### `js/jquery.bgswitcher.js`

トップページの背景画像を自動で切り替えるための jQuery プラグインです。外部由来のライブラリなので、通常は中身を大きく改造せず、`index.html` から使い方だけ指定します。

このサイトでの使われ方:

```javascript
$(".hero-slider").bgswitcher({
    images: ["image/works.jpg", "image/me.jpg", "image/contact.jpg", "image/skills.jpg"],
    interval: 5000,
    effect: "fade"
});
```

初学者が見るポイント:
- `$.fn.bgswitcher` により、jQuery オブジェクトへ機能を追加している
- `images` 配列に背景画像のパスを渡す
- `interval` は切り替え間隔、`duration` は切り替え時間
- このファイルは「仕組み」、`index.html` の設定は「使い方」

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

## 4. 代表的な処理の追い方

### ローダー

```text
HTML の .loader
  ↓ ページ読み込み完了
jQuery の $(window).on('load')
  ↓
$('.loader').fadeOut(800)
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

### 背景画像スライダー

```text
index.html の .hero-slider
  ↓
jquery.bgswitcher.js の bgswitcher()
  ↓
images 配列の画像を interval ごとに切り替える
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
- JavaScript / jQuery はユーザー操作に反応する動きを作る
- `class` は CSS と JavaScript の橋渡しになる
- `data-*` 属性は JavaScript に追加情報を渡すときに便利
- GitHub Pages では、静的ファイルを push するだけで公開サイトに反映できる
- ITサポート向けポートフォリオでは、作品の見た目だけでなく「業務改善」「運用支援」「切り分け力」が伝わる説明が重要
