#!/bin/bash
# SessionStart hook — install GitHub CLI (gh) from GitHub Releases.
#
# Why GitHub Releases instead of apt:
#   - The Claude Code on the web image cannot reach cli.github.com's apt repo
#     (return 403), but it can reach github.com/cli/cli/releases.
#   - Pinning a version makes the install deterministic across sessions.
#
# Authentication is intentionally NOT configured here. Provide GH_TOKEN
# via your environment if you need API access (gh respects $GH_TOKEN).

set -euo pipefail

# Only run inside Claude Code on the web. Locally `gh` is already installed
# (or the user manages it themselves).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GH_VERSION="2.62.0"
GH_BIN="/usr/local/bin/gh"

# Idempotent: skip if the correct version is already on disk.
if [ -x "$GH_BIN" ] && "$GH_BIN" --version 2>/dev/null | grep -q "gh version ${GH_VERSION}"; then
  echo "gh ${GH_VERSION} already present at ${GH_BIN}"
  exit 0
fi

case "$(uname -m)" in
  x86_64)        gh_arch="amd64" ;;
  aarch64|arm64) gh_arch="arm64" ;;
  *)
    echo "session-start gh hook: unsupported arch $(uname -m)" >&2
    exit 1
    ;;
esac

tarball="gh_${GH_VERSION}_linux_${gh_arch}.tar.gz"
url="https://github.com/cli/cli/releases/download/v${GH_VERSION}/${tarball}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "session-start gh hook: downloading ${url}"
curl -fsSL "$url" -o "${workdir}/gh.tar.gz"
tar -xzf "${workdir}/gh.tar.gz" -C "${workdir}"

install -m 0755 "${workdir}/gh_${GH_VERSION}_linux_${gh_arch}/bin/gh" "$GH_BIN"
echo "session-start gh hook: installed $("$GH_BIN" --version | head -1)"
