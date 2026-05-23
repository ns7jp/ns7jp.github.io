# Support Docs — IT サポート実務向けドキュメント集

ITサポート・社内SE・運用監視業務で実際に使われる手順書・事例集をまとめたフォルダです。**Windows 11 + Microsoft 365 + Active Directory** を標準的な業務環境として想定し、現場で参考になる粒度で記述しています。

ポートフォリオ作品（Web アプリ・サーバー監視ツール）が「**コードが書けること**」の証明であるのに対し、このフォルダのドキュメントは「**手順書を整備し、ナレッジを共有できること**」の証明として用意しました。

---

## 📂 収録ドキュメント（全 12 本）

### 🛠 標準業務 手順書（4 本）

#### 1. [PC キッティング手順書](./pc-kitting-guide.md)

新入社員に Windows 11 PC を配布する際の標準手順をまとめたチェックリスト形式の手順書。受領・検品から、Windows 初期設定、Active Directory 参加、Microsoft 365 導入、セキュリティ設定、ユーザー引き渡しまで全工程を網羅しています。

#### 2. [退職者アカウント停止手順書](./account-offboarding-guide.md)

退職・異動者の AD/M365 アカウント停止と関連リソース引き継ぎの標準手順書。情報漏洩・不正アクセス・ライセンス無駄消費を防ぐための時系列フロー（最終日 → 翌営業日 → 30 日 → 90 日）と、PowerShell コマンド例を掲載。

#### 3. [共有フォルダ・アクセス権限管理手順書](./shared-folder-access-management.md)

ファイルサーバー / SharePoint / OneDrive の権限を、最小権限の原則に沿って付与・変更・削除・棚卸しするための手順書。AD グループ単位の標準設計、四半期棚卸しスクリプト、よくある落とし穴を収録。

#### 4. [Microsoft 365 ライセンス管理手順書](./m365-license-management.md)

ライセンス新規割当・変更・取消・棚卸しの標準手順書。グループベースライセンス（GBL）の活用、月次棚卸しによる利用率分析、コスト最適化の判断フローを掲載。

---

### 🚨 障害対応 / インシデント対応（3 本）

#### 5. [障害対応事例集（10 ケース）](./troubleshooting-case-studies.md)

ヘルプデスクでよく問い合わせを受ける10ケースを「**現象 → 影響範囲 → 切り分け → 想定原因 → 対応 → 再発防止**」の6項目で整理した事例集。

**含まれるケース**：PC起動不可 / ネット接続不可 / メール送受信不可 / 印刷不可 / パスワードロック / Office ライセンスエラー / VPN接続不可 / 共有フォルダアクセス不可 / PC低速化 / ファイル破損

#### 6. [重大インシデント対応プレイブック](./incident-response-playbook.md)

P1 / P2 重大度の事案で発動する、検知から事後分析までの定型フロー。役割分担（IC / Tech Lead / Comms / Scribe）、標準タイムライン、報告テンプレート、ポストモーテムの進め方をまとめています。

#### 7. [マルウェア感染疑い対応フロー](./malware-suspected-response.md)

感染兆候の判断基準から、即時隔離（5 分以内）、影響範囲の特定、検体保全、復旧、事後対応まで。電源切断 vs シャットダウンの判断基準、横展開検知の PowerShell クエリ等を収録。

---

### 📓 事後分析 / 復旧運用（2 本）

#### 8. [Postmortem 実例（共有フォルダ I/O 飽和、P2）](./postmortem-example.md)

重大インシデント対応プレイブックの「型」を、実際の振り返りに当てはめた架空のサンプル。**MTTA / MTTR / MTTM、5 Whys、応急 / 恒久 / 中期対応** を含む。`incident-response-playbook.md` と組み合わせると「型 → 実例」が一通り読めます。

#### 9. [バックアップ / リストア Runbook](./backup-restore-runbook.md)

Windows ファイルサーバー（VSS + Robocopy）と Linux サーバー（rsync + systemd timer）の 2 系統を載せ、**月次リストアテスト計画** までを含めた運用Runbook。「取れている」だけでなく「**必ず戻せる**」の証明を意識した構成。

---

### 📐 運用設計 / 変更管理（3 本）

#### 10. [DR / リストア演習記録](./dr-test-log.md)

`backup-restore-runbook.md` の手順が **机上ではなく実際に動くこと** を月次演習で検証する記録。直近 6 ヶ月分（Win VSS / Linux 単体復元 / 全停止再構築）を載せ、所要時間・RTO/RPO 達成・発見した課題・反映状況まで残しています。「Runbook 自体が腐っていないか」を継続検証する仕組み。

