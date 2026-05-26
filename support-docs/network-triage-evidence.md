# ネットワーク一次切り分け 証跡集

「ネットワークが遅い」「サイトに繋がらない」「証明書エラーが出る」といった問い合わせを受けたときに、**OSI 参照モデルの下から上へ機械的に当てる**コマンド一覧と、想定される出力例をまとめたドキュメントです。

実機の出力は環境ごとに異なります。本ドキュメントの値は RFC 5737 / RFC 2606 で定義されている**ドキュメント用の予約レンジ**（`192.0.2.0/24`、`203.0.113.0/24`、`example.com`）を使ったサンプルです。実機ログは社内固有情報を含むため、ポートフォリオでは加工版のみを掲載します。

---

## 0. 切り分け順序（早見表）

| レイヤー | 症状の典型 | 最初に叩くコマンド | 次の手 |
|---|---|---|---|
| L1 / L2 | リンクが上がらない、断続切断、特定VLANだけ通らない | `ip -br link` / `ethtool eth0` / `arp -a` | 物理交換、ポート差し替え、スイッチログ |
| L3 | 「pingは通るが業務通信NG」「経路が不安定」 | `ping` / `traceroute` / `mtr -rwc 20` | 経路表 (`ip route`)、MTU、ルータ ACL |
| DNS | 「名前で繋がらないがIPなら繋がる」「古い名前を引いてくる」 | `dig +trace example.com` / `dig @8.8.8.8 example.com` | hosts、リゾルバ、TTL、内部 DNS スプリット |
| TLS | 「証明書エラー」「混在コンテンツ」「期限切れ」 | `openssl s_client -connect host:443 -servername host` | チェーン不備、SNI 設定、期限管理 |
| L4 | 「TCP が張れない」「途中で切れる」「特定ポートだけ通らない」 | `ss -tnp` / `tcpdump -ni any port 443` | FW / SG / fail2ban、コネクション枯渇 |
| L7 (HTTP) | 「遅い」「504」「リダイレクトループ」 | `curl -v -w '@curl-format.txt'` | 接続/TLS/最初の1バイト/合計時間の分解 |

> 上から順に当てると **下位の問題を上位で誤判定しない**。ping が通らないのに HTTP のチューニングを始めるような無駄が減ります。

---

## 1. L2 — リンク / ARP

### 1.1 ip / ethtool — リンク状態

```bash
# 簡潔に全 NIC を見る（UP / DOWN / 速度）
$ ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
eth0             UP             52:54:00:aa:bb:cc <BROADCAST,MULTICAST,UP,LOWER_UP>
eth1             DOWN           52:54:00:aa:bb:cd <BROADCAST,MULTICAST>

# 速度・全二重・自動ネゴ
$ sudo ethtool eth0 | grep -E 'Speed|Duplex|Link detected'
        Speed: 1000Mb/s
        Duplex: Full
        Link detected: yes
```

**よくある原因**:

- `Link detected: no` → ケーブル / SFP / スイッチポート
- `Speed: 100Mb/s`（GbE想定なのに 100M） → CAT5 ケーブル、オートネゴ失敗、片側だけ手動固定
- `Duplex: Half` → ハーフ/フル不一致。CRC エラー多発の典型

### 1.2 arp — 同セグメントの到達確認

```bash
# ARP テーブル（既知の隣接機器）
$ ip neigh show
192.0.2.1 dev eth0 lladdr 52:54:00:11:22:33 REACHABLE
192.0.2.10 dev eth0 lladdr 52:54:00:aa:bb:01 STALE

# 特定 IP の MAC を強制解決
$ sudo arping -c 3 -I eth0 192.0.2.10
ARPING 192.0.2.10 from 192.0.2.50 eth0
Unicast reply from 192.0.2.10 [52:54:00:AA:BB:01]  0.812ms
```

**よくある原因**:

- 同セグメントで応答が無い → スイッチポート / VLAN / NIC 物理障害
- 同じ IP で複数 MAC が応答 → **IP 重複**（DHCP リース重複、静的IP の衝突）

---

## 2. L3 — ping / traceroute / mtr / MTU

### 2.1 ping — 疎通と RTT 揺らぎ

