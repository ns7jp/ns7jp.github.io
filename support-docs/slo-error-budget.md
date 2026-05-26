# SLO / Error Budget — Lab 内サービスでの具体例

「監視を入れた」「アラートを設定した」までは Lab で示せますが、運用品質を**数値で語れる**ようになると、次の段階に進めます。このドキュメントは、ポートフォリオ内の Lab サービスを題材に、SLI（指標）→ SLO（目標）→ Error Budget（許容失敗量）→ 月中の運用判断、までを 1 本でつなげた具体例です。

> 数値はすべて Lab を想定した架空値です。実環境では過去 4 週間のベースラインを取り、利用者と合意して定めます。

---

## 1. SLI / SLO / Error Budget のおさらい

| 用語 | 意味 | 例 |
|---|---|---|
| **SLI**（Service Level Indicator） | サービス品質を測る**指標** | 「5xx 以外で応答した HTTP リクエストの割合」 |
| **SLO**（Service Level Objective） | SLI に対して合意した**目標値** | 「月次で 99.5% 以上」 |
| **Error Budget** | SLO を 100% から引いた**許容失敗量** | 「100% − 99.5% = 0.5%」 = 月 30 日換算で 3h 36m |
| **SLA**（Service Level Agreement） | SLO を**外部契約**化したもの。違反時のペナルティ条項を含む | 本ドキュメントでは扱わない |

「**SLO を守るためのバジェットを意識的に使う**」という考え方が運用設計の柱になります。たとえば「今月のバジェットを既に 70% 消費している」なら、新規リリースを止めて安定化に振る判断ができます。

---

## 2. 対象サービスと SLI 定義

ポートフォリオ内の Lab サービスに対し、SLI を 3 系統で定義します。

| サービス | 種別 | SLI（測定方法） |
|---|---|---|
| **file-server（fs01）** | Availability | 5 分ごとの SMB 共有マウントテストが**成功した割合**（外形監視） |
| **monitoring-stack（Grafana / Prometheus）** | Latency | `/api/health` を 1 分ごとに叩き、**応答が 1.0 秒以内に返った割合** |
| **backup ジョブ（fs01 + app01）** | Freshness | `backup_last_success_timestamp` が**過去 26 時間以内**である割合（日次 02:00 / 03:00 + 余裕 2h） |

外形監視は Prometheus の `blackbox_exporter`、ジョブの鮮度監視は `node_exporter` の textfile collector 経由で `backup_last_success_timestamp` を出力する想定です。現在の [Verified Infrastructure Lab](../verified-lab/) では HTTP ターゲットに対する `blackbox_exporter` と Alertmanager 配送を実装し、障害注入から解消通知まで自動検証します。`fs01` の SMB probe とバックアップ鮮度メトリクスは、Windows / ファイルサーバーを用意した後に実測する設計サンプルです。

---

## 3. SLO と Error Budget（月次）

| サービス | SLO | Error Budget（月 30 日換算） | 想定影響 |
|---|---|---|---|
| file-server | **99.5%** | 0.5% = **3h 36m** | 不在で書類が開けない、提出物の差し戻し |
| monitoring-stack | **99.0%**（Lab は内部利用） | 1.0% = **7h 12m** | 障害検知の遅れ、ダッシュボード閲覧不可 |
| backup（fs01 + app01）| **99.9%**（鮮度） | 0.1% = **43m / 月** | リストア時に直前 24h のデータが戻らないリスク |

> 「Lab は内部利用なので Grafana SLO を 99.0% に下げる」というのは**意図的な選択**です。すべて 99.9% に揃えると、運用工数とリリース速度の両方が圧迫されます。SLO はビジネス価値に応じて意図的に**差をつける**ものです。

### Error Budget の計算式

```
Error Budget (時間) = (1 - SLO) × 期間
                    = (1 - 0.995) × 30日 × 24時間
                    = 0.005 × 720h
                    = 3.6h ≒ 3h 36m
```

---

## 4. Error Budget の運用判断（バジェットポリシー）

月中で消費したバジェットの割合に応じて、運用上の判断を変えます。

| 消費率 | ステータス | 運用判断 |
|---|---|---|
| **0 〜 50%** | 健全 | 通常リリース可。新機能・改善を進める |
| **50 〜 75%** | 注意 | 重要な変更は事前レビュー必須。**深夜帯リリース推奨** |
| **75 〜 100%** | 警戒 | 新規リリース凍結（バグ修正・セキュリティ対応のみ）。**安定化に振る** |
| **100% 超** | バジェット枯渇 | **エラーバジェット凍結会議**を開催。原因分析・恒久対策・SLO 妥当性の再確認 |

### 月次レビューのテンプレート

```
- 対象月       : 2026-05
- 対象サービス : file-server (fs01)
- SLO          : 99.5%
- 実績         : 99.62% (達成)
- 消費バジェット: 2h 44m / 3h 36m（76% 消費）
- 主な消費要因 : 5/12 ファイルサーバー切替作業（計画停止）45m
                 5/18 ストレージ I/O 飽和（Postmortem 参照）58m
                 5/25 監視 false alarm 復旧 21m
- 判断         : 警戒水準。6 月は新規共有設定の追加を延期、I/O 飽和の恒久対策を優先
- 次回見直し   : 2026-06-30
```

---

## 5. アラート設計と SLO の連動（マルチウィンドウ・バーンレート）

「しきい値を 1 つだけ決める」のではなく、**バーンレート（バジェット消費速度）**でアラートを階層化すると、誤報（false positive）と検知漏れ（false negative）のバランスが取れます。

