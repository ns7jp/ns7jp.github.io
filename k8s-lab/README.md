# Kubernetes Lab — kind + nginx-ingress

> **目的**: 「k8s に触れていない」状態を抜けるための最小 Lab。Docker さえ入っていれば
> ノート PC でも 5 分で立ち上がる構成にしています。

## ゴール

| 観点 | 内容 |
|------|------|
| 環境 | `kind` (Kubernetes in Docker) でローカル 3 ノードクラスタを起動 |
| 構成 | nginx-ingress-controller + nginx deployment + ingress |
| 検証 | `curl -H "Host: hello.lab.local" http://localhost` が 200 を返す |
| 拡張 | `monitoring-stack` の Prometheus を `Pod` メトリクス取得に向ける手順を併記 |

## 想定アーキテクチャ

```
                            host (Linux / macOS / WSL2)
+----------------------------------------------------------------+
|  Docker                                                        |
|   ┌──────────────────────────────────────────────────────────┐ |
|   │ kind cluster: lab-cluster                                │ |
|   │                                                          │ |
|   │  ┌─ control-plane ──┐  ┌─ worker-1 ──┐  ┌─ worker-2 ──┐ │ |
|   │  │ kube-apiserver   │  │ kubelet     │  │ kubelet     │ │ |
|   │  │ etcd / scheduler │  │ ingress-ctl │  │             │ │ |
|   │  └──────────────────┘  └─────────────┘  └─────────────┘ │ |
|   │                                                          │ |
|   │  Deployment: nginx (replicas=2)                          │ |
|   │  Service:    nginx (ClusterIP)                           │ |
|   │  Ingress:    hello.lab.local → nginx                     │ |
|   └──────────────────────────────────────────────────────────┘ |
|              ↑ host port 80 → ingress-controller               |
+----------------------------------------------------------------+
              ↑
        curl -H "Host: hello.lab.local" http://localhost
```

## ファイル構成

```
k8s-lab/
├── README.md                 ... 本ファイル
├── kind-config.yaml          ... 3ノード + port mapping
└── manifests/
    ├── ingress-nginx.yaml    ... ingress-nginx controller (公式マニフェストを取得して適用)
    ├── nginx-deployment.yaml ... Deployment + Service
    └── nginx-ingress.yaml    ... Ingress (hello.lab.local)
```

## 実行手順

```bash
# 1. kind と kubectl をインストール（macOS の場合）
brew install kind kubectl

# 2. クラスタ起動 (約 2 分)
cd k8s-lab
kind create cluster --config kind-config.yaml

# 3. ingress-nginx をインストール（kind 用の公式マニフェスト）
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/kind/deploy.yaml

# 4. ingress-controller が Ready になるまで待つ
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 5. nginx と Ingress を作成
kubectl apply -f manifests/nginx-deployment.yaml
kubectl apply -f manifests/nginx-ingress.yaml

# 6. 動作確認
curl -s -H "Host: hello.lab.local" http://localhost/ | head -5
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
# ...
```

## 後片付け

```bash
kind delete cluster --name lab-cluster
```

## ポートフォリオでの位置づけ

- `monitoring-stack/` が **VM 単体の運用**、`ansible/` が **VM の冪等構築**、
  `azure-lab/` が **クラウド単体 VM の払い出し** を担当。
- 本 Lab は **「複数コンテナをオーケストレーション」する観点** を最小単位で示します。
- `linux-lab.html` で扱う systemd / cron は **単一ホスト** の話、
  k8s は **クラスタとしてのライフサイクル管理** の話、と並べて読めるようにしています。

## 設計上の判断

| 項目 | 採用 | 理由 |
|------|------|------|
| ディストリビューション | **kind** | 同一マシンで完結。`minikube` より起動が速い |
| ノード数 | **3 (cp + worker×2)** | スケジューラと NodeAffinity の動作確認に最低限必要 |
| ingress | **nginx-ingress** | de facto。`hostPort` で host:80 に露出 |
| アプリ | **nginx 公式イメージ** | ストック構成。学習用途では十分 |
| TLS | **未対応（HTTP のみ）** | ローカル Lab。cert-manager + Let's Encrypt 拡張は別途 |
| 監視 | `monitoring-stack/` から `kubernetes-service-endpoints` discovery で接続予定 | 本 Lab の範疇外 |

## 注意

- `kind` クラスタは host network を docker bridge 経由で使うため、企業の VPN や厳しい FW 配下では起動が不安定になることがあります。
- 本番 k8s では Pod Security Standards (restricted)、NetworkPolicy、RBAC の設定が必要です。本 Lab では省略しています。

## 関連リンク

- Linux 単一ホスト運用: [`../linux-lab.html`](../linux-lab.html)
- Azure 単体 VM 払い出し: [`../azure-lab/`](../azure-lab/)
- 観測スタック: [`../monitoring-stack/`](../monitoring-stack/)
- IaC 統制 / SLO / 変更管理: [`../support-docs/`](../support-docs/)
