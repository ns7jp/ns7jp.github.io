# ネットワーク設計メモ — ACL / VPN / セグメント分離

> `infra-lab.html` の VLAN 論理構成図に対する **L3/L4 のフィルタ設計** と
> Site-to-Site VPN / クライアント VPN の構成例をまとめたメモです。
> 実機ベンダー設定は環境依存なので、本ファイルでは **意図と粒度の例** を示します。

---

## 1. VLAN 間アクセス制御マトリクス

`infra-lab.html` で示した VLAN 構成のうち、VLAN 間で許可すべき通信を整理します。

| 送信元 \ 宛先 | DMZ(10) | Server(20) | User(30) | Guest/IoT(40) | Internet |
|---|---|---|---|---|---|
| **DMZ(10)** | — | 必要ポートのみ | 拒否 | 拒否 | 80/443 戻り |
| **Server(20)** | — | 内部許可 | 拒否（戻りのみ） | 拒否 | 必要に応じて 443 (M365 / 更新) |
| **User(30)** | 80/443 | 53/88/389/445/3389 etc. | — | 拒否 | 80/443 |
| **Guest/IoT(40)** | 拒否 | 拒否 | 拒否 | — | 80/443 のみ |
| **Internet** | 80/443 | 拒否 | 拒否 | 拒否 | — |

### User → Server 必要ポート（参考）

| サービス | プロトコル | ポート | 備考 |
|---------|------------|--------|------|
| DNS | UDP/TCP | 53 | クライアント→ DC |
| Kerberos | UDP/TCP | 88 | AD 認証 |
| LDAP | TCP | 389 | AD 検索 |
| LDAPS | TCP | 636 | TLS 化 LDAP |
| SMB | TCP | 445 | ファイル共有 |
| RDP | TCP | 3389 | 管理用、ジャンプサーバ経由のみ推奨 |
| Print | TCP | 631 (IPP) / 9100 (RAW) | 印刷サーバ |
| HTTP(S) | TCP | 80/443 | イントラポータル |

---

## 2. Edge ファイアウォール ACL 例（疑似 Cisco ASA 構文）

```
! インバウンド (Internet → DMZ)
access-list outside_in extended permit tcp any host 192.0.2.10 eq 443
access-list outside_in extended permit tcp any host 192.0.2.10 eq 80
access-list outside_in extended permit tcp any host 192.0.2.11 eq 25
access-list outside_in extended permit udp any host 192.0.2.12 eq 500
access-list outside_in extended permit udp any host 192.0.2.12 eq 4500
access-list outside_in extended deny ip any any log

! DMZ → Internal （戻り通信 + 必要分のみ。明示的に拒否を最後に）
access-list dmz_in extended permit tcp host 192.0.2.11 host 10.0.20.30 eq 25
access-list dmz_in extended deny ip any 10.0.0.0 255.255.0.0 log
access-list dmz_in extended permit ip any any  ! Internet 戻り

! Server VLAN → 他 (基本拒否、明示許可のみ)
access-list inside_server extended permit tcp any host 10.0.20.10 eq 80   ! 監視
access-list inside_server extended permit tcp any host 10.0.20.10 eq 443
access-list inside_server extended permit udp any any eq 123             ! NTP 出力
access-list inside_server extended permit tcp any any eq 443             ! M365 / 更新
access-list inside_server extended deny ip any 10.0.30.0 255.255.255.0 log
access-list inside_server extended deny ip any 10.0.40.0 255.255.255.0 log

! Guest/IoT VLAN は Internet 出口のみ
access-list guest_in extended deny ip any 10.0.0.0 255.255.0.0 log
access-list guest_in extended permit tcp any any eq 80
access-list guest_in extended permit tcp any any eq 443
access-list guest_in extended permit udp any any eq 53
access-list guest_in extended deny ip any any log
```

**設計意図**

- 「拒否を最後にログ付きで明示」する。**implicit deny だけに頼らない**（運用時の見える化のため）
- Guest VLAN は社内資産 (10.0.0.0/16) への到達を **最初に拒否**
- Server VLAN は受動的（外部からの限定通信のみ）。能動通信は NTP / M365 / 更新の 3 種に絞る
- DMZ は戻り通信のみ。内部からの能動アクセスは原則しない

---

## 3. Site-to-Site VPN（IPsec）構成例