> バーンレート 1 = 1 ヶ月で Error Budget をちょうど使い切るペース。バーンレート 14.4 = 2 時間で月次バジェットを使い切るペース。

| アラート | 条件（短期 AND 長期） | 重大度 | 想定アクション |
|---|---|---|---|
| `FileServerFastBurn` | 1h バーンレート > 14.4 **かつ** 5m バーンレート > 14.4 | critical | 即時オンコール起床。月次バジェットの 2% を 1 時間で消費 |
| `FileServerSlowBurn` | 6h バーンレート > 6 **かつ** 30m バーンレート > 6 | warning | 当営業日内に対応。じわじわ消費している |
| `FileServerBudgetExhausted` | 残バジェット < 0 | warning（記録目的） | リリース凍結発動。原因の事後分析を起票 |

### Prometheus ルール例

```yaml
groups:
  - name: file-server-slo
    rules:
      # probe_success は probe ごとに成功=1 / 失敗=0 を返す gauge。
      # SLI: 直近 5 分に取得した probe の成功割合。
      - record: sli:fs01_smb:availability_5m
        expr: avg_over_time(probe_success{job="fs01-smb"}[5m])

      # SLO 違反率（= 1 - SLI）
      - record: slo:fs01:error_ratio_5m
        expr: 1 - sli:fs01_smb:availability_5m

      # 短期バーンレート（5m / 1h）
      - alert: FileServerFastBurn
        expr: |
          (
            slo:fs01:error_ratio_5m  > (14.4 * 0.005)
          )
          and
          (
            avg_over_time(slo:fs01:error_ratio_5m[1h]) > (14.4 * 0.005)
          )
        for: 2m
        labels:
          severity: critical
          slo: file-server
        annotations:
          summary: "fs01 SLO バーンレート 14.4 超過"
          description: "1 時間で月次 Error Budget の 2% を消費。即時切り分けを開始してください。"
          runbook: "https://ns7jp.github.io/support-docs/incident-response-playbook.md"

      # 長期バーンレート（30m / 6h）
      - alert: FileServerSlowBurn
        expr: |
          (
            avg_over_time(slo:fs01:error_ratio_5m[30m]) > (6 * 0.005)
          )
          and
          (
            avg_over_time(slo:fs01:error_ratio_5m[6h]) > (6 * 0.005)
          )
        for: 15m
        labels:
          severity: warning
          slo: file-server
        annotations:
          summary: "fs01 SLO バーンレート 6 を継続"
          description: "6 時間でバジェットの 5% 消費ペース。当営業日内に切り分けを始めてください。"
```

---

## 6. ダッシュボードに載せるもの

Grafana の SLO ダッシュボードに置く 4 パネル:

1. **SLI 実績**: 30 日移動平均（折れ線）— 99.5% ラインを赤で水平描画
2. **Error Budget 残量**: ガーゲージ（残 / 消費の割合）
3. **バーンレート**: 1h / 6h / 24h の 3 系列
4. **主要インシデントの注釈**: Postmortem の発生時刻を縦線で重ねる

---

## 7. SLO 導入のアンチパターン

| パターン | なぜダメか | 代替 |
|---|---|---|
| 全部 99.9% に揃える | 工数とリリース速度を圧迫する。**意味のない高 SLO** はバジェット枯渇を慢性化させる | サービス重要度ごとに 99.0 / 99.5 / 99.9 と階層化 |
| SLI に「サーバー稼働率」を使う | 利用者から見た失敗を捉えられない（プロセスは生きてるのに応答 5xx） | 利用者視点のリクエスト成功率や応答時間を使う |
| SLO 違反したらすぐ厳罰 | 改善のフィードバック機能が動かなくなり、計測が形骸化する | バジェット凍結 → 原因分析 → 恒久対策の順で運用 |
| アラートをしきい値 1 本で固定 | 短期スパイクで誤報 / 長期じわじわ劣化で見落とし | マルチウィンドウ + マルチバーンレート |
| SLO を技術者だけで決める | サービスの価値判断を伴う数値なので、利用者抜きでは妥当性が無い | 月次レビューに業務側を巻き込む |

---

## 8. ポートフォリオでの位置づけ

- [Monitoring Stack](../monitoring-stack/) のホスト4アラートと HTTP 外形監視アラートが **L1: 異常検知と通知配線**
- このドキュメントの SLO バーンレート設計が **L2: 影響の見える化**
- [Postmortem 実例](https://ns7jp.github.io/support-docs/postmortem-example.html) と [Backup Runbook](https://ns7jp.github.io/support-docs/backup-restore-runbook.html) の RTO/RPO が **L3: 失敗からの回復設計**

3 段が揃うと、「監視している」だけでなく「**運用品質を数値で説明できる**」が伝わります。

---

## 関連リンク

- [Monitoring Stack](../monitoring-stack/) — Prometheus / Grafana / Loki / blackbox_exporter / Alertmanager の Lab 構成
- [Verified Infrastructure Lab](../verified-lab/) — HTTP 外形監視の発火、通知、復旧を自動実証
- [Production Readiness](https://ns7jp.github.io/production-readiness.html) — 本番化で足す外部通知・認証・SSO
- [重大インシデント対応プレイブック](https://ns7jp.github.io/support-docs/incident-response-playbook.html) — 障害発生時のフロー
- [Postmortem 例](https://ns7jp.github.io/support-docs/postmortem-example.html) — Error Budget 消費の実例（架空）
- [Backup / Restore Runbook](https://ns7jp.github.io/support-docs/backup-restore-runbook.html) — RTO / RPO / DR ドリル計画
