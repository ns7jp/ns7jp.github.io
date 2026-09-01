# 一言用語集

| 用語 | 一言で | このLabでの確認 |
|---|---|---|
| OS | hardwareとapplicationの間で基本機能を提供するsoftware | `cat /etc/os-release` |
| Application | 利用目的のために動くprogram | Web serviceの応答を確認 |
| File | 名前を付けて保存したdata | `ls -l` / `cat` |
| Directory | fileやdirectoryをまとめる場所 | `pwd` / `ls` |
| Terminal | 文字で入出力するための画面 | Windows Terminalなどを開く |
| Shell | 入力したcommandを解釈するprogram | `echo "$SHELL"` |
| Command | shellへ依頼する命令 | command名、option、argumentに分ける |
| Option | commandの動作を切り替える指定 | `ls -l`の`-l` |
| Argument | commandが処理する対象や値 | `cat note.txt`の`note.txt` |
| Standard output / error | 通常結果とerrorを分ける出力経路 | 表示とexit codeを保存 |
| Environment variable | processへ渡す名前付きの設定値 | `printenv HOME`。秘密情報は表示・保存しない |
| Administrator / general user | 全体を変更できる強い権限 / 通常作業の権限 | `whoami`。通常は一般userから開始 |
| Process | 実行中のprogramの単位 | `ps` |
| Service | backgroundで継続して機能を提供するprocess | `systemctl status` |
| Host | network上で識別されるcomputerやVM | `hostname` |
| Client / Server | 要求する側 / 機能を提供する側 | clientから`curl`してserver logを確認 |
| localhost | 今操作している環境自身を指す名前 | `getent hosts localhost` |
| Package | 導入・更新しやすくまとめたsoftware | package名とversionを記録 |
| Repository | packageやsource codeを保管・配布する場所 | 配布元を確認 |
| IP address | 機器の通信上の住所 | `ip address` |
| CIDR | IP範囲を `/24` などで表す書き方 | 管理元を `/32` に限定 |
| Subnet | 同じ通信範囲として分けたネットワーク | Public / Privateを分離 |
| Route | 宛先までの次の送り先 | `ip route` |
| DNS | 名前をIPへ変換する仕組み | `dig` / `resolvectl` |
| Port | 1台の中で通信先サービスを分ける番号 | `ss -lntp` |
| Firewall | 通信条件により許可・拒否する境界 | 許可/拒否を両方試験 |
| Bastion | 管理接続を中継・集約する踏み台 | Privateへの入口を限定 |
| SSH | 暗号化された遠隔管理通信 | 鍵認証と接続元制限 |
| systemd | Linuxのserviceを管理する仕組み | `systemctl status` |
| Container | processと依存関係を隔離して配る単位 | Docker Composeで起動 |
| Image | containerを作る読取専用のひな型 | versionを固定 |
| IaC | インフラ設定をcodeとして管理する方法 | Ansible / Terraform |
| 冪等性 | 同じ操作を繰り返しても余計な変更がない性質 | 2回目 `changed=0` |
| Metrics | 時系列の数値データ | CPU、memory、disk |
| Logs | eventを時刻順に残した記録 | journal / Loki |
| Alert | 条件を超えたことを知らせる仕組み | 発生と復旧を確認 |
| Runbook | 状況別の具体的な運用手順 | alertからリンク |
| SLO | 利用者に提供したい品質目標 | 可用性、応答時間 |
| RTO | 障害から復旧するまでの目標時間 | timerで実測 |
| RPO | 失ってよいデータ時間の上限 | backup時刻と比較 |
| Rollback | 変更前の状態へ戻すこと | 前版へ切り戻し |
| Artifact | CIが保存する結果ファイル | report / log / checksum |
| Checksum | ファイルが同じか確かめる要約値 | `sha256sum` |
| NOT RUN | 手順はあるが未実行 | 実績と分けて表示 |
