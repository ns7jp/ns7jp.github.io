# 動作確認の詳細と過去の検証履歴

[動作確認の記録へ戻る](https://ns7jp.github.io/evidence-demo.html)／[現在の検証証跡台帳](https://github.com/ns7jp/server/blob/main/docs/evidence/README.md)

2026年8〜9月の紹介ページから分けた履歴です。数値は当時の対象版・実行環境での結果で、本人の独力再現や最新コード全体の合格を示すものではありません。後日の本人実習とAI実行は台帳から別々に確認できます。

## 本人PC上のVMへのAnsible基盤適用（2026-09-04）

AIの手順案内を受けた本人操作です。[Ubuntuの結果票](https://github.com/ns7jp/server/blob/main/docs/evidence/2026-09-04-ansible-foundation-build.md)では、Hyper-VのVMへfoundation.yml（基本設定とDocker）を適用し、鍵接続、Dockerの動作、2回目の変更なしなどを記録しています。対象版は44cf16aです。[AlmaLinux 9.7の結果票](https://github.com/ns7jp/server/blob/main/docs/evidence/2026-09-04-ansible-foundation-el9-build.md)は537d9be相当と記載されています。後者は既存VMの再利用で別用途のサービスが残り、新規構築・SSHだけの最小公開は未証明です。

これらは監視全体のsite.yml適用や72時間稼働・本番運用の完了を示すものではありません。

## CIの構築・復旧試験（2026-08-22）

[23項目の実行記録](https://github.com/ns7jp/server/blob/4a292026b569dd1a522c0f2913b4ad40aeccebe7/docs/evidence/2026-08-22-full-stack-e2e.md)はDocker導入済みの一時Ubuntu環境での結果です。[8月19日の試験結果](https://github.com/ns7jp/server/blob/0d82d6865db8f5198bb16bc44b670b97ffb4726f/docs/evidence/2026-08-19-build-validation.md)とは対象版・範囲を分けています。

| 区分 | 確認済み | どこまで試したか | 状態 |
| --- | --- | --- | --- |
| 構築・再実行 | 同じ構築手順を2回実行し、2回目に不要な変更が出ないこと | Docker導入済みの一時Ubuntu環境 | 合格 |
| 起動・通知 | 11サービスの起動と、異常・復旧の通知 | テスト環境内の通知のみ。Slackへの送信は未実施 | 合格 |
| Docker情報の読み取り制限 | 情報は読めるが、設定を変える操作は拒否されること | 対象版 `7622a9d` の自動テスト内 | 合格 |
| ネットワーク | 通信経路、待ち受けポート、ファイアウォール、サービス間通信 | 同じ一時環境内のみ。別の管理PCや社内DNSは未実施 | 合格 |
| 障害・データ復旧 | アプリを1秒で復旧し、監視データ3種類を復元 | サーバー本体の故障と長時間の連続運転は未実施 | 合格 |

11サービスの内訳は監視10＋通知確認1です。通知先はテスト環境内のlocal webhookです。

当該CIには、Docker未導入の最小OSへの導入、別の管理PC・社内DNSからの確認、独立した対象サーバーの受け入れ・切り戻し、再起動後・72時間稼働、Slack実通知、AWSの作成・削除、D-2は含まれません。後日の別記録と合算して通し試験済みとは表現しません。

翌8月23日の[切り戻し試験](https://github.com/ns7jp/server/actions/runs/32611251044)も一時CI環境です。新しい版を確認してから指定した前の版へ戻した記録で、継続利用する独立サーバーでの結果ではありません。

## AI側の作業環境での追加演習（2026-08-24）

B-1〜B-4はAI支援セッションがAI側の作業環境（仮想ディスク付きUbuntu、Docker、Linux内の分離環境）で実行したものです。本人PCのWSL2での実績には加えません。B-2・B-3は本人の環境で通して実行した記録ができるまで、面談で実演できるとは表現しません。

| 演習 | 内容 | 結果 |
| --- | --- | --- |
| B-1 ディスク容量の追加 | 使える領域を作り、容量が足りなくなった状態から領域を広げる | [5項目合格 / 不合格0](https://github.com/ns7jp/server/blob/main/docs/drills/logs/2026-08-24-B-1.md)（220M→457M） |
| B-2 問題が起きた場所の確認 | Web・アプリ・データベースのどこで止まっているかを順に確認する | [9項目合格 / 不合格0](https://github.com/ns7jp/server/blob/main/docs/drills/logs/2026-08-24-B-2.md) |
| B-3 データベースの復元 | バックアップからデータベースを戻し、内容が元と一致するか確認する | [7項目合格 / 不合格0](https://github.com/ns7jp/server/blob/main/docs/drills/logs/2026-08-24-B-3.md)（復旧0.149秒） |
| B-4 ネットワーク設定の確認 | 同じネットワーク内と、別のネットワーク間の通信設定を確認する | [6項目合格 / 不合格0 / 環境の制約で3項目は未実施](https://github.com/ns7jp/server/blob/main/docs/drills/logs/2026-08-24-B-4.md) |

B-4の3項目は環境の制約で未実施です。220M→457Mは利用できる容量、0.149秒はこの記録条件でのDB復旧計測であり、実システムの復旧保証ではありません。

8月25日までの記録では実行中に見つけた問題は29件、うち壊れているのに合格と判定したものは6件でした。[欠陥台帳](https://github.com/ns7jp/server/blob/main/docs/evidence/defects-found.md)は10月時点で49件となり、各記録時点を分けています。Ubuntu以外のLinux向け[CI](https://github.com/ns7jp/server/actions/runs/32811100007)と[設定](https://github.com/ns7jp/server/tree/main/ansible/roles/common/molecule/el9)はコンテナ内の検証です。9月4日の再利用AlmaLinux VMへの基盤適用とも区別します。

## 自動テストで見つけた失敗と修正

- [最初の実行](https://github.com/ns7jp/server/actions/runs/32571650745)：変数を書く位置の誤りを検出し、位置を修正。
- [次の実行](https://github.com/ns7jp/server/actions/runs/32571890175)：一時ファイルと同期処理の競合で、再実行時にも不要な変更が発生。実行方法を修正。
- [修正後の実行](https://github.com/ns7jp/server/actions/runs/32572409469)：再実行、起動、通信制限、ネットワーク、復旧・復元を再確認。合否は上記の対象版・一時環境での結果です。

## D-1の失敗と再試行（2026-08-19）

[原記録](https://github.com/ns7jp/server/blob/0d82d6865db8f5198bb16bc44b670b97ffb4726f/docs/drills/logs/2026-08-19-D-1.md)には、最初は停止後に自動復旧せず5分で中止し、停止方法を変更した経緯が残っています。2回目は古いコードを使用していたことが判明。対象コードをそろえた3回目で13秒の復旧を確認しました。途中のnginxの名前解決失敗やWSL2のマウント設定の問題も原記録にあります。

このWSL2の記録は実行者が未記載であり、[主作品の区分](https://github.com/ns7jp/server/blob/main/docs/project-reference.md)に従い本人操作の実績には加えません。8月22日のCIでの1秒復旧とは別環境・別日付の結果です。

## 2分15秒の動作確認動画

[動画を見る](https://ns7jp.github.io/demo.html)／[連続撮影の手順案](https://github.com/ns7jp/server/blob/main/docs/demo-capture-guide.md)

8月18日・19日の画面とログを再構成した映像です。連続した操作録画ではなく、8月22日の自動テストやSlack実通知は含みません。
