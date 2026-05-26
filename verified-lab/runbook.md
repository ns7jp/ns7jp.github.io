# Runbook - LabProbeTargetDown

`LabProbeTargetDown` は、blackbox_exporter から検証用 HTTP ターゲットへの probe が 30 秒以上失敗したときに発火する Lab 用アラートです。GitHub Actions の障害注入ドリルでは意図的に起動します。

## 初動

| 順番 | 確認 | コマンド | 判断 |
|---|---|---|---|
| 1 | アラート状態 | `curl -s http://localhost:9090/api/v1/alerts` | `LabProbeTargetDown` が firing か |
| 2 | ターゲット状態 | `docker compose -f monitoring-stack/docker-compose.yml ps` | `probe-target` が停止または異常か |
| 3 | 外形 probe | `curl -s http://localhost:9115/probe?target=http://probe-target/&module=http_2xx` | `probe_success` が 0 か |
| 4 | 通知配送 | `docker compose -f monitoring-stack/docker-compose.yml logs webhook-receiver` | firing が受信済みか |

## 復旧

```bash
docker compose -f monitoring-stack/docker-compose.yml start probe-target
curl -sG --data-urlencode 'query=probe_success{service="lab-http-target"}' \
  http://localhost:9090/api/v1/query
docker compose -f monitoring-stack/docker-compose.yml logs webhook-receiver
```

完了条件:

- `probe_success` が `1` に戻る
- webhook receiver に `resolved` が記録される
- 復旧できない場合は `docker compose logs probe-target blackbox-exporter prometheus` を証跡として保存する

## 証跡

`verified-lab/scripts/verify-monitoring-lab.sh` は、確認結果を `verified-lab/output/` に生成します。GitHub Actions 実行時は artifact としてアップロードし、実行時刻と実結果を workflow run に紐づけます。

## 本番化の境界

この Runbook は検証用ターゲットの復旧だけを扱います。本番のサービスでは、影響利用者、連絡先、ロールバック承認、Teams / メール通知、認証された Alertmanager、TLS、保持期間を別途定義します。
