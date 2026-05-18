# SLO / SLI 定義とアラートしきい値の根拠

社内サポート規模 (100-500 名) の業務系サービスを想定した SLO / SLI とエラーバジェットの設計メモです。「なぜ CPU 85% なのか」「なぜ 10 分なのか」 を後から検証できるよう、しきい値の **根拠と運用上のトレードオフ** を残します。

> このページは `monitoring-stack/prometheus/alert.rules.yml` と対応関係にあります。

---

## 1. サービスごとの SLO

| サービス | SLI | SLO (月間) | エラーバジェット | 観測手段 |
|---|---|---|---|---|
| ファイルサーバー (SMB) | 接続成功率 | 99.5% | 月 3h 38m | `smbstatus` + journald |
| Active Directory (DNS/Kerberos) | DNS 名前解決成功率 | 99.9% | 月 43m | blackbox_exporter / Probe |
| 社内 Web (社内ポータル) | 5xx を返さない応答率 | 99.0% | 月 7h 18m | nginx access log → Loki |
| メール (M365 Exchange Online) | (Microsoft 側 SLA) 99.9% | 月 43m | M365 Service Health |
| 監視 (Prometheus + Grafana) | scrape 成功率 | 99.0% | 月 7h | up{job=~".+"} メトリクス |

**運用ルール**
- エラーバジェットの 50% を超えて消費 → リリース凍結、根本原因対応を優先
- 75% を超えて消費 → ポストモーテム必須 (`support-docs/postmortem-example.md` 形式)
- バジェット内ならリリース速度を優先 (過剰な信頼性投資はしない)

---

## 2. アラートしきい値の根拠

### 2.1 `HostHighCpu`: CPU 85% を 10 分継続 → warning

| 観点 | 設定値 | 根拠 |
|---|---|---|
| しきい値 | 85% | 80% だとビルド/バッチで誤検知が多い。90% だと業務影響が出てから鳴る。中間の 85% で「兆候段階」を捉える |
| 評価期間 | 10 分 (`for: 10m`) | スパイクで鳴らさない。`scrape_interval=15s` × 40 サンプル相当 |
| 重大度 | warning | 業務停止ではない。Slack 通知のみ、夜間は鳴らさない |
| エスカレーション | 30 分継続でページャー | 自動復旧しないと判断 |

**判断の流れ**:
1. `top` でプロセス上位を確認 → 業務プロセスか、バックアップ等の正常系か
2. `journalctl --since "20 min ago"` で同時刻のエラー有無
3. 業務影響あり → 該当プロセスを kill か再起動 (手順書あり)
4. 影響なし → 監視継続、定常化なら閾値見直し

### 2.2 `HostHighMemory`: available < 10% を 15 分継続 → warning

- **なぜ available?** `MemFree` だけだとキャッシュ分が引かれてしまい誤検知。Linux 3.14+ の `MemAvailable` が業界標準
- **なぜ 15 分?** Java など GC を持つプロセスは一時的に 90% 超える設計もある。継続的に超過したら OOM Killer 発火の前兆
- **アクション**: `dmesg | grep -i oom`、`smem -r` で RSS 上位を確認

### 2.3 `HostLowDisk`: 空き < 10% を 10 分継続 → critical

- **なぜ critical?** ログ書き込み停止 → サービス障害 → エビデンス消失の三重苦。warning ではなく即対応
- **なぜ 10%?** 1TB 中の 10% = 100GB は数日で詰まる。5% まで落ちると logrotate も書き込めない
- **アクション**: `du -sh /var/log/* | sort -h | tail`、古いバックアップ・コアダンプの確認

### 2.4 `NodeExporterDown`: up == 0 を 5 分継続 → critical

- **なぜ 5 分?** scrape interval 15s × 20 で「一時的なネットワーク瞬断ではない」と判断
- **アクション**: `ssh` で疎通確認 → 不可ならホスト側障害、可なら exporter プロセスの状態を確認

---

## 3. SLO 達成度の可視化

Grafana に **SLO Burn Rate ダッシュボード** を別途用意 (本リポジトリでは未実装、TODO):

```promql
# 例: 直近 1h のエラーレートが SLO の 14.4 倍 → 5% バジェットを 1 日で消費するペース
sum(rate(http_requests_total{status=~"5.."}[1h]))
  /
sum(rate(http_requests_total[1h]))
  > (1 - 0.99) * 14.4
```

しきい値 14.4 と 6 の 2 段階で fast-burn / slow-burn を分けるのが Google SRE Workbook の標準。

---

## 4. アラート設計の原則 (このリポジトリでの方針)

1. **症状ベース、原因ベースではない**: 「CPU 高い」より「応答が遅い」 を優先
2. **アクション可能なものだけ鳴らす**: 鳴ったら必ず何かやる。鳴っても何もしないアラートは廃止
3. **重大度を 2 段階に絞る**: `warning` (営業時間内対応) / `critical` (即時対応)。`info` は通知しない
4. **`for:` を必ず付ける**: 瞬間値で鳴らさない。リトライで自動復旧するなら鳴らさない
5. **アラート名にホスト/サービスを含める**: タイトルだけで状況が分かるように

---

## 5. 改善ロードマップ

- [ ] Alertmanager を導入、ルーティング (Slack / Teams / メール) を実装
- [ ] Grafana SLO ダッシュボード (multi-window multi-burn-rate)
- [ ] blackbox_exporter で外形監視 (DNS / HTTP / TCP)
- [ ] Loki に対応する `LogQL` アラート (例: sshd ブルートフォース検知)
- [ ] PagerDuty 連携 (現在は Slack のみ想定)