```bash
$ ping -c 5 -W 2 192.0.2.1
PING 192.0.2.1 (192.0.2.1) 56(84) bytes of data.
64 bytes from 192.0.2.1: icmp_seq=1 ttl=64 time=0.532 ms
64 bytes from 192.0.2.1: icmp_seq=2 ttl=64 time=0.491 ms
64 bytes from 192.0.2.1: icmp_seq=3 ttl=64 time=12.4  ms   <-- スパイク
64 bytes from 192.0.2.1: icmp_seq=4 ttl=64 time=0.477 ms
64 bytes from 192.0.2.1: icmp_seq=5 ttl=64 time=0.501 ms

--- 192.0.2.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4083ms
rtt min/avg/max/mdev = 0.477/2.880/12.420/4.768 ms
```

**読み方**:

- `0% packet loss` でも `mdev`（揺らぎ）が大きいなら、上位経路の輻輳・無線干渉を疑う
- `Destination Host Unreachable` → 自分の経路表に該当ルートが無い（`ip route` を確認）
- `Request timeout` → 先方の応答無し or 戻りの ICMP が FW でブロック

### 2.2 traceroute / mtr — 経路と劣化箇所

```bash
# mtr は traceroute + ping を統合した連続モニタリングツール
$ sudo mtr -rwc 20 example.com
Start: 2026-05-26T09:12:03+0900
HOST: ops01                                Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.0.2.1                          0.0%    20    0.5    0.6   0.4   1.2   0.2
  2.|-- 203.0.113.1                        0.0%    20    1.2    1.4   1.1   3.2   0.4
  3.|-- 203.0.113.254                      5.0%    20    2.1    2.3   1.9   8.4   1.1   <-- 5%損失
  4.|-- ???                                100.0%  20    0.0    0.0   0.0   0.0   0.0   <-- 応答なし
  5.|-- 203.0.113.10                       0.0%    20   12.4   13.1  11.8  22.5   2.4
  6.|-- 93.184.216.34                      0.0%    20   12.6   13.0  11.9  18.7   1.8
```

**読み方**:

- `???` の hop は **ICMP TimeExceeded を返さない設定**のルータが多い。最終 hop が応答していれば実害なし
- 中間の hop だけ Loss% が高く、その先は 0% → **その hop の ICMP 応答制限**であって実通信は通っている可能性
- 中間 hop から先まで全部 Loss が高い → **そこから先の経路劣化**

### 2.3 MTU 不一致

```bash
# DF ビットを立てた ping で MTU を実測（VPN / トンネル経由でよくハマる）
$ ping -M do -s 1472 -c 3 example.com
PING example.com (93.184.216.34) 1472(1500) bytes of data.
1480 bytes from 93.184.216.34: icmp_seq=1 ttl=56 time=12.6 ms

# 1472 + ICMP/IP ヘッダ 28 = 1500（標準MTU）が通れば OK。
# 通らない場合は -s を 1452, 1400, 1380... と下げて境界を探す
$ ping -M do -s 1473 -c 3 example.com
From 203.0.113.1 icmp_seq=1 Frag needed and DF set (mtu = 1500)
```

**ヒント**: VPN（IPsec / WireGuard）越しは MTU が 1400 前後に下がる。アプリ側で巨大 POST が失敗するのに ping は通る場合の典型原因。

---

## 3. DNS — dig / nslookup / 委譲確認

### 3.1 dig — 委譲チェーンの追跡

```bash
# 委譲を最上位から辿る。社内 DNS のキャッシュ汚染を疑う時の決定打
$ dig +trace example.com

; <<>> DiG 9.18.18 <<>> +trace example.com
;; global options: +cmd
.                       86400  IN  NS  a.root-servers.net.
...
com.                    172800 IN  NS  a.gtld-servers.net.
...
example.com.            172800 IN  NS  a.iana-servers.net.
example.com.            172800 IN  NS  b.iana-servers.net.
;; Received 56 bytes from 199.43.135.53#53(a.gtld-servers.net) in 24 ms

example.com.            86400  IN  A   93.184.216.34
example.com.            86400  IN  RRSIG A 8 2 86400 ...
;; Received 1389 bytes from 199.43.135.53#53(a.iana-servers.net) in 28 ms
```

