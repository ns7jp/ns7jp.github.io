# 島田則幸のポートフォリオサイト

![HTML5](https://img.shields.io/badge/HTML5-E34F26?logo=html5&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?logo=css3&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-jQuery-F7DF1E?logo=javascript&logoColor=black)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-success?logo=github)

🔗 **公開サイト**: https://ns7jp.github.io/

公共職業訓練（2025年10月〜2026年1月）で制作した5作品＋自学のインフラ系作品（サーバー監視ダッシュボード）の計6作品と、学習成果を掲載するポートフォリオサイトです。
本READMEは、Web初学者の方にもファイル構成・役割・しくみが伝わるよう、詳しく解説しています。

---

## このサイトの全体像（初学者向け）

このサイトは「静的サイト」と呼ばれる種類のWebページです。サーバーで毎回ページを生成するのではなく、
あらかじめ用意したHTML・CSS・JavaScriptのファイルをそのままブラウザに表示しています。

- **HTML**：ページの構造（見出し・本文・画像・リンクなど）を書く言語
- **CSS**：見た目（色・大きさ・配置・アニメーションなど）を整える言語
- **JavaScript（jQuery）**：動き（メニュー開閉・スライダー・スクロール演出など）を付ける言語
- **PHP**：お問い合わせフォームの送信処理だけサーバー側で動かす言語

GitHub Pagesという無料のホスティングサービスで公開しています。

---

## ページ構成

| ページ | ファイル | 内容 |
|--------|----------|------|
| トップ | `index.html` | ヒーロースライダー・自己紹介・スキル・作品のプレビュー |
| 自己紹介 | `me.html` | プロフィール・経歴タイムライン・取得資格 |
| スキル | `skills.html` | HTML/CSS・Python・PHP・JS・データベースなどの習熟度 |
| 作品 | `works.html` | 6作品のデモリンク・GitHubリンク・使用例・制作トラブル談 |
| 連絡先 | `contact.html` | メール・GitHubなどの連絡先情報 |

---

## フォルダ・ファイルの役割

```
pf/
├── index.html               … トップページ（最初に表示されるページ）
├── me.html                  … 自己紹介ページ
├── skills.html              … スキル一覧ページ
├── works.html               … 作品一覧ページ
├── contact.html             … 連絡先ページ
├── mail.php                 … お問い合わせフォームの送信処理（PHP対応サーバー用）
├── favicon.ico              … ブラウザのタブに表示される小さなアイコン
├── sticky_notes_data.json   … 付箋アプリのサンプルデータ（参考用）
├── README.md                … このファイル（プロジェクトの説明書）
├── .gitignore               … Gitに登録しないファイルを指定する設定
│
├── css/
│   ├── reset.css            … ブラウザごとのデフォルトスタイル差を消すリセットCSS
│   └── style.css            … サイト全体の見た目を定義するメインCSS
│
├── js/
│   └── jquery.bgswitcher.js … 背景画像を切り替えるjQueryプラグイン（外部ライブラリ）
│
└── image/                   … サイトで使用する画像ファイル群
    ├── main.jpg / main1〜7.jpg … ヒーロースライダー用の画像
    ├── pulse.png            … 作品「Pulse」のスクリーンショット
    ├── post.png             … 作品「掲示板アプリ」のスクリーンショット
    ├── teikei.png           … 作品「定型文管理アプリ」のスクリーンショット
    ├── notes.png            … 作品「付箋アプリ」のスクリーンショット
    ├── magic.png            … 作品「サンプル企業サイト」のスクリーンショット
    └── me.jpg / image.jpg ほか … 各ページのヒーロー画像・プロフィール画像
```

---

## 掲載作品

| # | 作品名 | 主な技術 | リポジトリ |
|---|--------|----------|------------|
| ① | SNSアプリ「Pulse」 | PHP / SQLite / CSRF対策 / bcryptパスワード管理 | [ns7jp/pulse](https://github.com/ns7jp/pulse) |
| ② | 掲示板アプリ | PHP / MySQL / XSS対策 | [ns7jp/post](https://github.com/ns7jp/post) |
| ③ | 定型文管理アプリ | Python / Flet / JSON | [ns7jp/works](https://github.com/ns7jp/works) |
| ④ | 付箋アプリ | Python / Tkinter | [ns7jp/works](https://github.com/ns7jp/works) |
| ⑤ | サンプル企業サイト | HTML / CSS / Vanilla JS | [ns7jp/magic](https://github.com/ns7jp/magic) |
| ⑥ | サーバー監視ダッシュボード | Python / Flask / psutil / Chart.js | [ns7jp/server-monitor](https://github.com/ns7jp/server-monitor) |

---

## 使用技術（このサイト本体）

- **HTML5**：セマンティックタグ（`header` / `nav` / `section` / `article` / `footer`）でページを構造化
- **CSS3**：Flexbox・CSS Grid・カスタムプロパティ（CSS変数）・トランジション・キーフレームアニメーション
- **JavaScript / jQuery 3.6.0**：ローダー演出、ハンバーガーメニュー、スクロール連動、ヒーロースライダー
- **Font Awesome 6.5.1**：アイコンフォント（CDN経由で読み込み）
- **Google Fonts**：Noto Sans JP / Playfair Display / Montserrat（CDN経由で読み込み）
- **GitHub Pages**：静的ファイルを無料公開できるホスティングサービス

---

## ローカルで動かす方法（初学者向け）

### 静的ページ（HTML/CSS/JSだけ）の場合
1. このフォルダをそのままダウンロード
2. `index.html` をダブルクリック → ブラウザで開く

これだけで、PHP以外のページは動作確認できます。

### お問い合わせフォーム（mail.php）も動かしたい場合
PHPはサーバー側で動く言語なので、ブラウザだけでは動きません。
ローカルで動作確認するには、**XAMPP** などのローカルサーバー環境が必要です。

1. XAMPPをインストール → Apacheを起動
2. このフォルダを `xampp/htdocs/` 内に配置
3. ブラウザで `http://localhost/pf/index.html` にアクセス

---

## 著者

**島田則幸（Noriyuki Shimada）**

- 📧 net7jp@gmail.com
- 📂 [作品リポジトリ一覧](https://github.com/ns7jp)

---

© 2026 Noriyuki Shimada. All rights reserved.
