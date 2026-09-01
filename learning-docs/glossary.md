# 一言用語集

| 用語 | 一言で | このLabでの確認 |
|---|---|---|
| <a id="term-os"></a>OS | hardwareとapplicationの間で基本機能を提供するsoftware | `cat /etc/os-release` |
| <a id="term-application"></a>Application | 利用目的のために動くprogram | Web serviceの応答を確認 |
| <a id="term-file"></a>File | 名前を付けて保存したdata | `ls -l` / `cat` |
| <a id="term-directory"></a>Directory | fileやdirectoryをまとめる場所 | `pwd` / `ls` |
| <a id="term-terminal"></a>Terminal | 文字で入出力するための画面 | Windows Terminalなどを開く |
| <a id="term-shell"></a>Shell | 入力したcommandを解釈するprogram | `echo "$SHELL"` |
| <a id="term-command"></a>Command | shellへ依頼する命令 | command名、option、argumentに分ける |
| <a id="term-option"></a>Option | commandの動作を切り替える指定 | `ls -l`の`-l` |
| <a id="term-argument"></a>Argument | commandが処理する対象や値 | `cat note.txt`の`note.txt` |
| <a id="term-history"></a>history | 実行したcommandを記録した履歴 | `history` |
| <a id="term-stdout-stderr"></a>Standard output / error | 通常結果とerrorを分ける出力経路 | 表示とexit codeを保存 |
| <a id="term-env-var"></a>Environment variable | processへ渡す名前付きの設定値 | `printenv HOME`。秘密情報は表示・保存しない |
| <a id="term-admin-user"></a>Administrator / general user | 全体を変更できる強い権限 / 通常作業の権限 | `whoami`。通常は一般userから開始 |
| <a id="term-sudo"></a>sudo | 一般userのまま一時的に管理者権限でcommandを実行する仕組み | `sudo -l`(自分が実行できる範囲を確認) |
| <a id="term-process"></a>Process | 実行中のprogramの単位 | `ps` |
| <a id="term-service"></a>Service | backgroundで継続して機能を提供するprocess(例: 画面を閉じても動き続けるWebサーバーなど) | `systemctl status` |
| <a id="term-daemon"></a>daemon | 常駐してbackgroundで動き続けるprocess(Serviceの実体) | `systemctl status docker`などで稼働を確認 |
| <a id="term-socket"></a>socket | processが通信を送受信する出入口(fileのように扱えるものもある) | `ls -l /var/run/docker.sock` |
| <a id="term-host"></a>Host | network上で識別されるcomputerやVM | `hostname` |
| <a id="term-client-server"></a>Client / Server | 要求する側 / 機能を提供する側 | clientから`curl`してserver logを確認 |
| <a id="term-localhost"></a>localhost | 今操作している環境自身を指す名前 | `getent hosts localhost` |
| <a id="term-package"></a>Package | 導入・更新しやすくまとめたsoftware | package名とversionを記録 |
| <a id="term-repository"></a>Repository | packageやsource codeを保管・配布する場所 | 配布元を確認 |
| <a id="term-ip"></a>IP address | 機器の通信上の住所 | `ip address` |
| <a id="term-cidr"></a>CIDR | IP範囲を `/24` などで表す書き方(例: `/24`は256個のアドレス) | 管理元を `/32` に限定 |
| <a id="term-subnet"></a>Subnet | 同じ通信範囲として分けたネットワーク | Public / Privateを分離 |
| <a id="term-route"></a>Route | 宛先までの次の送り先(例: `0.0.0.0/0 → 192.168.1.1`なら、すべての宛先をまず192.168.1.1経由で送る) | `ip route` |
| <a id="term-dns"></a>DNS | 名前をIPへ変換する仕組み | `dig` / `resolvectl` |
| <a id="term-port"></a>Port | 1台の中で通信先サービスを分ける番号 | `ss -lntp` |
| <a id="term-tcp"></a>TCP | 順序と到達を保証する通信方式(protocolの一種) | `ss -lntp`の`t` |
| <a id="term-protocol"></a>protocol | 通信の手順を決めた取り決め(例: TCP、HTTP) | 宛先のprotocol/portを記録 |
| <a id="term-firewall"></a>Firewall | 通信条件により許可・拒否する境界 | 許可/拒否を両方試験 |
| <a id="term-sg"></a>SG(Security Group) | VMやhost単位で通信を許可・拒否するcloudの設定 | Bastion SG / App SGの許可元を確認 |
| <a id="term-bastion"></a>Bastion | 管理接続を中継・集約する踏み台 | Privateへの入口を限定 |
| <a id="term-ssh"></a>SSH | 暗号化された遠隔管理通信 | 鍵認証と接続元制限 |
| <a id="term-fingerprint"></a>fingerprint | 鍵の内容を短く要約した値。本人確認に使う | 接続時に表示された値を、VM作成時のコンソール出力など別経路の記録と突き合わせる |
| <a id="term-systemd"></a>systemd | Linuxのserviceを管理する仕組み | `systemctl status` |
| <a id="term-unit"></a>unit | systemdが管理する1つの対象(serviceなど) | `systemctl status <unit名>` |
| <a id="term-container"></a>Container | processと依存関係を隔離して配る単位 | Docker Composeで起動 |
| <a id="term-image"></a>Image | containerを作る読取専用のひな型 | versionを固定 |
| <a id="term-iac"></a>IaC | インフラ設定をcodeとして管理する方法 | Ansible / Terraform |
| <a id="term-playbook"></a>playbook | Ansibleで実行するtaskをまとめた手順書(yaml) | `ansible-playbook playbook.yml --syntax-check` |
| <a id="term-inventory"></a>inventory | Ansibleが操作対象とするhostの一覧 | `inventory.ini`の中身、`-i inventory.ini` |
| <a id="term-task"></a>task | playbook内で実行する1つの操作単位 | 実行結果をtask名ごとに確認 |
| <a id="term-module"></a>module | taskが呼び出す個別の処理部品(例: apt、service) | taskが使うmodule名を確認 |
| <a id="term-idempotency"></a>冪等性 | 同じ操作を繰り返しても余計な変更がない性質 | 2回目 `changed=0` |
| <a id="term-metrics"></a>Metrics | 時系列の数値データ | CPU、memory、disk |
| <a id="term-collector"></a>collector | metricsやlogを集めて保存側へ送る役割 | collector自身の起動状態を確認 |
| <a id="term-prometheus"></a>Prometheus | metricsを収集しalert条件を評価する監視tool | `http://localhost:9090`を開く |
| <a id="term-logs"></a>Logs | eventを時刻順に残した記録 | journal / Loki |
| <a id="term-alert"></a>Alert | 条件を超えたことを知らせる仕組み | 発生と復旧を確認 |
| <a id="term-dead-man-alert"></a>dead-man alert | 監視自身の停止を検知する逆方向のalert(heartbeatが途切れたら発報) | heartbeat欠損時の発報条件を確認(実際の発報試験はNOT RUN) |
| <a id="term-webhook"></a>webhook | eventが起きた時に指定URLへ自動でHTTP通知する仕組み | local webhookへテスト通知を送信 |
| <a id="term-rate-limit"></a>rate limit | 一定時間あたりの要求数を制限する仕組み | 送信先の上限を確認してから試験 |
| <a id="term-runbook"></a>Runbook | 状況別の具体的な運用手順 | alertからリンク |
| <a id="term-slo"></a>SLO | 利用者に提供したい品質目標 | 可用性、応答時間 |
| <a id="term-rto-rpo"></a>RTO | 障害から復旧するまでの目標時間 | timerで実測 |
| RPO | 失ってよいデータ時間の上限 | backup時刻と比較 |
| <a id="term-rollback"></a>Rollback | 変更前の状態へ戻すこと | 前版へ切り戻し |
| <a id="term-artifact"></a>Artifact | CIが保存する結果ファイル | report / log / checksum |
| <a id="term-checksum"></a>Checksum | ファイルが同じか確かめる要約値 | `sha256sum` |
| <a id="term-not-run"></a>NOT RUN | 手順はあるが未実行 | 実績と分けて表示 |
