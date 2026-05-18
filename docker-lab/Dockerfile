# syntax=docker/dockerfile:1.7
#
# multi-stage build で「ヘルスチェック用 CLI」をコンテナ化する例。
# - builder stage: 依存解決・ビルド
# - runtime stage: distroless (or alpine) で root 不要・最小サイズ
# - 最終イメージは数十 MB に収まる
#
# ベースイメージは pin (digest 推奨だが Lab なのでタグ指定)。
# CVE スキャン (trivy) や Docker scout は CI で自動実行する想定。

ARG PYTHON_VERSION=3.12.5

# --- builder stage --------------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS builder

WORKDIR /build

# 依存だけ先にコピーして layer cache を効かせる
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY src/ ./src/

# --- runtime stage --------------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS runtime

LABEL org.opencontainers.image.title="healthcheck-cli" \
      org.opencontainers.image.description="HTTP/TCP/DNS の到達性を JSON で出す軽量 CLI" \
      org.opencontainers.image.source="https://github.com/ns7jp/ns7jp.github.io" \
      org.opencontainers.image.licenses="MIT"

# root で動かさない (脱獄リスク低減)
RUN groupadd --system app && useradd --system --gid app --no-create-home app

WORKDIR /app

# builder から成果物だけコピー (build tool を runtime に持ち込まない)
COPY --from=builder /install /usr/local
COPY --from=builder /build/src ./src

USER app

# stdout/stderr を即時 flush (コンテナログ収集との相性)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# HEALTHCHECK は orchestrator (k8s) があれば不要だが、単体 docker run で意味を持つ
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8080/healthz', timeout=2).status==200 else 1)" || exit 1

EXPOSE 8080
ENTRYPOINT ["python", "-m", "src.main"]
CMD ["--port", "8080"]
