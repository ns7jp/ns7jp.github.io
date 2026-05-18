# ネットワーク / ファイアウォール 設計メモ

`infra-lab.html` の VLAN 構成図と対応した、**実機レベルのファイアウォールルール設計** です。NSG (Azure) / iptables (Linux) / Windows Firewall / nftables の 4 種を扱い、どこに何を書くかを整理します。

---

## 1. 設計の前提

- VLAN 構成は `infra-lab.html` の VLAN 図に準拠
- デフォルト deny、必要ポートのみ allow (whitelist 方式)
- ルールはコード管理 (Terraform / Ansible / GPO)。手動変更は NG
- 変更は PR レビュー後に CI で plan、承認後 apply

---

## 2. ゾーン別の許可マトリクス

| 送信元 → 送信先 | DMZ | Server | User | Guest/IoT | Internet |
|---|---|---|---|---|---|
| **DMZ** | full | 443/80 (限定), 25 | × | × | full out |
| **Server** | × | full (internal) | × | × | 443 (update), 53 (DNS) |
| **User** | × | 53, 88, 389, 445, 636, 3268 | full (intra) | × | full out |
| **Guest/IoT** | × | × | × | full (intra) | full out |
| **Internet** | 443, 80 (limited) | × | × | × | - |

凡例: `full` = 全ポート、`×` = 拒否、`<port>` = TCP 該当ポートのみ

---

## 3. NSG ルール例 (Azure - terraform-lab/ 対応)

`terraform-lab/main.tf` の NSG はこの方針:

```hcl
# 1000-1099: 管理アクセス (SSH, RDP, exporter)
# 1100-1199: アプリ層 (HTTP, HTTPS)
# 1200-1299: バックアップ / ストレージ
# 4096:      最終 deny (明示的に書く)
```

優先度を 100 番台で区切ることで、ルール追加時の番号衝突を防ぎ、grep で見やすくする。

---

## 4. Linux iptables / nftables (Ansible Playbook と対応)

`ansible/playbook.yml` の UFW タスクが裏で生成するルールを **明示版** で書くとこうなります。

### nftables (推奨)

```nft
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;

        # 状態保持されているコネクション + ループバック
        ct state established,related accept
        iif "lo" accept

        # ICMP は ping/MTU 探索に必要
        ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } accept
        ip6 nexthdr icmpv6 icmpv6 type { echo-request, nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } accept

        # SSH は管理セグメントのみ
        ip saddr 10.0.99.0/24 tcp dport 22 accept

        # node_exporter は監視サーバーのみ
        ip saddr 10.0.20.50/32 tcp dport 9100 accept

        # 上記以外は drop (policy で対応)
        log prefix "[nft drop] " level warn
        counter
    }

    chain forward { type filter hook forward priority filter; policy drop; }
    chain output  { type filter hook output  priority filter; policy accept; }
}
```

### iptables (レガシー環境向け)

```bash
# デフォルト deny
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 状態保持 + ループバック
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# SSH (管理セグメントのみ)
iptables -A INPUT -p tcp --dport 22 -s 10.0.99.0/24 -j ACCEPT

# SSH ブルートフォース対策 (fail2ban の代替/補完)
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh_bf --update --seconds 60 --hitcount 4 -j DROP
iptables -A INPUT -p tcp --dport 22 -m recent --name ssh_bf --set

# 保存 (Debian/Ubuntu)
iptables-save > /etc/iptables/rules.v4
```

---

## 5. Windows Defender Firewall (PowerShell)

GPO で配るのが基本。手動検証用のコマンドだけ載せます。

```powershell
# 既存ルール棚卸し
Get-NetFirewallRule -Enabled True | Select-Object DisplayName, Direction, Action, Profile |
    Sort-Object DisplayName | Format-Table -AutoSize

# 受信ルール追加: SMB を管理セグメントからのみ許可
New-NetFirewallRule -DisplayName "Allow SMB from Admin Subnet" `
    -Direction Inbound -Protocol TCP -LocalPort 445 `
    -RemoteAddress 10.0.99.0/24 -Action Allow -Profile Domain

# プロファイルごとのデフォルト動作確認
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
```

---

## 6. 変更前後の検証手順

ルール変更で「閉めすぎて自分が SSH 切断される」事故を防ぐため、毎回これをやります。

```bash
# 1. 現状ルールをバックアップ
sudo nft list ruleset > /tmp/nft.before.$(date +%s)
sudo iptables-save > /tmp/iptables.before.$(date +%s)

# 2. 「at コマンドで 5 分後に自動ロールバック」 を仕込む
echo "nft -f /tmp/nft.before.<timestamp>" | sudo at now + 5 minutes

# 3. ルール適用
sudo nft -f /etc/nftables.conf

# 4. 別セッションで疎通確認 (今のセッションは絶対閉じない)
# 別ターミナルから ssh で入れたら OK

# 5. at ジョブをキャンセル
sudo atq
sudo atrm <job-id>
```

---

## 7. トラブルシューティング

| 症状 | 確認コマンド | よくある原因 |
|---|---|---|
| 突然 SSH できない | (コンソールから) `nft list ruleset`、`journalctl -u nftables` | 直近のルール変更でロックアウト |
| 監視が落ちた | 監視サーバーから `nc -zv <target> 9100` | exporter ポートが許可されていない |
| 通信が遅い | `iptables -L -v -n | head -50` で先頭の counter | drop ルールが前段にあって retry している |
| Path MTU の問題 | `ping -M do -s 1472 <dst>` | ICMP type 3 (destination-unreachable) を drop している |

---

## 8. 関連

- [`terraform-lab/main.tf`](../terraform-lab/main.tf) — Azure NSG の実装
- [`ansible/playbook.yml`](../ansible/playbook.yml) — UFW の自動設定
- [`infra-lab.html`](../infra-lab.html) — VLAN 論理構成図
