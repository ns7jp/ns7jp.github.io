# 成果物テンプレートと完成例

実在するIP、hostname、利用者名、秘密情報は記入しません。空欄は推測で埋めず `NOT RUN` または `未確認` とします。

## 1. 要件・構成メモ

### 空テンプレート

```text
目的 / 利用者:
成功条件:
対象 / 対象外:
接続元 → 宛先 → protocol/port:
データ / backup:
許容停止時間(RTO) / 許容損失(RPO):
前提 / リスク / 戻し方:
```

### 合格水準の架空例

```text
目的 / 利用者: 学習者が管理端末からLab Webの状態を確認する
成功条件: 管理元だけSSH、clientからHTTPS、異常を5分以内にローカル検知
対象 / 対象外: Ubuntu VMとLab container / 公開DNS・本番通信は対象外
接続元 → 宛先 → protocol/port: admin → VM → TCP/22、client → proxy → TCP/443
データ / backup: 設定とtest dataを日次保存、checksumを確認
RTO / RPO: 60分 / 24時間（目標。別host実測はNOT RUN）
前提 / リスク / 戻し方: NAT内、snapshot取得、consoleからrollback
```

この例は「目的、通信、対象外、目標、戻し方」が試験へ追跡できるため設計区分12点相当です。以下に16点・20点相当の架空の記入例を示します。

### 16点相当の架空例

```text
目的 / 利用者: 学習者が管理端末からLab Webの状態を確認し、障害を自分で切り分けられるようにする
成功条件: 管理元だけSSH、clientからHTTPS、異常を5分以内にローカル検知、切り分け手順で原因箇所まで特定できる
対象 / 対象外: Ubuntu VMとLab container、監視・alert経路 / 公開DNS・本番通信・複数VM構成は対象外
接続元 → 宛先 → protocol/port: admin → VM → TCP/22、client → proxy → TCP/443、monitor → exporter → TCP/9100（各通信をfailure-drills.mdの該当drillへ対応付け）
データ / backup: 設定とtest dataを日次保存、checksumを確認、復元手順書へ追跡できる
RTO / RPO: 60分 / 24時間（目標。別host実測はNOT RUN。lab-guide.md Step7で実施予定）
前提 / リスク / 戻し方: NAT内、snapshot取得、consoleからrollback、各リスクの試験項目をsecurity-threat-model.mdへ記載
```

この例（架空の記入例）は要件の各項目を試験手順まで追跡できるため設計区分16点相当です。

### 20点相当の架空例

```text
目的 / 利用者: 学習者が管理端末からLab Webの状態を確認し、障害を自分で切り分けて復旧できるようにする
成功条件: 管理元だけSSH、clientからHTTPS、異常を5分以内にローカル検知、非機能要件（可用性・性能の目標値）を明記し達成有無を判定できる
対象 / 対象外: Ubuntu VMとLab container、監視・alert経路、脅威モデルの主要リスク / 公開DNS・本番通信・複数VM構成は対象外（理由: 個人検証環境のため）
接続元 → 宛先 → protocol/port: admin → VM → TCP/22、client → proxy → TCP/443、monitor → exporter → TCP/9100（security-threat-model.mdの通信フロー表と対応、各行の脅威・軽減策・受容理由を記載）
データ / backup: 設定とtest dataを日次保存、checksumを確認、暗号化方式と鍵の保管場所を明記、復元試験の合否まで追跡
RTO / RPO: 60分 / 24時間（目標として明記。別host実測はNOT RUN、lab-guide.md Step7で実施予定）
前提 / リスク / 戻し方: NAT内、snapshot取得、consoleからrollback。各リスクについて受容・軽減・移転・回避のどれを選んだか理由付きで記載
```

この例（架空の記入例）は非機能要件・脅威ごとの判断理由まで説明しているため設計区分20点相当です。いずれも架空の記入例であり、実際に検証した結果ではありません。

## 2. 作業・確認記録

```text
日時 / 実施者 / 環境 / commit:
変更目的 / 対象 / 承認:
事前状態 / backup / rollback:
実行コマンド:
期待結果:
実際の結果 / exit code:
変更後の別手段での確認:
判定: PASS / FAIL / NOT RUN
証跡の保存先 / 秘密情報確認:
```

## 3. 障害記録

```text
検知時刻 / 着手 / 復旧:
現象 / 利用者影響 / 直前変更:
事実 / 推測 / 未確認:
仮説 → 確認 → 結果 → 次の判断:
原因 / 暫定復旧 / 恒久対策:
実測RTO / RPO / 残課題:
```

## 4. 引き渡し報告

```text
完了した範囲:
受入試験と結果:
日常確認 / alert時のRunbook:
backup / restore結果:
未実施(NOT RUN) / 既知の制約:
rollback / 緊急連絡:
廃棄する環境と期限:
```

## 自己採点

[修了判定ルーブリック](./assessment-rubric.md)の各区分について、点数だけでなく根拠ファイルを1つ以上記載します。完成例をコピーしただけの項目や未実施項目は加点しません。
