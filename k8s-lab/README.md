# Kubernetes Lab — 本番に持っていける最小構成

`kubectl apply -k manifests/` だけで、**production-grade な必須要素** を一通り揃えた nginx ワークロードが立ち上がります。learning だけでは見落としやすい "本番に必要なやつ" を意図的に全部入れています。

> ローカル検証は `kind` または `minikube` でできます。Azure 上で動かす場合は `terraform-lab/` の VM に k3s を入れるか、AKS に切り替えてください。

---

## 含まれる要素 (なぜ必要か)

| マニフェスト | 内容 | 含めた理由 |
|---|---|---|
| `namespace.yaml` | `lab` namespace | 環境分離。RBAC / NetworkPolicy のスコープ |
| `configmap.yaml` | nginx 配信用 HTML | コンテナ image を変えずに content を差し替えできる |
| `deployment.yaml` | nginx 2 replicas | requests/limits, probes, securityContext, topologySpread を全部入り |
| `service.yaml` | ClusterIP | 内部向け。Ingress を別途置く前提 |
| `hpa.yaml` | HPA (CPU 70%, 2-5) | 負荷変動に自動追従。SRE の基本 |
| `pdb.yaml` | PodDisruptionBudget | ノードメンテ時の可用性保証 |
| `networkpolicy.yaml` | 同一 NS + ingress-nginx のみ許可 | デフォルト deny の世界観 |
| `kustomization.yaml` | Kustomize エントリポイント | overlay で env 別に上書き可能 |

---

## "本番グレード" のチェックリスト

このマニフェストはこれを満たしています。落としやすい項目なので採用面接でも聞かれます。

- [x] `resources.requests` と `limits` が両方ある (CPU/メモリ)
- [x] `livenessProbe` と `readinessProbe` を分けて定義
- [x] `securityContext.runAsNonRoot: true` (root で動かさない)
- [x] `readOnlyRootFilesystem: true` (改ざん耐性)
- [x] `allowPrivilegeEscalation: false`
- [x] `capabilities.drop: [ALL]` (最小権限)
- [x] `seccompProfile: RuntimeDefault`
- [x] `nginx-unprivileged` イメージ (root 不要)
- [x] `replicas: 2` + `topologySpreadConstraints` (単一障害点を作らない)
- [x] `RollingUpdate` の `maxUnavailable: 0` (無停止デプロイ)
- [x] `PodDisruptionBudget` (ノードドレイン耐性)
- [x] `NetworkPolicy` (デフォルト deny の世界観)
- [x] `HorizontalPodAutoscaler` (負荷変動への対応)
- [x] Prometheus scrape annotations

---

## 起動方法 (kind)

```bash
# 1. ローカル kind クラスタを作る
kind create cluster --name lab

# 2. metrics-server (HPA に必須) を入れる
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 3. ラボのマニフェストを適用
kubectl apply -k manifests/

# 4. 状態確認
kubectl -n lab get all
kubectl -n lab describe deploy/web
kubectl -n lab get hpa

# 5. 動作確認 (ポートフォワード)
kubectl -n lab port-forward svc/web 8080:80
# 別ターミナルで:
curl http://localhost:8080/

# 6. ローリング更新の確認
kubectl -n lab set image deploy/web nginx=nginxinc/nginx-unprivileged:1.27.1-alpine
kubectl -n lab rollout status deploy/web

# 7. 後片付け
kind delete cluster --name lab
```

---

## トラブルシューティング

| 症状 | 確認コマンド | よくある原因 |
|---|---|---|
| Pod が `CrashLoopBackOff` | `kubectl -n lab logs deploy/web --previous` | probe の path / port ミス、resources 不足 |
| HPA が `unknown` | `kubectl top pod -n lab` | metrics-server 未導入 |
| Pod が `Pending` | `kubectl -n lab describe pod <name>` | node リソース不足、PVC 待ち |
| Service に届かない | `kubectl -n lab get endpoints` | label セレクタ不一致、readinessProbe NG |
| NetworkPolicy が効かない | `kubectl get ns -L kubernetes.io/metadata.name` | CNI が NetworkPolicy 非対応 (kind デフォルトは flannel = 非対応) |

---

## 関連 Lab

- [`terraform-lab/`](../terraform-lab/) — k3s をホストする VM を IaC で構築
- [`monitoring-stack/`](../monitoring-stack/) — Pod のメトリクスを Prometheus でスクレイプ
- [`docker-lab/`](../docker-lab/) — ここで使うコンテナイメージのビルド