本社拠点と支社拠点を IPsec トンネルで接続する想定。Edge ルーター（任意ベンダー）で IKEv2 を使用。

```
   本社拠点                                   支社拠点
   (10.0.0.0/16)                              (10.1.0.0/16)
   +------------+                             +------------+
   | Edge FW    |                             | Edge FW    |
   | 198.51.100.1                             | 203.0.113.1
   +-----+------+                             +-----+------+
         |                                          |
         +<======== IPsec IKEv2 Tunnel ========>+
         |                                          |
         | Phase1: aes256, sha256, dh20             |
         | Phase2: aes-gcm-256, lifetime 1h         |
         | PSK or 証明書認証（推奨: 証明書）         |
```

**設計上の決め事**

| 項目 | 値 |
|------|---|
| 認証方式 | IKEv2 + 証明書認証（PSK は Lab のみ） |
| 暗号 (Phase1) | AES-256 / SHA-256 / DH Group 20 |
| 暗号 (Phase2) | AES-256-GCM / lifetime 1h |
| DPD | 30秒 / 3回失敗で再ネゴ |
| 経路 | 本社 → 支社 = 10.1.0.0/16, 支社 → 本社 = 10.0.0.0/16 |
| 障害時 | サイト間ルーティングが落ちたら **本社経由インターネット** に明示的に切り替える経路は持たない（情報漏洩防止のため） |

**監視項目**（Prometheus / SNMP 経由）

- IPsec トンネル UP 状態
- Phase1 / Phase2 SA 数
- ハンドシェイク失敗カウンタ
- Tx/Rx パケット数（**急減** で経路障害の早期検知）

---

## 4. クライアント VPN（SSL-VPN / WireGuard）

リモートワーク端末から社内 VLAN 30 へ接続する想定。

### WireGuard サーバー設定例

```ini
# /etc/wireguard/wg0.conf  (本社 VPN GW)
[Interface]
Address = 10.0.99.1/24
ListenPort = 51820
PrivateKey = <server-private-key>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# 利用者: Shimada (会社支給ノート)
PublicKey = <client-pub>
AllowedIPs = 10.0.99.10/32
PresharedKey = <psk>

[Peer]
# 利用者: 退職者は authorized から削除すると同様に [Peer] ブロックを削除
```

### クライアント側（WireGuard for Windows）

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.99.10/32
DNS = 10.0.20.10

[Peer]
PublicKey = <server-pub>
PresharedKey = <psk>
Endpoint = vpn.example.com:51820
AllowedIPs = 10.0.20.0/24, 10.0.30.0/23
PersistentKeepalive = 25
```

**設計意図**

- `AllowedIPs` を **社内宛のみ** に限定（split tunnel）→ Internet トラフィックは利用者の家庭回線を使用
- DNS は社内 DC を強制指定 → AD 認証や社内名前解決が正しく動く
- `PersistentKeepalive` 25 秒で NAT テーブル維持
- 退職者対応は `[Peer]` ブロック削除のみ。`authorized_keys` と同じ運用感

---

## 5. 切り分けの順序（VLAN/VPN トラブル時）

問い合わせ「拠点からファイルサーバーに繋がらない」の例：

1. **L1**: ケーブル / リンクアップ。`ip -s link`、スイッチログの port-down 確認
2. **L2**: VLAN タグ。`show vlan brief` / `show interfaces trunk`
3. **L3**: 経路。`ip route`、`traceroute -n 10.0.20.30` で **どこで止まるか** を見る
4. **L4**: ポート疎通。`nc -zv 10.0.20.30 445` / `Test-NetConnection -Port 445`
5. **L7**: アプリ層。SMB session 列挙、AD 認証ログ
6. **VPN 経由なら**: トンネル UP、ルーティングテーブル、`AllowedIPs` を順に

ここまでで問題箇所が **拠点側か / トンネル上か / サーバー側か** に切り分けできれば、
担当者に渡せる粒度の情報になります。

---

## 関連リンク

- VLAN 論理構成図: [`../infra-lab.html`](../infra-lab.html)
- 障害対応プレイブック: [`incident-response-playbook.md`](./incident-response-playbook.md)
- Linux 一次切り分け（`ss`/`ip route`/`nc`の使い方）: [`../linux-lab.html`](../linux-lab.html)
- Cloud (Azure) Lab（ハイブリッド前提の NSG 例）: [`../azure-lab/`](../azure-lab/)
