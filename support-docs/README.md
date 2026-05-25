# Support Docs — IT サポート実務向けドキュメント集

ITサポート・社内SE・運用監視業務で実際に使われる手順書・事例集をまとめたフォルダです。**Windows 11 + Microsoft 365 + Active Directory** を標準的な業務環境として想定し、現場で参考になる粒度で記述しています。

ポートフォリオ作品（Web アプリ・サーバー監視ツール）が「**コードが書けること**」の証明であるのに対し、このフォルダのドキュメントは「**手順書を整備し、ナレッジを共有できること**」の証明として用意しました。

---

## 📂 収録ドキュメント（全 15 本 + M365 ポリシー定義 7 ファイル）

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

### 🔁 変更作業ケース（1 本）

#### 5. [AD / Microsoft 365 変更作業ケース](./ad-m365-change-case.md)

部署異動に伴う AD 属性、所属グループ、共有フォルダ権限、M365 ライセンス確認を、**変更申請 → 事前確認 → 作業 → 検証 → 証跡保存 → ロールバック** の流れで整理した実務寄りのケースです。

---

### 🚨 障害対応 / インシデント対応（3 本）

#### 6. [障害対応事例集（10 ケース）](./troubleshooting-case-studies.md)

ヘルプデスクでよく問い合わせを受ける10ケースを「**現象 → 影響範囲 → 切り分け → 想定原因 → 対応 → 再発防止**」の6項目で整理した事例集。

**含まれるケース**：PC起動不可 / ネット接続不可 / メール送受信不可 / 印刷不可 / パスワードロック / Office ライセンスエラー / VPN接続不可 / 共有フォルダアクセス不可 / PC低速化 / ファイル破損

#### 7. [重大インシデント対応プレイブック](./incident-response-playbook.md)

P1 / P2 重大度の事案で発動する、検知から事後分析までの定型フロー。役割分担（IC / Tech Lead / Comms / Scribe）、標準タイムライン、報告テンプレート、ポストモーテムの進め方をまとめています。

#### 8. [マルウェア感染疑い対応フロー](./malware-suspected-response.md)

感染兆候の判断基準から、即時隔離（5 分以内）、影響範囲の特定、検体保全、復旧、事後対応まで。電源切断 vs シャットダウンの判断基準、横展開検知の PowerShell クエリ等を収録。

---

### 📓 事後分析 / 復旧運用（2 本）

#### 9. [Postmortem 実例（共有フォルダ I/O 飽和、P2）](./postmortem-example.md)

重大インシデント対応プレイブックの「型」を、実際の振り返りに当てはめた架空のサンプル。**MTTA / MTTR / MTTM、5 Whys、応急 / 恒久 / 中期対応** を含む。`incident-response-playbook.md` と組み合わせると「型 → 実例」が一通り読めます。

#### 10. [バックアップ / リストア Runbook](./backup-restore-runbook.md)

Windows ファイルサーバー（VSS + Robocopy）と Linux サーバー（rsync + systemd timer）の 2 系統を載せ、**サービス別 RTO/RPO 表**、**月次リストアテスト計画**、**年次 DR ドリル計画（火災 / DC 障害 / ランサムウェア）** までを含めた運用Runbook。「取れている」だけでなく「**目標時間内に必ず戻せる**」の証明を意識した構成。

---

### 🎯 運用設計 / SRE (3 本)

#### 11. [SLO / Error Budget](./slo-error-budget.md)

Lab 内サービスを題材に、**SLI 定義 → SLO 値 → Error Budget 計算 → 月中の運用判断**までを 1 本で示した SLO 設計の具体例。マルチウィンドウ・バーンレート Prometheus ルールも記載。

#### 12. [チケット分類 / 受付の型（ITIL 4 区分）](./ticket-taxonomy.md)

**インシデント / サービスリクエスト / 問題 / 変更**の 4 区分と、受付フローチャート（Mermaid）、それぞれの受付テンプレート（時系列タイムライン形式）。

#### 13. [オフィス IT / 物理層](./office-it-physical-layer.md)

[VLAN 論理構成図](../infra-lab.html) の対となる**物理層**ドキュメント。ラック搭載 / LAN 配線 / UPS A/B 系統 / 無線AP / 複合機 / 物理セキュリティの棚卸テンプレと切り分け順。

---

### 🎤 面接 / 自答 (1 本)

#### 14. [面接 想定 FAQ](./interview-faq.md)

選考で問われやすい 10 問の自答メモ（製造業 18 年からなぜ IT、強み弱み、3 ヶ月で何を学ぶか 等）。

---

### 🔐 M365 ポリシー定義サンプル (7 ファイル)

#### 15. [M365 / Intune / Entra ID / Defender ポリシー](./m365-policy-examples/)

Intune Compliance Policy / Configuration Profile、Conditional Access、Defender ASR を **JSON 定義**で公開。Graph SDK 経由で適用する PowerShell サンプル、棚卸しレポートスクリプトも収録。

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
- ☁️ [Cloud Lab](https://ns7jp.github.io/cloud-lab.html) — AWS VPC / Security Group / Terraform validate
- 🐧 [Linux Lab](https://ns7jp.github.io/linux-lab.html) — systemd / journalctl / SSH / rsync の一次運用
- 📊 [Monitoring Stack](../monitoring-stack/) — Prometheus + Grafana + node_exporter (docker-compose)
- ⚙️ [Ansible Playbook](../ansible/) — Linux ベースライン冪等化
- ✅ [Infra Evidence](../infra-evidence/) — 実行証跡サンプルとCI検証観点
- 🛡 [Production Readiness](../production-readiness.md) — 本番化で足す運用観点
- 🧰 [support-scripts/](../support-scripts/) — PowerShell + bash の確認・監査・棚卸しスクリプト
- 📂 [作品リポジトリ一覧](https://github.com/ns7jp)

---

**著者**：島田則幸（Noriyuki Shimada） / 📧 net7jp@gmail.com