#### 11. [SLO / SLI / エラーバジェット定義書](./slo-definitions.md)

ファイルサーバー / Web/App / AD・DNS / 社外向け Web の **4 サービス分の SLI・SLO・エラーバジェット** を定義。`alert.rules.yml` のしきい値がどこから来ているのかを SLO から逆算した根拠付きで記述し、バジェット消費率による変更凍結フローまで含めています。

#### 12. [変更管理 / RFC テンプレート + 実例](./change-management-rfc.md)

CAB 承認を伴う構成変更プロセスのテンプレート + 実例 1 件（CR-2026-014 fs01 VSS 領域拡張）。**何を / いつ / どう変えるか / 失敗したらどう戻すか** を変更前に合意するための型と、緊急変更の事後 RFC 運用を併記。

#### 補助: [ネットワーク設計メモ — ACL / VPN / セグメント分離](./network-acl-vpn-examples.md)

`infra-lab.html` の VLAN 論理構成図に対する **L3/L4 のフィルタ設計**（Edge FW ACL 例 / VLAN 間アクセスマトリクス）と、Site-to-Site VPN・WireGuard のクライアント VPN 構成例。切り分け時の L1 → L7 の順序付きチェックも収録。

---

### 🧰 関連: 実務 PowerShell + bash スクリプト

#### → [support-scripts/](../support-scripts/)

ドキュメントから参照される実行可能スクリプト集。端末一次確認、セキュリティ監査、AD/M365 棚卸し、**Linux 一次切り分け（bash）**、**Pester ユニットテスト** まで収録し、JSON / CSV / HTML のサンプル出力も確認できます。

---

## 📋 ドキュメント整備で意識した点

- **チェックリスト化**: 抜け漏れを防ぐため、手順は番号付き or `[ ]` チェックボックスで列挙
- **想定読者の明示**: 誰のためのドキュメントかを冒頭に記載
- **環境条件の明記**: 「Windows 11 / Microsoft 365 / AD」など、適用範囲を最初に提示
- **切り分けの順序**: 現象 → 範囲 → 原因 → 対応 の順で、感覚的でなく論理的に進める構成
- **チケット化のしやすさ**: 受付内容、確認コマンド、判断、対応時間目安、エスカレーション基準を追記
- **再発防止の言及**: 単発対応で終わらせず、ナレッジとして残す視点
- **表形式の活用**: 手順／対応マトリクスは表で見やすく整理
- **ドキュメント間の連携**: 入社（キッティング）→ 異動・権限管理 → 退職（オフボーディング）の流れで相互参照
- **「型」と「実例」の対**: プレイブック（型）と Postmortem（実例）、Runbook（運用手順）と postmortem 内の改善対応をリンク

---

## ⚠️ 注意事項

- 本ドキュメントは **学習・ポートフォリオ目的の架空のサンプル** です。特定の企業の運用基準や実機構成を反映したものではありません。
- 実際の運用に流用する場合は、自社のセキュリティポリシー・IT 統制・ライセンス契約を確認したうえで適宜調整してください。
- スクリーンショットや具体的な ID／パスワード等は含めていません（公開ドキュメントのため）。

---

## 関連リンク

- 🌐 [ポートフォリオサイト](https://ns7jp.github.io/)
- 🪟 [Infra Lab (Windows / M365 / AD)](https://ns7jp.github.io/infra-lab.html) — VLAN 論理構成図、監視・証跡マトリクス
- 🐧 [Linux Lab](https://ns7jp.github.io/linux-lab.html) — systemd / journalctl / SSH / rsync の一次運用
- 📊 [Monitoring Stack](../monitoring-stack/) — Prometheus + Alertmanager + Loki + Grafana + node_exporter (docker-compose)
- ⚙️ [Ansible Playbook](../ansible/) — Linux ベースライン冪等化（実行ログサンプル付き）
- ☁️ [Azure Lab](../azure-lab/) — Terraform でハイブリッド前提の VNet / NSG / Bastion / VM を構築
- 🧰 [support-scripts/](../support-scripts/) — PowerShell + bash の確認・監査・棚卸しスクリプト
- 📂 [作品リポジトリ一覧](https://github.com/ns7jp)

---

**著者**：島田則幸（Noriyuki Shimada） / 📧 net7jp@gmail.com
