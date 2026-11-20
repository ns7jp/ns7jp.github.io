# 島田則幸のポートフォリオサイト

物流現場で新人向けの地図とチェックリストを作った経験を、社内ヘルプデスクの一次対応に生かしたいと考えています。[応募用の自己紹介](https://ns7jp.github.io/resume.html#helpdesk-intro)に、志望理由をまとめました。

[共有フォルダが開けないときの模擬チケット](https://github.com/ns7jp/ns7jp/blob/main/docs/helpdesk-intake.md)では、打ち合わせの期限を聞き、権限担当に引き継ぎ、利用者が資料を開けるまで連絡を続ける流れを紹介しています。

**[公開サイトを見る](https://ns7jp.github.io/)** ／ 技術実習：[サーバー構築・監視ラボ `server`](https://github.com/ns7jp/server)

[![Static site check](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/static-check.yml)
[![Infrastructure checks](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml/badge.svg)](https://github.com/ns7jp/ns7jp.github.io/actions/workflows/infra-check.yml)

## はじめに見てほしいページ

| 採用向けに確認したいこと | ページ |
| --- | --- |
| 共有フォルダを開けない利用者に、何を聞き、どう案内するか | [受付から業務再開までの模擬チケット](https://github.com/ns7jp/ns7jp/blob/main/docs/helpdesk-intake.md) |
| Windowsの検証環境で本人が何を確かめたか | [AIの案内による部署別の共有アクセス試験](https://github.com/ns7jp/server/blob/main/docs/evidence/2026-11-10-kvm-ad-client-access-gpo.md) |
| サイトが開けないとき、何を確かめるか | [Codexによるネットワークの測定と利用者への連絡例](learning-docs/network-triage-lab.md) |
| 何を作り、どこまで取り組んだか | [制作概要](https://ns7jp.github.io/project-brief.html) |
| 実際の結果・失敗・未確認範囲 | [動作確認の記録](https://ns7jp.github.io/evidence-demo.html) |
| 経歴・資格・応募情報 | [履歴書](https://ns7jp.github.io/resume.html)・[自己紹介](https://ns7jp.github.io/me.html) |
| 作業時の確認・相談・報告 | [仕事の進め方](https://ns7jp.github.io/work-readiness.html) |

## 学習用のページ

[学習ルート](https://ns7jp.github.io/learning-path.html)から、環境準備・最小構成・監視・復旧へ進めます。文字での操作が初めてなら、[環境準備](learning-docs/environment-setup.md)と[最初の30分](learning-docs/first-30-minutes.md)を参照してください。

全ページと教材の案内、ファイル構成、技術の説明は[サイトの詳細資料](docs/site-reference.md)、コードの読み方は[CODE_WALKTHROUGH.md](CODE_WALKTHROUGH.md)にまとめています。

## 開発体制について

文書・コード・テストの作成と操作の案内に、Claude Code / Codexを利用しています。個人学習の記録であり、本人操作・AI実行・CIの結果を分けて示しています。AIなしでの独力再現・説明は未確認です。[支援範囲の詳細](https://github.com/ns7jp/ns7jp/blob/main/docs/resume.md#4-b-ポートフォリオにおける-ai-支援の範囲)

## ローカルで確認する方法

Pythonを使い、リポジトリ直下をローカル配信します。

```bash
git clone https://github.com/ns7jp/ns7jp.github.io.git
cd ns7jp.github.io
python -m http.server 8000 --bind 127.0.0.1
```

起動後に [localhost:8000](http://localhost:8000/) を開きます。終了は `Ctrl+C` です。

## 検査

Node.js・Bash・Makeがある環境で、リンク、HTML構造、アクセシビリティなどを確認します。

```bash
make check
```

外部URLの到達確認は別途 `node scripts/check-external-links.js` を実行します。相手側の一時障害でも失敗するため、通常の必須検査には含めていません。全CI項目は[静的サイト検査](.github/workflows/static-check.yml)を参照してください。

<details>
<summary>以前のREADMEの節から探す</summary>

<a id="実施状況"></a><a id="このサイトの目的"></a><a id="このサイトの全体像"></a><a id="閲覧の流れ"></a><a id="ページ構成"></a><a id="indexhtml"></a><a id="mehtml"></a><a id="skillshtml"></a><a id="workshtml"></a><a id="contacthtml"></a><a id="support-docs"></a><a id="support-scripts"></a><a id="フォルダファイルの役割"></a><a id="掲載成果物"></a><a id="このサイト本体で使っている技術"></a><a id="html5"></a><a id="css3"></a><a id="javascriptvanilla-js"></a><a id="font-awesome"></a><a id="google-fonts"></a><a id="github-pages"></a><a id="初学者向けの学習ポイント"></a><a id="制作で意識したこと"></a>

実習の詳しい条件、教材・ページ一覧、ファイル構成、技術の説明は[サイト構成・教材・技術の詳細](docs/site-reference.md)へ移しました。

</details>

## 著者

島田則幸（Noriyuki Shimada）／ [連絡先](https://ns7jp.github.io/contact.html)

## ライセンス

[LICENSE](LICENSE)を参照してください。コード例・手順書は学習とポートフォリオ確認向けに公開しています。プロフィール・履歴書・人物写真など、個人情報を含む素材の無断利用は避けてください。
