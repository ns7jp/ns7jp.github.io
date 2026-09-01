# 小さな脅威モデル

> 以下の通信フロー表にあるbastion/app/monitor/collectorなどは、複数台のネットワーク構成ではなく、[lab-guide.md Step 0](./lab-guide.md#step-0--安全境界と環境採録)で定義する単一VM内の論理的な役割分担として読みます。実際に複数ホストへ分離した構成の通信は本ドキュメントの対象外です。

## 保護対象と境界

- 保護対象: 管理鍵、設定、監視データ、backup、操作証跡。
- 利用者: 管理者、閲覧者、自動化用service account。
- 境界: 管理端末、Internet/edge、bastion、private server、monitoring、backup先。

## 通信フロー

| # | 通信元 → 先 | Protocol / port | 理由 | 拒否条件 | Log |
|---|---|---|---|---|---|
| 1 | 管理端末 → bastion | SSH / 22 | 管理 | 管理CIDR外、鍵不一致 | auth / firewall |
| 2 | bastion → app | SSH / 22 | private管理 | bastion SG（Security Group：VM/host単位で通信を許可・拒否するcloudの設定）外 | auth / flow |
| 3 | monitor → exporter | HTTP / 9100 | metrics取得 | monitor外、書込 | Prometheus / firewall |
| 4 | collector → Loki | HTTP / 3100 | log転送 | collector外 | Loki |
| 5 | Alertmanager → 通知先 | HTTPS / 443 | alert通知 | 未承認先 | Alertmanager |

## 脅威と確認

| 脅威 | 予防 | 検知・確認 | 現在地 |
|---|---|---|---|
| SSH全世界公開 | `admin_cidr`必須、`0.0.0.0/0`拒否 | Terraform validation | 実装済み、apply NOT RUN |
| 秘密情報のcommit | environment / GitHub Secrets | 高確度パターンのCI検査、目視 | CI追加済み |
| 過剰権限 | 専用user、read-only mount | write拒否test | 一時環境で実測履歴あり |
| 不正変更 | PR、review、required check | CIとaudit log | CIあり、required設定 NOT SET |
| 脆弱image | version固定、更新手順 | image scanner | scanner導入はNOT SET |
| log消失・改ざん | 外部転送、保存期間、時刻同期 | 欠損alert、restore | 外部保管 NOT RUN |
| backup利用不能 | checksum、世代、暗号化 | 別host restore | 別host NOT RUN |
| 監視自身の停止 | dead-man alert（監視自身の停止を検知する逆方向のalert）、別経路 | heartbeat欠損 | NOT RUN |

受容、軽減、移転、回避のどれを選んだかと理由を変更記録へ残します。
