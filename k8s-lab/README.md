# Kubernetes Lab — 本番に持っていける最小構成

`kubectl apply -k overlays/<env>/` だけで、**production-grade な必須要素** を一通り揃えた nginx ワークロードが立ち上がります。learning だけでは見落としやすい "本番に必要なやつ" を意図的に全部入れています。dev / stg / prod の 3 環境を Kustomize overlay で切替えられます。

> ローカル検証は `kind` または `minikube` でできます。Azure 上で動かす場合は `terraform-lab/` の VM に k3s を入れるか、AKS に切り替えてください。

---

## ディレクトリ構成

```
k8s-lab/
├── base/                   ... 環境共通の最小単位
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── networkpolicy.yaml
│   └── kustomization.yaml
├── overlays/               ... 環境別の差分
│   ├── dev/                ... kind 想定、replicas=1, latest tag
│   ├── stg/                ... 内部 CA TLS, replicas=2
│   └── prod/               ... Let's Encrypt, replicas=3, PDB minAvailable=2
├── argocd/                 ... GitOps (ApplicationSet で 3 環境を自動生成)
├── policies/               ... Kyverno ClusterPolicy (root 禁止 / latest 禁止など)
├── ingress/                ... cert-manager ClusterIssuer (Let's Encrypt + 社内 CA)
├── secrets/                ... SOPS + age による暗号化 Secret
└── screenshots/            ... 動作証跡 (期待出力)
```

## base に含まれる要素 (なぜ必要か)

| マニフェスト | 内容 | 含めた理由 |
|---|---|---|
| `namespace.yaml` | `lab` namespace (overlay で上書き) | 環境分離。RBAC / NetworkPolicy のスコープ |
| `configmap.yaml` | nginx 配信用 HTML | コンテナ image を変えずに content を差し替えできる |
| `deployment.yaml` | nginx 2 replicas | requests/limits, probes, securityContext, topologySpread を全部入り |
| `service.yaml` | ClusterIP | 内部向け。Ingress を別途置く前提 |
| `hpa.yaml` | HPA (CPU 70%, 2-5) | 負荷変動に自動追従。SRE の基本 |
| `pdb.yaml` | PodDisruptionBudget | ノードメンテ時の可用性保証 |
| `networkpolicy.yaml` | 同一 NS + ingress-nginx のみ許可 | デフォルト deny の世界観 |
| `kustomization.yaml` | Kustomize エントリポイント | overlay で env 別に上書き |

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

# 3. ラボのマニフェストを適用 (dev / stg / prod を選ぶ)
kubectl apply -k overlays/dev/

# 4. 状態確認
kubectl -n lab-dev get all
kubectl -n lab-dev describe deploy/dev-web
kubectl -n lab-dev get hpa

# 5. 動作確認 (ポートフォワード)
kubectl -n lab-dev port-forward svc/dev-web 8080:80
# 別ターミナルで:
curl http://localhost:8080/

# 6. ローリング更新の確認 (本来は overlay 側の image tag を上げて再 apply)
kubectl -n lab-dev set image deploy/dev-web nginx=nginxinc/nginx-unprivileged:1.27.1-alpine
kubectl -n lab-dev rollout status deploy/dev-web

# 7. 環境切替 (stg / prod も同じやり方)
kubectl apply -k overlays/prod/
kubectl -n lab-prod get all

# 8. 後片付け
kind delete cluster --name lab
```

---

## 関連サブディレクトリ

- [`overlays/`](overlays/) — dev / stg / prod の差分 (replicas / image tag / resources / ingress host / TLS issuer)
- [`argocd/`](argocd/) — ArgoCD ApplicationSet で 3 環境を一括管理する GitOps 構成
- [`policies/`](policies/) — Kyverno ClusterPolicy (root 禁止 / latest tag 禁止 / resource limits 必須 / probes 必須)
- [`ingress/`](ingress/) — cert-manager ClusterIssuer (Let's Encrypt staging/prod + 社内 CA)
- [`secrets/`](secrets/) — SOPS + age による暗号化 Secret (GitOps と相性が良い方式)
- [`screenshots/`](screenshots/) — `kubectl get all` 等の期待出力 (動作証跡)

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
