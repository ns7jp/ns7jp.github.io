# Ingress + cert-manager

`overlays/stg` と `overlays/prod` の Ingress で参照する **cert-manager の ClusterIssuer** をここに置きます。

## 構成

```
[Internet]
   ↓ DNS A レコード
[Cloud LB / NLB]
   ↓
[Ingress NGINX Controller]
   ↓
[Service (ClusterIP)]
   ↓
[Pod]
```

TLS 証明書は **cert-manager** が ACME プロトコルで自動取得・自動更新します。手作業ゼロ。

## セットアップ

```bash
# 1. ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# 2. cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.yaml

# 3. ClusterIssuer
kubectl apply -f k8s-lab/ingress/cert-manager-issuers.yaml

# 4. stg や prod の overlay を apply すると、Ingress の annotation 経由で
#    cert-manager が自動的に Certificate を発行
kubectl apply -k k8s-lab/overlays/prod/

# 5. 進捗確認
kubectl get certificate -A
kubectl describe certificate web-prod-tls -n lab-prod
```

## ファイル

| ファイル | 内容 |
|---|---|
| `cert-manager-issuers.yaml` | Let's Encrypt staging/prod + 社内 CA の 3 つの ClusterIssuer |

## トラブルシューティング

| 症状 | 確認 | 原因 |
|---|---|---|
| Certificate `Ready=False` が続く | `kubectl describe certificate ...` の Events | DNS 未反映、HTTP-01 challenge が届かない |
| `pending` のまま 5 分以上 | `kubectl get challenges -A` | Ingress controller の health、namespace 間ネットワーク |
| `rate limit exceeded` | `kubectl logs -n cert-manager deploy/cert-manager` | 本番 issuer を試行錯誤に使った。staging に切替 |
