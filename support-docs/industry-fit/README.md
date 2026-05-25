# Industry Fit — 応募先業種別の追記

「インフラ運用支援」と一括りで言っても、**製造業情シス / SaaS・Web 系 / SIer・MSP / 中小情シス** では評価軸が大きく違います。このフォルダは、応募先業種ごとに **本ポートフォリオのどこを強調するか / 何を補強するか** を整理した追記メモです。

書類選考時に応募先に合わせた 1 枚を添付できるよう、各業種で:

- **業界が重視する観点**
- **本ポートフォリオで対応する成果物**
- **追加で口頭で補足する点**
- **入社後 3 ヶ月の進め方**

を見開き 1 枚で示します。

---

## 収録ファイル

| ファイル | 主な業種 | 規模感 |
|---|---|---|
| [`manufacturing-it.md`](./manufacturing-it.md) | 製造業情シス（自動車部品 / 食品 / 化学 / 機械） | 500〜5000 人 |
| [`saas-sre.md`](./saas-sre.md) | SaaS / Web スタートアップ・成長企業の SRE 補助 | 50〜500 人 |
| [`sier-msp.md`](./sier-msp.md) | SIer / MSP / クラウドベンダー一次受 | 1000+ 人 |
| [`small-it-team.md`](./small-it-team.md) | 中小情シス・1 人情シス補助 | 50〜500 人 |

---

## 使い方

書類選考や面接前に:

1. 応募先の事業内容・規模・募集要項から該当業種を特定
2. 該当業種のファイルをそのままメール添付 or ポートフォリオ URL の最後に追記
3. 面接ではここに書いた「**追加で口頭で補足する点**」を念頭に置く

応募先が複数業種にまたがる場合（例: 製造業の DX 子会社で SaaS 寄り）は、両方を読み合わせます。

---

## 全業種共通の核

業種特化と関係なく、本ポートフォリオで一貫して見せている軸:

| 軸 | 中身 |
|---|---|
| **手順化** | 15 手順書 + Pester 25 テスト + チケット分類フロー |
| **再現性** | Ansible playbook + Terraform validate + Docker Compose |
| **観測性** | Prometheus + Grafana + Loki + Promtail + 2 ダッシュボード |
| **数値化** | SLO / Error Budget / RTO / RPO / DR ドリル |
| **証跡** | CI 検証 + 実行トレース + 失敗→修正対比 + ビジュアルモックアップ |

業種特化追記は、上記の核に**重み付けと不足分の補強**を加える形です。

---

## 関連リンク

- [Resume (1pager)](https://ns7jp.github.io/resume.html) — 経歴・readiness マトリクス
- [面接 想定 FAQ](../interview-faq.md) — 10 問の自答
- [SLO / Error Budget](../slo-error-budget.md) — 運用品質の数値化
- [チケット分類](../ticket-taxonomy.md) — ITIL 4 区分
- [物理層](../office-it-physical-layer.md) — ラック / LAN / UPS / 複合機
- [M365 ポリシー JSON](../m365-policy-examples/) — Intune / 条件付きアクセス / Defender