### 3.2 dig — 内部 DNS / 外部 DNS の食い違い

```bash
# 内部 DNS（社内 AD DNS）
$ dig @192.0.2.10 fileserver.corp.local +short
192.0.2.20

# 外部 DNS（パブリック）— "corp.local" は引けない
$ dig @8.8.8.8 fileserver.corp.local +short
(空行)

# 逆引き
$ dig -x 192.0.2.20 +short
fileserver.corp.local.
```

**よくある罠**:

- VPN 接続中に**スプリット DNS が効いていない** → 名前解決だけ外に出てしまい、社内ホストが引けない
- TTL が長い（86400 = 24h）レコードを変更しても、リゾルバキャッシュが消えるまで反映されない
- `/etc/hosts` で上書きされているのに気付かない → `getent hosts fileserver` で OS の解決順を確認

### 3.3 nslookup（Windows 標準）

```text
> nslookup fileserver.corp.local 192.0.2.10
Server:  dc01.corp.local
Address: 192.0.2.10

Name:    fileserver.corp.local
Address: 192.0.2.20
```

Windows 端末でも 1 行で叩けるので、ユーザー側に走らせて送ってもらう簡易切り分けに向きます。

---

## 4. TLS — openssl / nmap / 証明書期限

### 4.1 openssl s_client — 証明書チェーンの中身を確認

```bash
$ echo | openssl s_client -connect example.com:443 -servername example.com -showcerts 2>/dev/null \
    | openssl x509 -noout -subject -issuer -dates -ext subjectAltName

subject= CN = example.com
issuer= C = US, O = DigiCert Inc, CN = DigiCert TLS RSA SHA256 2020 CA1
notBefore=Jan 13 00:00:00 2026 GMT
notAfter=Feb 13 23:59:59 2027 GMT
X509v3 Subject Alternative Name:
    DNS:example.com, DNS:www.example.com
```

**確認ポイント**:

- `notAfter` を見て**残日数**を計算（後述）
- `Subject Alternative Name` に**アクセス時のホスト名が含まれているか**（含まれないと近代ブラウザは `NET::ERR_CERT_COMMON_NAME_INVALID`）
- `-servername` を付けないと SNI が送られず、ホスティング側で**異なる証明書が返る**ことがある

### 4.2 nmap — 大量ホストの期限を一括確認

```bash
# 内部の Web 系を一掃するとき
$ nmap --script ssl-cert -p 443 192.0.2.0/24 -oG - | grep -E 'Host|Not valid after'
Host: 192.0.2.20 (fileserver.corp.local)  Status: Up
| ssl-cert: Subject: commonName=fileserver.corp.local
| Not valid before: 2025-08-01T00:00:00
| Not valid after:  2026-08-01T23:59:59
```

期限が **30 日以内**のホストを抽出して P3 チケットを起票、というルーチンを月次で回せる形にします。

### 4.3 残日数の計算（cron に置く）

```bash
days_left() {
  local host=$1 port=${2:-443}
  local end_date
  end_date=$(echo | openssl s_client -connect "$host:$port" -servername "$host" 2>/dev/null \
              | openssl x509 -noout -enddate | cut -d= -f2)
  local end_epoch now_epoch
  end_epoch=$(date -d "$end_date" +%s)
  now_epoch=$(date +%s)
  echo $(( (end_epoch - now_epoch) / 86400 ))
}

$ days_left example.com
628
```

`days_left` が 30 未満なら通知、というワンライナーで簡易証明書監視が回せます。**Lab 用の素朴な実装**で、本番では Prometheus の `blackbox_exporter` モジュール `ssl_earliest_cert_expiry` を使い、Alertmanager 経由で通知します。

---

## 5. L4 — TCP / UDP / tcpdump / ss

### 5.1 ss — 接続状態とリスナー

