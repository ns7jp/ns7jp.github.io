# k8s-lab レンダリング結果と動作証跡

実行を伴うものは「コマンド + 期待される出力」 の形でここに残します。レビュアー / 採用担当者がローカルで `kind` を立てなくても、各 overlay が何を生成するかが分かるようにするのが目的です。

---

## 生成済みのファイル

| ファイル | 生成コマンド | 内容 |
|---|---|---|
| `rendered-dev.yaml` | `kustomize build overlays/dev` | dev overlay の最終マニフェスト |
| `rendered-stg.yaml` | `kustomize build overlays/stg` | stg overlay の最終マニフェスト |
| `rendered-prod.yaml` | `kustomize build overlays/prod` | prod overlay の最終マニフェスト |
| `diff-dev-vs-prod.diff` | `diff rendered-dev.yaml rendered-prod.yaml` | 環境間の差分 |
| `kubectl-get-all.expected.txt` | kind に apply 後の期待される `kubectl get` 結果 | 動作確認の答え合わせ |
| `kubectl-describe-deploy.expected.txt` | `kubectl describe deploy/prod-web` の期待出力 | 設定が効いているかの確認 |

---

## 環境差分のサマリ

| 項目 | dev | stg | prod |
|---|---|---|---|
| namespace | `lab-dev` | `lab-stg` | `lab-prod` |
| namePrefix | `dev-` | `stg-` | `prod-` |
| replicas | 1 | 2 | 3 |
| HPA min / max | 1 / 2 | 2 / 5 (base) | 3 / 10 |
| PDB minAvailable | 1 (base) | 1 (base) | 2 |
| image tag | `1.27-alpine` | `1.27.1-alpine` | `1.27.1-alpine` |
| requests CPU/mem | 25m / 32Mi | 50m / 64Mi (base) | 100m / 128Mi |
| limits CPU/mem | 100m / 64Mi | 200m / 128Mi (base) | 500m / 256Mi |
| Ingress host | `web.dev.local` | `web.stg.example.internal` | `web.example.com` |
| TLS issuer | なし | `internal-ca-issuer` | `letsencrypt-prod` |

---

## 動作確認手順 (実機で実行する場合)

```bash
# 1. kind クラスタ作成 (ingress-ready ノード)
cat <<EOF | kind create cluster --name lab --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
      - containerPort: 443
        hostPort: 443
EOF

# 2. ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

# 3. metrics-server (HPA に必要)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 4. dev overlay を apply
kubectl apply -k overlays/dev/

# 5. 期待される状態 (kubectl-get-all.expected.txt と一致するか)
kubectl get all -n lab-dev

# 6. 動作確認
echo "127.0.0.1 web.dev.local" | sudo tee -a /etc/hosts
curl -s http://web.dev.local/ | grep "Kubernetes Lab"

# 7. 後片付け
kubectl delete -k overlays/dev/
kind delete cluster --name lab
```
