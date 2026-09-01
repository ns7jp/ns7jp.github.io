# 安全な障害演習

## 共通ルール

自分の破棄可能なLabだけで行います。開始前にsnapshot、console接続、終了条件を確認し、1回に1つだけ壊します。次を演習票の先頭に記録します。

```text
Drill ID / 日時 / commit / host / 実施者:
想定現象 / 影響 / 成功条件 / 中止条件:
開始前snapshot / console経路 / 切り戻し:
仮説 → 確認コマンド → 結果 → 次の判断:
検知時刻 / 着手時刻 / 復旧時刻 / 実測RTO:
原因 / 復旧 / 再発防止 / 残課題:
```

| ID | 故障注入 | 観測順 | 復旧・成功条件 |
|---|---|---|---|
| D-01 | LabのWeb containerを1つ停止 | alert → `docker compose ps` → log | Runbookで起動、alert resolved |
| D-02 | Lab専用portのFirewall許可を外す | client curl → route → `ss` → firewall counter | ruleを復元し許可/拒否を再試験 |
| D-03 | Lab volumeへ上限付きdummy fileを作成 | alert → `df` → inode → `du` | 対象確認後だけdummyを削除 |
| D-04 | CPU制限containerで短い負荷 | load → process → container metrics | 時間上限で自動停止し正常化 |
| D-05 | memory制限container内だけで負荷 | memory → cgroup → OOM log | hostへ影響せず原因を特定 |
| D-06 | コピーした設定へ構文誤りを入れる | config check（対象: nginx設定fileは`sudo nginx -t`、Ansible playbookは`ansible-playbook --syntax-check`で検査） → Git diff | 本番fileへ置く前に検査で阻止 |
| D-07 | 期限切れtest証明書をローカルだけで使う | DNS → clock → expiry → SAN | 有効なtest証明書へ戻す |
| D-08 | backupのコピーを破損させる | size → checksum → extract | 原本を保護し別世代を選択 |

実ネットワーク遮断、fork bomb、host全体のdisk充填、実証明書失効は行いません。

## 前提Step（lab-guide.mdとの対応）

各drillは、対応する[lab-guide.md](./lab-guide.md)のStepが完了している前提です。未完了のStepがある場合は先にそちらを実施します。

- D-01: Step 3・Step 5実施後（Webサービスと監視alertが稼働している前提）
- D-02: Step 3実施後（ufwなどでFirewallルールが設定済みの前提）
- D-03: Step 3・Step 5実施後（Lab volumeと disk監視のalertが動いている前提）
- D-04: Step 3実施後（CPU制限付きcontainerが起動済みの前提）
- D-05: Step 3実施後（memory制限付きcontainerが起動済みの前提）
- D-06: Step 3またはStep 4実施後（nginx設定またはStep 4のplaybookが存在する前提）
- D-07: Step 3実施後（HTTPSで終端するWebサービスがローカルで稼働している前提）
- D-08: Step 7実施後、backupが存在する前提