```bash
# リスニング中のポート（PID / プロセス名つき）
$ sudo ss -tlnp
State    Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
LISTEN   0       128            0.0.0.0:22          0.0.0.0:*      users:(("sshd",pid=812,fd=3))
LISTEN   0       4096           0.0.0.0:9100        0.0.0.0:*      users:(("node_exporter",pid=901,fd=3))
LISTEN   0       511            0.0.0.0:80          0.0.0.0:*      users:(("nginx",pid=1011,fd=6))

# 確立済み接続（接続元 IP の偏りを確認）
$ sudo ss -tnp | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head
     32 192.0.2.100
     18 192.0.2.105
      4 192.0.2.50
```

**読み方**:

- `Recv-Q` が積まれている → アプリ側で処理が追いついていない（CPU / I/O / GC を確認）
- `Send-Q` が積まれている → クライアント側が受け取っていない（ネットワーク劣化、相手の輻輳）
- 特定 IP からの確立接続が **異常に多い** → DoS 試行、または同一クライアントのコネクション漏れ

### 5.2 tcpdump — 実トラフィックの確認

```bash
# 1) 特定ホストの 443 番だけ、20 パケットだけ取って終了
$ sudo tcpdump -ni any host 192.0.2.20 and port 443 -c 20 -w /tmp/cap.pcap

# 2) 同じ条件を画面に流す（SYN だけに絞ると 3-way handshake の片寄りが見える）
$ sudo tcpdump -ni any 'tcp[tcpflags] & tcp-syn != 0 and port 443'
09:30:12.001234 IP 192.0.2.50.51234 > 192.0.2.20.443: Flags [S], seq 0, ...
09:30:12.001456 IP 192.0.2.20.443 > 192.0.2.50.51234: Flags [S.], seq 0, ack 1, ...
09:30:12.001789 IP 192.0.2.50.51234 > 192.0.2.20.443: Flags [.], ack 1, ...   <-- 3-way OK

# 3) 後で Wireshark で開く（フィルタや TCP Stream で詳細解析）
$ wireshark /tmp/cap.pcap
```

**切り分けの典型**:

- **SYN だけ往復して ACK が返らない** → 経路の片方向遮断、戻り経路の NAT/FW
- **RST が即返る** → サーバー側でポート閉鎖、SG/FW で拒否
- **TLS ClientHello の後に応答なし** → SNI ホスト名と証明書設定の不一致、TLS バージョン不整合

### 5.3 nc — 単純疎通

```bash
# Linux から TCP 443 の疎通確認のみ（ペイロードは送らない）
$ nc -zv example.com 443
Connection to example.com (93.184.216.34) 443 port [tcp/https] succeeded!

# Windows PowerShell の等価
PS> Test-NetConnection example.com -Port 443 -InformationLevel Detailed
```

---

## 6. L7 (HTTP) — curl と時間分解

### 6.1 curl の verbose と時間内訳

```bash
$ cat > /tmp/curl-format.txt <<'EOF'
namelookup:  %{time_namelookup}
connect:     %{time_connect}
appconnect:  %{time_appconnect}
starttransfer: %{time_starttransfer}
total:       %{time_total}
size_download: %{size_download}
http_code:   %{http_code}
EOF

$ curl -s -o /dev/null -w '@/tmp/curl-format.txt' https://example.com
namelookup:  0.012
connect:     0.021
appconnect:  0.082          <-- TLS ハンドシェイク完了まで
starttransfer: 0.151        <-- 最初の 1 バイト到達まで
total:       0.182
size_download: 1256
http_code:   200
```

**読み方**:

| 指標 | 内訳 | 高い時の疑い |
|---|---|---|
| `time_namelookup` | DNS 解決時間 | リゾルバ遅延、外部 DNS への到達性 |
| `time_connect` | TCP 3-way handshake | 経路 RTT、SG / FW の遅延 |
| `time_appconnect` − `time_connect` | TLS ハンドシェイク | 証明書チェーン取得（OCSP / AIA）、TLS バージョン互換 |
| `time_starttransfer` − `time_appconnect` | アプリ初期処理 | サーバー側 CPU / DB / 認証 |
| `time_total` − `time_starttransfer` | 本体ダウンロード | サイズ、回線帯域 |

「サイトが遅い」という曖昧な問い合わせを、**どの区間が遅いか**まで分解できると、上位担当への引き渡しが格段に楽になります。

### 6.2 verbose の代表的な落とし穴

