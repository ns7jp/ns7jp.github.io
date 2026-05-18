# Kyverno ポリシー

クラスタワイドに **「最低限ここまでは守らせる」 ガードレール** を定義します。manifest 側で気をつけるのとは別に、クラスタ側でも強制する二重防御です。

## ポリシー一覧

| ポリシー | 動作 | 用途 |
|---|---|---|
| `require-non-root` | Enforce (block) | root で動くコンテナを拒否 |
| `disallow-privilege-escalation` | Enforce (block) | `allowPrivilegeEscalation: true` を拒否 |
| `require-resource-limits` | Enforce (block) | `resources.requests/limits` 未指定を拒否 |
| `disallow-latest-tag` | Enforce (block) | `image:latest` を拒否 |
| `require-probes` | Audit (warn のみ) | probe 未設定をログに残す |

## なぜ Audit と Enforce を使い分けるか

- 既存環境にいきなり Enforce を入れると **全 deploy が失敗する** ので、まず Audit (違反をログ) で 1-2 週間運用
- 違反が出尽くしたら Enforce に切り替え
- これも IaC なので Git 上で `Audit` → `Enforce` の差分が PR で見える

## 動作確認

```bash
# 1. Kyverno をクラスタへ
kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml

# 2. ポリシーを適用
kubectl apply -f k8s-lab/policies/kyverno-policies.yaml

# 3. 違反する Pod を作って block されることを確認
kubectl run bad --image=nginx:latest --namespace=lab-dev --dry-run=client -o yaml | \
  sed 's/image: nginx:latest/image: nginx:latest/' | \
  kubectl apply -f -
# → "validation error: image tag に latest を使うとロールバック困難..." で拒否される

# 4. レポート確認
kubectl get policyreports -A
kubectl get clusterpolicyreports
```

## 関連

- このポリシーは [`k8s-lab/base/deployment.yaml`](../base/deployment.yaml) の設定を **クラスタ側からも保証** する役割
- CIS Kubernetes Benchmark の Section 5 (Policies) と整合
