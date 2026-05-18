# Docker Lab — 本番グレードの Dockerfile

「動くだけ」ではなく **本番運用に必要な事項を最初から盛り込んだ Dockerfile** のサンプルです。レビューで指摘されがちな観点を Dockerfile 内コメントに残し、CI でビルド・lint・脆弱性スキャンまで自動化しています。

中身のアプリ自体は標準ライブラリだけで動く軽量 HTTP ヘルスチェッカーで、`k8s-lab/` でそのまま動かせます。

---

## Dockerfile に意図的に入れている本番要素

- [x] `FROM ... AS builder` の **multi-stage build** (build tool を runtime に持ち込まない)
- [x] **base image の version pin** (`python:3.12.5-slim`)
- [x] **non-root user** (`USER app`)
- [x] `.dockerignore` で `.git` / テストを除外 (機密漏洩防止 + イメージサイズ削減)
- [x] **layer cache を効かせる順序** (requirements.txt → src の順にコピー)
- [x] `PYTHONUNBUFFERED=1` (コンテナログ即時 flush)
- [x] `HEALTHCHECK` 命令 (k8s なくても単体 `docker run` で意味を持つ)
- [x] OCI **ラベル** (`org.opencontainers.image.*`)
- [x] `EXPOSE` で公開ポートをドキュメント化
- [x] `ENTRYPOINT` + `CMD` の分離 (運用時のオプション差し替え)

---

## ビルドと起動

```bash
# ビルド (BuildKit syntax を活用)
DOCKER_BUILDKIT=1 docker build -t healthcheck-cli:dev docker-lab/

# 起動
docker run --rm -p 8080:8080 --name hc healthcheck-cli:dev

# 動作確認 (別ターミナル)
curl -s http://localhost:8080/healthz
# → {"status": "ok"}

curl -s "http://localhost:8080/probe?host=8.8.8.8&port=53"
# → {"host": "8.8.8.8", "port": 53, "reachable": true}
```

---

## イメージサイズと脆弱性

| 観点 | 値 / 方法 |
|---|---|
| 最終イメージサイズ | 約 130MB (`python:3.12-slim` ベース) |
| 削減オプション | `python:3.12-alpine` で約 60MB、`gcr.io/distroless/python3` で約 90MB |
| 脆弱性スキャン | `trivy image healthcheck-cli:dev` を CI で自動実行 (重大度 HIGH/CRITICAL で fail) |
| SBOM 生成 | `docker buildx build --sbom=true ...` (CI で artifact 化) |

---

## 関連 Lab

- [`k8s-lab/`](../k8s-lab/) — このイメージを Kubernetes で動かす
- [`.github/workflows/docker-ci.yml`](../.github/workflows/docker-ci.yml) — ビルド / hadolint / trivy の CI
- [`monitoring-stack/`](../monitoring-stack/) — このコンテナのログを Loki で集約
