# セキュリティベースライン (CIS Benchmarks 準拠)

社内サーバー / クライアント / コンテナの **最小限のセキュリティハードニング項目** を、CIS Benchmarks をベースに整理します。`ansible/playbook.yml` で自動適用している部分と、手動 / GPO で対応する部分を明示します。

> 完全な CIS Level 1 / Level 2 準拠を目指すものではなく、社内 100-500 名規模で「攻撃面を実用的に下げる」 ための実装可能なサブセットを抽出しています。

---

## 1. Linux サーバー (Ubuntu 22.04 LTS)

### 1.1 認証・アクセス

| 項目 | 設定 | 自動化 | CIS ID |
|---|---|---|---|
| SSH パスワード認証無効化 | `PasswordAuthentication no` | ansible | 5.2.10 |
| root SSH 直接ログイン禁止 | `PermitRootLogin no` | ansible | 5.2.8 |
| SSH プロトコル v2 のみ | `Protocol 2` (デフォルト) | - | 5.2.4 |
| SSH MaxAuthTries 制限 | `MaxAuthTries 4` | ansible | 5.2.7 |
| SSH ClientAliveInterval | `ClientAliveInterval 300` | ansible | 5.2.16 |
| SSH 暗号スイート制限 | `Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com` | ansible | 5.2.13 |
| sudo パスワード必須 | `Defaults !authenticate` を許可しない | 手動 | 5.3.4 |
| sudo コマンドログ | `Defaults logfile=/var/log/sudo.log` | 手動 | 5.3.3 |

### 1.2 ネットワーク

| 項目 | 設定 | 自動化 | CIS ID |
|---|---|---|---|
| デフォルト deny | UFW `default deny incoming` | ansible | 3.5.x |
| IP forwarding 無効 | `net.ipv4.ip_forward = 0` | ansible | 3.2.1 |
| Send redirects 無効 | `net.ipv4.conf.all.send_redirects = 0` | ansible | 3.2.2 |
| Source routed packets 拒否 | `net.ipv4.conf.all.accept_source_route = 0` | ansible | 3.3.1 |
| ICMP redirects 拒否 | `net.ipv4.conf.all.accept_redirects = 0` | ansible | 3.3.2 |
| Reverse Path Filter 有効 | `net.ipv4.conf.all.rp_filter = 1` | ansible | 3.3.7 |
| TCP SYN Cookies 有効 | `net.ipv4.tcp_syncookies = 1` | ansible | 3.3.8 |

### 1.3 ファイルシステム

| 項目 | 設定 | 自動化 | CIS ID |
|---|---|---|---|
| `/tmp` 別パーティション | `nodev,nosuid,noexec` でマウント | 手動 / kickstart | 1.1.2-1.1.5 |
| `/var/log` 別パーティション | 容量逼迫から本体を守る | 手動 / kickstart | 1.1.11 |
| `/home` `nodev` マウント | dev ファイル作成不可 | 手動 | 1.1.18 |
| 不要 SUID/SGID の特定 | `find / -perm /6000 -type f` | 監査 | 6.1.13 |
| world-writable ファイル監査 | `find / -perm -002 -type f` | 監査 | 6.1.10 |

### 1.4 監査・ロギング

| 項目 | 設定 | 自動化 |
|---|---|---|
| auditd 有効化 | `systemctl enable auditd` | ansible |
| auditd ルール (sudo, identity, network) | `/etc/audit/rules.d/cis.rules` | ansible |
| rsyslog でリモートログサーバーへ転送 | `*.* @logserver.internal:514` | 手動 |
| journald 永続化 | `Storage=persistent` | ansible |
| logrotate 設定 | デフォルト + sudo.log を追加 | 手動 |

### 1.5 不要サービス停止

`ansible/playbook.yml` で実装している部分:

```yaml
- name: Disable unnecessary services
  ansible.builtin.systemd:
    name: "{{ item }}"
    state: stopped
    enabled: false
  loop:
    - avahi-daemon
    - cups
    - rpcbind
  ignore_errors: yes   # サービスが未インストールでも playbook を止めない
```

### 1.6 自動更新

```yaml
# unattended-upgrades: セキュリティパッチのみ自動適用
- name: Enable unattended security upgrades
  apt:
    name: unattended-upgrades
    state: present
- name: Configure unattended-upgrades
  copy:
    src: 50unattended-upgrades
    dest: /etc/apt/apt.conf.d/50unattended-upgrades
```

---

## 2. Windows クライアント (Windows 11)

`support-scripts/Test-SecurityBaseline.ps1` で確認しているチェック項目:

| 項目 | 確認方法 |
|---|---|
| BitLocker 有効化 | `Get-BitLockerVolume` |
| Windows Defender 有効 | `Get-MpPreference`, `Get-MpComputerStatus` |
| Windows Firewall 全プロファイル ON | `Get-NetFirewallProfile` |
| Windows Update 設定 | `Get-WindowsUpdateLog`, AUOptions レジストリ |
| UAC レベル | `ConsentPromptBehaviorAdmin` レジストリ |
| SmartScreen | `SmartScreenEnabled` レジストリ |
| TPM 有効・所有 | `Get-Tpm` |
| Secure Boot | `Confirm-SecureBootUEFI` |
| Credential Guard | `Get-CimInstance -ClassName Win32_DeviceGuard` |

これらは GPO / Intune で **強制適用** し、スクリプトは **検証** に使う、という二段構え。

---

## 3. Docker コンテナ

`docker-lab/Dockerfile` および `k8s-lab/manifests/deployment.yaml` で実装:

| 項目 | 実装 |
|---|---|
| non-root user で実行 | `USER app` (Dockerfile) / `runAsNonRoot: true` (k8s) |
| readonly root FS | `readOnlyRootFilesystem: true` (k8s) |
| privilege escalation 禁止 | `allowPrivilegeEscalation: false` (k8s) |
| Linux capabilities drop | `capabilities.drop: [ALL]` (k8s) |
| seccomp profile | `seccompProfile: RuntimeDefault` (k8s) |
| イメージスキャン | Trivy CI gate で HIGH/CRITICAL ブロック |
| SBOM 生成 | `docker buildx --sbom=true` (publish workflow) |
| イメージ署名 | (将来) cosign による署名 |

---

## 4. Microsoft 365 / Entra ID

| 項目 | 設定 |
|---|---|
| MFA 全員必須 | Conditional Access ポリシー |
| レガシー認証ブロック | Conditional Access ポリシー (Basic Auth 禁止) |
| パスワード ハッシュ同期 + Smart Lockout | Entra ID デフォルト |
| Defender for Office 365 安全な添付ファイル / リンク | E5 / Defender ライセンス |
| 監査ログ保持 | デフォルト 90 日 → 1 年に延長 |
| ゲストアクセス制限 | 既定の B2B 設定を「招待時管理者承認」 に変更 |
| Privileged Identity Management (PIM) | グローバル管理者は時限昇格のみ |

---

## 5. 検証スケジュール

| 頻度 | 内容 | ツール |
|---|---|---|
| デイリー | unattended-upgrades の適用状況 | `unattended-upgrades --dry-run` |
| ウィークリー | Trivy / hadolint で Dockerfile / image スキャン | GitHub Actions (Dependabot 起点) |
| マンスリー | `lynis audit system` で Linux ハードニングスコア | lynis |
| マンスリー | CIS-CAT Lite / OpenSCAP で準拠スキャン | OpenSCAP |
| クォータリー | バックアップからのリストア訓練 | `backup-restore-runbook.md` |
| 半期 | アカウント棚卸し (休眠 / 退職者残り) | `Get-StaleUserAccounts.ps1` |
| 年次 | ペネトレーションテスト (外部委託) | - |

---

## 6. インシデント発生時のフロー

`support-docs/incident-response-playbook.md` および `malware-suspected-response.md` を参照。要点だけ:

1. **隔離**: 該当端末を有線 / 無線から切り離し、電源は切らない (揮発メモリ保全)
2. **保全**: PowerShell 履歴、イベントログ、auditd ログを別ホストへコピー
3. **連絡**: 上位責任者 → 経営層 → (必要なら) JPCERT / 警察
4. **調査**: タイムラインを 5W1H で復元、IoC を抽出
5. **根絶**: 該当認証情報のリセット、影響範囲のフォレンジック
6. **復旧**: クリーンインストール推奨、バックアップは IoC 確認後に戻す
7. **学習**: Postmortem を `support-docs/postmortem-example.md` の形式で残す

---

## 7. 関連

- [`ansible/playbook.yml`](../ansible/playbook.yml) — Linux 自動ハードニング
- [`support-scripts/Test-SecurityBaseline.ps1`](../support-scripts/Test-SecurityBaseline.ps1) — Windows ベースライン確認
- [`support-docs/network-firewall-design.md`](network-firewall-design.md) — FW ルール設計
- [`support-docs/incident-response-playbook.md`](incident-response-playbook.md) — インシデント対応
- CIS Benchmarks (Ubuntu 22.04 LTS / Windows 11 / Docker)
