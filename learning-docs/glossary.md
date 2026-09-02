# 一言用語集

この表は、この教材(Lab)の演習で出てくる言葉を、一言で確認するための一覧です。

> **かんたんに言うと** 「用語」はことばの名前、「一言で」はその意味、「このLabでの確認」は自分の環境で実際に確かめるためのコマンドや操作です。意味を読むだけで終わらせず、3列目を自分で動かすと記憶に残ります。

| 用語 | 一言で | このLabでの確認 |
|---|---|---|
| <a id="term-os"></a>OS | 基本ソフト。ハードウェア(機械そのもの)とアプリの間に入り、基本の機能を提供する | `cat /etc/os-release` |
| <a id="term-application"></a>Application | 利用目的のために動くプログラム。いわゆるアプリ | Webサービスの応答を確認 |
| <a id="term-file"></a>File | 名前を付けて保存したデータ | `ls -l` / `cat` |
| <a id="term-directory"></a>Directory | ファイルやディレクトリ(フォルダー)をまとめる入れ物 | `pwd` / `ls` |
| <a id="term-terminal"></a>Terminal | 文字で入出力するための画面 | Windows Terminalなどを開く |
| <a id="term-shell"></a>Shell | 入力したコマンドを受け取り、実行につなぐプログラム | `echo "$SHELL"` |
| <a id="term-command"></a>Command | シェルへ依頼する命令 | コマンド名、オプション、引数に分けて読む |
| <a id="term-option"></a>Option | コマンドの動きを切り替える指定 | `ls -l`の`-l` |
| <a id="term-argument"></a>Argument | コマンドが処理する対象や値。ファイル名など | `cat note.txt`の`note.txt` |
| <a id="term-history"></a>history | 実行したコマンドを記録した履歴 | `history` |
| <a id="term-stdout-stderr"></a>Standard output / error(標準出力・標準エラー出力) | 通常の結果とエラーを分けて流す出力の通り道 | 画面表示とexit code(コマンドの終了状態を表す数値)を保存 |
| <a id="term-env-var"></a>Environment variable | プロセス(実行中のプログラム)へ渡す、名前の付いた設定値 | `printenv HOME`。秘密情報は表示・保存しない |
| <a id="term-admin-user"></a>Administrator / general user | 管理者は全体を変更できる強い権限。一般ユーザーは通常作業の権限 | `whoami`で今の自分を確認。誤操作の影響を小さくするため、通常は一般ユーザーから始める |
| <a id="term-sudo"></a>sudo | 一般ユーザーのまま、一時的に管理者権限でコマンドを実行する仕組み | `sudo -l`(自分が実行できる範囲を確認) |
| <a id="term-process"></a>Process | 実行中のプログラム1つ分の単位 | `ps` |
| <a id="term-service"></a>Service | 画面の裏側(background)で動き続け、機能を提供するプロセス(例: 画面を閉じても動き続けるWebサーバーなど) | `systemctl status` |
| <a id="term-daemon"></a>daemon | 常駐して裏側で動き続けるプロセス。読みは「デーモン」でServiceの実体 | `systemctl status docker`などで稼働を確認 |
| <a id="term-socket"></a>socket | プロセスが通信をやり取りする出入口。ファイルのように扱えるものもある | `ls -l /var/run/docker.sock` |
| <a id="term-host"></a>Host | ネットワーク上で1台として識別されるコンピューターやVM(仮想マシン) | `hostname` |
| <a id="term-client-server"></a>Client / Server | 要求する側 / 機能を提供する側 | client側から`curl`で要求を送り、server側のログ(記録)を確認 |
| <a id="term-localhost"></a>localhost | 今操作している環境自身を指す名前 | `getent hosts localhost` |
| <a id="term-package"></a>Package | 導入や更新をしやすい形にまとめたソフト | パッケージ名とバージョンを記録 |
| <a id="term-repository"></a>Repository | パッケージやソースコード(プログラムの元の文)を保管し、配る場所 | 配布元を確認 |
| <a id="term-ip"></a>IP address | 機器の通信上の住所 | `ip address` |
| <a id="term-cidr"></a>CIDR | IPアドレスの範囲を `/24` などで表す書き方(例: `/24`は256個のアドレス) | 接続を許可する管理元を `/32`(1つのアドレスだけ)に限定する |
| <a id="term-subnet"></a>Subnet | 同じ通信範囲としてまとめ、区切ったネットワーク | 公開側(Public)と非公開側(Private)に分ける |
| <a id="term-route"></a>Route | 宛先までの次の送り先(例: `0.0.0.0/0 → 192.168.1.1`なら、すべての宛先をまず192.168.1.1経由で送る) | `ip route` |
| <a id="term-dns"></a>DNS | ホスト名(example.comのような名前)をIPアドレスへ変換する仕組み | `dig` / `resolvectl` |
| <a id="term-port"></a>Port | 1台の中で通信先サービスを分ける番号 | `ss -lntp` |
| <a id="term-tcp"></a>TCP | データの順序と到達を保証する通信方式。protocol(通信の取り決め)の一種 | `ss -lntp`の`t`がTCPを指す |
| <a id="term-protocol"></a>protocol | 通信の手順を決めた取り決め(例: TCP、HTTP) | 宛先のprotocolとport番号を記録 |
| <a id="term-firewall"></a>Firewall | 決めた条件で通信を許可・拒否する関所 | 許可される通信と拒否される通信の両方を試す |
| <a id="term-sg"></a>SG(Security Group) | VMやhost単位で通信を許可・拒否するcloud(クラウド)側の設定 | Bastion用SGとApp用SGで、通信を許可する接続元を確認 |
| <a id="term-bastion"></a>Bastion | 管理用の接続を1か所へ集めて中継するサーバー。踏み台とも呼ぶ | 非公開側(Private)への入口を1か所に限定する |
| <a id="term-ssh"></a>SSH | 通信を暗号化して離れたサーバーを操作する仕組み | 鍵による認証と、接続元の制限を設定する |
| <a id="term-fingerprint"></a>fingerprint | 鍵の内容を短く要約した値。本人確認に使う | なりすまし防止のため、接続時に表示された値を別経路の記録(VM作成時のコンソール出力など)と見比べる |
| <a id="term-systemd"></a>systemd | Linuxのサービスの起動・停止・自動起動を管理する仕組み | `systemctl status` |
| <a id="term-unit"></a>unit | systemdが管理する1つの対象。サービスなど | `systemctl status <unit名>` |
| <a id="term-container"></a>Container | プログラムと必要な部品(依存関係)をまとめ、他と隔離して配る単位 | Docker Composeで起動 |
| <a id="term-image"></a>Image | コンテナを作るための読み取り専用のひな型 | 毎回同じ状態で動かすため、versionを固定する |
| <a id="term-iac"></a>IaC | Infrastructure as Code。サーバーなどの設定を、手作業ではなくコード(設定ファイル)として管理する方法 | Ansible / Terraform |
| <a id="term-playbook"></a>playbook | Ansibleで実行するtask(処理)をまとめた手順書。yamlという書式で書く | `ansible-playbook playbook.yml --syntax-check` |
| <a id="term-inventory"></a>inventory | Ansibleが操作する相手のhost(機器)一覧 | `inventory.ini`の中身を確認し、`-i inventory.ini`で指定する |
| <a id="term-task"></a>task | playbook内で実行する1つの操作単位 | 実行結果をtask名ごとに確認 |
| <a id="term-module"></a>module | taskが呼び出す個別の処理部品(例: apt、service) | taskが使うmodule名を確認 |
| <a id="term-idempotency"></a>冪等性 | 読みは「べきとうせい」。同じ操作を何度繰り返しても結果が変わらず、余計な変更が起きない性質 | 2回目の実行で `changed=0`(変更なし)になることを確認 |
| <a id="term-metrics"></a>Metrics | 時間の経過にそって記録する数値データ | CPU、メモリ、ディスクの使用状況 |
| <a id="term-collector"></a>collector | metrics(数値)やlog(記録)を集め、保存する側へ送る役割 | 集める側が止まると監視も止まるため、collector自身の起動状態を確認 |
| <a id="term-prometheus"></a>Prometheus | metricsを集め、alert(通知)を出す条件を判定する監視ソフト | `http://localhost:9090`を開く |
| <a id="term-logs"></a>Logs | 起きたできごと(event)を時刻順に残した記録 | journal / Loki |
| <a id="term-alert"></a>Alert | 決めた条件を超えたことを知らせる通知の仕組み | 発生した時と、元に戻った時の両方の通知を確認 |
| <a id="term-dead-man-alert"></a>dead-man alert | 監視の仕組み自体が止まったことを知らせる逆向きのalert。定期信号(heartbeat)が途切れたら発報する | heartbeat(定期信号)が途切れた時の発報条件を確認。実際の発報試験はNOT RUN(未実施) |
| <a id="term-webhook"></a>webhook | できごと(event)が起きた時に、指定したURLへHTTPで自動通知する仕組み | 手元(local)のwebhookへテスト通知を送信 |
| <a id="term-rate-limit"></a>rate limit | 一定時間あたりに受け付ける要求の数を制限する仕組み | 送りすぎて止められないよう、送信先の上限を確認してから試す |
| <a id="term-runbook"></a>Runbook | 状況別に「何をするか」を書いた具体的な運用手順書 | alertの通知からRunbookへリンクしておく |
| <a id="term-slo"></a>SLO | Service Level Objective。利用者に提供したい品質の目標 | 可用性(止まらない割合)、応答時間 |
| <a id="term-rto-rpo"></a>RTO | Recovery Time Objective。障害から復旧するまでにかけてよい時間の目標 | 復旧までの時間をタイマーで実測 |
| RPO | Recovery Point Objective。失ってよいデータの時間の上限 | backupを取った時刻と比較 |
| <a id="term-rollback"></a>Rollback | 変更前の状態へ戻すこと | 1つ前の版へ戻す(切り戻す) |
| <a id="term-artifact"></a>Artifact | CI(変更のたびに自動で実行・確認する仕組み)が保存する結果ファイル | report(報告) / log(記録) / checksum |
| <a id="term-checksum"></a>Checksum | ファイルが同じか確かめる要約値 | `sha256sum` |
| <a id="term-not-run"></a>NOT RUN | 手順はあるが未実行 | 実測した実績とは分けて表示する |
