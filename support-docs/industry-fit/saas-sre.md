# SaaS / Web SRE 補助 向け追記

「SaaS 提供企業 / Web スタートアップ / 成長企業」の **SRE / インフラ補助 / DevOps 支援** ポジションを志望する場合の本ポートフォリオの読み方と、口頭補足のポイントです。

SaaS / Web 系は「**SLO で会話する文化**」「**観測性 (Observability) の三本柱**」「**コード化された運用 (IaC + GitOps)**」「**ポストモーテム文化**」に特徴があります。

> 私（島田）は本領域の業務経験は未経験ですが、Lab で SLO / Loki / Terraform / Postmortem を扱える状態にしており、SRE 補助の入口としての準備度を提示できます。

---

## SRE / Web 系が重視する 6 つの観点

| # | 観点 | 理由 |
|---|---|---|
| 1 | **SLO / Error Budget で会話する** | しきい値の機械的監視より、利用者体感 × 数値合意 |
| 2 | **観測性の三本柱 (Metrics / Logs / Traces)** | 障害時に「どこを見るか」の標準化 |
| 3 | **IaC + GitOps** | 設定変更は PR で、自動適用 + ロールバック容易 |
| 4 | **ブラム文化を持たない Postmortem** | 個人責任ではなく、システム / プロセス改善視点 |
| 5 | **オンコール文化** | 持ち回りで責任分担、ローテーション設計 |
| 6 | **継続的な改善 (Toil 削減)** | 繰り返し作業をコード化し、人間は判断に集中 |

---

## 本ポートフォリオで対応する成果物

| 重視観点 | 対応する成果物 |
|---|---|
| SLO / Error Budget | [SLO ドキュメント](../slo-error-budget.md) — SLI 定義 → SLO 値 → Error Budget → マルチウィンドウ・バーンレート Prometheus ルール → 月中の運用判断 |
| 観測性 (Metrics) | [Monitoring Stack](../../monitoring-stack/) — Prometheus + Grafana + node_exporter + 4 アラート + Node Overview ダッシュボード |
| 観測性 (Logs) | [Monitoring Stack](../../monitoring-stack/) — Loki + Promtail + Logs Overview ダッシュボード。systemd journal / Docker / /var/log を統合 |
| 観測性 (Traces) | 本番化差分として [Production Readiness](../../production-readiness.md) に明記 (Tempo / OpenTelemetry) |
| IaC + GitOps | [Cloud Lab Terraform](../../cloud-lab/) — fmt / init / validate を CI で実行。[Ansible Playbook](../../ansible/) — `--check --diff` で事前確認 |
| Postmortem | [Postmortem 実例](../postmortem-example.md) — MTTA / MTTR / 5 Whys / 応急対応 / 恒久対応。[インシデント対応プレイブック](../incident-response-playbook.md) — IC / Tech Lead / Comms / Scribe 役割分担 |
| オンコール | [面接 FAQ](../interview-faq.md) Q7 — 夜間オンコール対応への姿勢 |
| Toil 削減 | [Support Toolkit](../../support-scripts/) — PowerShell 9 本 + Pester 25 テスト + GitHub Actions で自動化 |

---

## SaaS / Web 特化で追加で言及する点

### 1. SLO は数値だけでなく文化

ドキュメントには「**SLO 99.5%**」と書きやすいですが、本質は「**Error Budget を意識した行動**」です。

- バジェット消費が早い月 → リリース凍結を提案
- バジェットが余っている月 → 攻めの実験を許容
- バジェット計算結果は**業務側にも見せて意思決定材料化**

本ポートフォリオの [SLO ドキュメント §4](../slo-error-budget.md#4-error-budget-の運用判断バジェットポリシー) で消費率に応じた運用判断を整理しているのは、この文化を理解した上での記述です。

### 2. オンコール初心者として始める前提

未経験のためオンコールはセカンダリ（バックアップ）から入り、

- 既存のオンコールメンバーの**通報を全件読む**（最初の 1 ヶ月）
- ペアでオンコール対応に同席（2 ヶ月目）
- 軽微なインシデントから主担当（3 ヶ月目）

の段階を踏みたい、と面接で正直に伝えます。Lab で[インシデント対応プレイブック](../incident-response-playbook.md)の型は身につけていますが、本番の重みは別物と理解しています。

### 3. Datadog / New Relic / PagerDuty / Slack の知識

本ポートフォリオは OSS スタック (Prometheus + Loki + Grafana) で固めていますが、SaaS / Web 系では商用観測スタックが多いです。

- **Datadog / New Relic**: APM, RUM, ログ統合 — Lab の Prometheus + Loki と概念は同じ
- **PagerDuty / Opsgenie**: アラート配送 / オンコール管理 — Alertmanager の代替
- **Slack / Microsoft Teams**: 通知 + 障害コミュニケーション — Webhook で連携

「商用ツールは未経験」を隠さず、「**概念は OSS スタックで把握しており、API ドキュメント読みながら 1-2 週間でキャッチアップする**」と伝えます。

### 4. Kubernetes 周辺

本ポートフォリオは Docker Compose レベルで止めており、Kubernetes は Lab に含めていません。SaaS / Web 系で K8s 必須の場合は、

- **入社後の最優先キャッチアップ対象**として明示
- 個人でローカル kind / k3s 環境を構築し、基本オペレーションを 1 ヶ月以内に身につける
- Helm / Argo CD は段階的に習得

を計画として伝えます。資格は CKAD / CKA を視野に。

---

## 入社後 3 ヶ月の進め方 (SRE 補助想定)

| 期間 | 目標 | 具体物 |
|---|---|---|
| 1 週目 | サービス全体構成 / SLO 一覧 / オンコール体制を把握 | システム俯瞰図 + SLO 一覧の自分用整理メモ |
| 2-4 週目 | 既存ダッシュボード / アラートルールを通読 + 改善候補リスト化 | Grafana / Datadog ダッシュボード読解メモ |
| 2 ヶ月目 | セカンダリオンコール + Postmortem への参加 | 自分が同席したインシデント 3 件のサマリー |
| 3 ヶ月目 | Toil 削減タスクを 1 件主担当 (例: 棚卸し自動化 / アラート整理) | 削減時間の数値化 + PR マージ |

---

## 補強したい技術 (応募までに / 入社後に)

| 領域 | 状態 | 補強計画 |
|---|---|---|
| **Kubernetes** | 未着手 | kind / k3s で Lab 構築、kubectl 基本操作、Pod / Deployment / Service / Ingress |
| **Helm / Argo CD** | 未着手 | Helm chart 作成、Argo CD で GitOps 検証 |
| **Datadog / New Relic** | 概念のみ | フリーティアでアカウント開設、ダッシュボード 1 枚作成 |
| **Tempo / Jaeger (Traces)** | 概念のみ | Monitoring Stack に Tempo を追加し、OpenTelemetry でアプリ計装 |
| **資格** | ITパスポート (2026-06 予定) | LPIC-1 → CKAD → AWS SAA |

---

## 関連リンク

- [Resume (1pager)](https://ns7jp.github.io/resume.html)
- [SLO / Error Budget](../slo-error-budget.md) — 運用品質の数値化
- [Monitoring Stack](../../monitoring-stack/) — Metrics + Logs の Lab
- [Postmortem 実例](../postmortem-example.md) — 振り返りの型
- [面接 想定 FAQ](../interview-faq.md) — 強み弱み・オンコール姿勢