```bash
$ curl -v https://example.com 2>&1 | head -25
*   Trying 93.184.216.34:443...
* Connected to example.com (93.184.216.34) port 443
* ALPN: offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN),  TLS handshake, Server hello (1):
* TLSv1.2 (IN),  TLS handshake, Certificate (11):
* TLSv1.2 (IN),  TLS handshake, Server key exchange (12):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
* Server certificate:
*  subject: CN=example.com
*  start date: Jan 13 00:00:00 2026 GMT
*  expire date: Feb 13 23:59:59 2027 GMT
*  issuer: C=US, O=DigiCert Inc, CN=DigiCert TLS RSA SHA256 2020 CA1
*  SSL certificate verify ok.
> GET / HTTP/1.1
> Host: example.com
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/1.1 200 OK
```

`SSL certificate verify ok` の手前で失敗するなら証明書側の問題、`HTTP/1.1 200 OK` 以降で遅いならアプリ側の問題、というように **どこで止まるかで責任分界を分けられる**のが curl -v の価値です。

---

## 7. Windows 側の同等コマンド

ユーザー端末（Windows）に走らせてもらう時の対応表です。

| Linux | Windows PowerShell |
|---|---|
| `ip -br link` | `Get-NetAdapter` |
| `ip route` | `Get-NetRoute` |
| `arp -a` | `Get-NetNeighbor` |
| `ping -c 5` | `Test-Connection -Count 5` |
| `traceroute` | `Test-NetConnection -TraceRoute` |
| `dig` | `Resolve-DnsName` |
| `nc -zv host 443` | `Test-NetConnection host -Port 443` |
| `ss -tnp` | `Get-NetTCPConnection \| ?{$_.State -eq 'Established'}` |
| `openssl s_client` | `Invoke-WebRequest -Uri https://...` + `$_.ServicePoint.Certificate` |

> ポートフォリオ内の [`support-scripts/Test-NetworkTriage.ps1`](../support-scripts/Test-NetworkTriage.ps1) は、これらを 1 本で叩いて結果を CSV に落とす Windows 一次切り分けスクリプトです。

---

## 8. 切り分け中の証跡保存

トラブル中に**何を見たか**を残しておくと、再発分析と引き継ぎが楽になります。

```bash
# 1) すべての出力を1つのディレクトリに集める
TS=$(date +%Y%m%d-%H%M%S)
DIR=~/triage/$TS
mkdir -p "$DIR"

# 2) 切り分け結果を順に保存
ip -br link             > "$DIR/01-link.txt"
ip route                > "$DIR/02-route.txt"
ss -tlnp                > "$DIR/03-listen.txt"
ping -c 5 192.0.2.1     > "$DIR/04-ping-gw.txt"  2>&1
mtr -rwc 20 example.com > "$DIR/05-mtr-out.txt"  2>&1
dig +trace example.com  > "$DIR/06-dig-trace.txt" 2>&1
curl -v https://example.com > "$DIR/07-curl-v.txt" 2>&1

# 3) tar に固めてチケットに添付
tar czf "${DIR}.tar.gz" -C ~/triage "$TS"
```

公開リポジトリではこの「フォルダ単位の証跡」は載せていません。代わりに [`infra-evidence/network-triage.sample.txt`](../infra-evidence/network-triage.sample.txt) で、上記の `01-link.txt` 〜 `07-curl-v.txt` 相当のサンプル出力を 1 ファイルに整理しています。

---

## 関連

- [Linux Operation Lab](../linux-lab.html) — systemd / journalctl / SSH / rsync の運用設計
- [Infra Operation Lab](../infra-lab.html) — Windows / M365 / AD 想定の運用設計
- [`support-scripts/Test-NetworkTriage.ps1`](../support-scripts/Test-NetworkTriage.ps1) — Windows 一次切り分け
- [`support-scripts/linux-triage.sh`](../support-scripts/linux-triage.sh) — Linux 一次切り分け
- [Infra Evidence](../infra-evidence/) — 実行サンプル出力
- [障害対応事例集](./troubleshooting-case-studies.md) — 10 ケースの切り分け事例
- [SLO / Error Budget](./slo-error-budget.md) — `blackbox_exporter` での外形監視
