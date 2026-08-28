# Beginner Server Lab

未経験者が「予想 → 実行 → 証跡 → 説明」の順で Linux サーバー構築を学ぶ補助教材です。公開中の設定を本番利用できるという意味ではありません。

| 読む順番 | 文書 | 目的 |
|---|---|---|
| 1 | [lab-guide.md](./lab-guide.md) | 8段階の操作と合格条件 |
| 2 | [glossary.md](./glossary.md) | 用語を一言で確認 |
| 3 | [failure-drills.md](./failure-drills.md) | 安全な障害演習 |
| 4 | [evidence-guide.md](./evidence-guide.md) | 実測・CI・架空例を分離 |
| 5 | [assessment-rubric.md](./assessment-rubric.md) | 100点の修了判定 |
| 6 | [security-threat-model.md](./security-threat-model.md) | 脅威から対策を考える |

## 状態表示

- **MEASURED**: 日時、commit、環境、コマンド、結果を伴う実測。
- **CI-GENERATED**: 一時 runner が自動生成した結果。
- **SAMPLE**: 説明用の架空例。実績に数えない。
- **NOT RUN**: 手順または計画のみで未実施。

## 安全原則

1. 自分が所有する、削除可能な VM / WSL2 内だけで行う。
2. SSH / Firewall 変更前は別セッションを維持し、戻し方を用意する。
3. パスワード、秘密鍵、Token、実在する IP / hostname を証跡へ含めない。
4. 期待外の結果が出たら連続操作せず、時刻、現象、直前操作を記録する。
5. AWS、外部通知、長時間試験は費用と情報送信先を確認してから明示的に行う。

