# ArgoCD ブートストラップ手順

このディレクトリは **GitOps** スタイルで k8s-lab を運用するための ArgoCD マニフェスト群です。「Git にマージしたら本番が変わる」 という宣言的運用の例として用意しています。

## なぜ GitOps か

`kubectl apply -k overlays/prod/` を手動で打つ運用は次の問題があります:

- 誰がいつ apply したか追跡しづらい
- ローカル kubeconfig の権限が広がりがち
- クラスタの実態と Git の差分が分からなくなる (drift)

ArgoCD を入れると:

- Git に push → 自動 sync (またはレビュー後手動 sync)
- Git の状態がクラスタの **真の状態** になる
- drift があれば UI / 通知で検知
- ロールバックは `git revert` 1 回

## 手順

```bash
# 1. ArgoCD をクラスタに入れる
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. UI を port-forward (本番では Ingress + IdP 統合)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 3. 初期パスワード
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# 4. このディレクトリのアプリ定義を apply
kubectl apply -f k8s-lab/argocd/applicationset.yaml

# 5. UI (https://localhost:8080) で 3 つの Application (dev/stg/prod) が
#    自動生成されることを確認

# 6. dev は自動 sync、stg/prod は手動 sync の運用 (applicationset.yaml 参照)
```

## sync ポリシーの方針

| 環境 | sync ポリシー | 理由 |
|---|---|---|
| dev | automated (prune + selfHeal) | 手戻り少なく、開発速度優先 |
| stg | automated (prune のみ、selfHeal off) | 検証のため手動介入を許容 |
| prod | 手動 sync のみ | レビュー後にスタッフが明示的に sync。誤反映を防ぐ |

## ファイル

| ファイル | 内容 |
|---|---|
| `applicationset.yaml` | dev / stg / prod の Application を ApplicationSet で一括定義 |
| `project.yaml` | 権限境界 (どの namespace / リソース種類が許可されるか) |
