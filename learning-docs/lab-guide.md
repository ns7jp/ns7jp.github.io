# 8段階ハンズオン

各段階で `目的 → 前提 → 操作 → 期待結果 → 失敗時 → 合格条件` を確認します。コマンドの意味を説明できない場合は、先に[用語集](./glossary.md)と[CUI入門](../cui-manual.html)（CUIは、文字を打ち込んでコンピューターを操作する方式）を確認します。

> **かんたんに言うと** Linuxサーバーを1台つくって運用するまでを、8つの段階に分けた練習メニューです。どの段階でも「何のためにやるか（目的）」「始める前に必要なもの（前提）」「実際の作業（操作）」「うまくいった時の状態（期待結果）」「うまくいかない時の対処（失敗時）」「次へ進んでよい基準（合格条件）」の6点を必ず確認します。

## Step 0 — 安全境界と環境採録

- **目的**: 壊してよい対象を一意にする。つまり、失敗しても困らない練習用の環境を1つだけ決め、それ以外の機器には触れないようにする。
- **前提**: 自分が所有し、削除してよい Ubuntu VM / WSL2。VM（仮想マシン）はパソコンの中に作るもう1台の仮想のコンピューター、WSL2はWindowsの中でLinuxを動かす仕組みである。
- **操作**: 下の準備を終えてから `bash scripts/capture-lab-evidence.sh preflight` を実行する。preflight（プリフライト）は「作業前の事前確認」という意味で、このコマンドは今の環境の情報をまとめて記録する。作業前の状態を残しておくと、後から「どこが変わったのか」を比べられるためである。出力を読み、秘密情報が含まれていないことを確認する。
- **期待結果**: `infra-evidence/measured/<日時>-preflight/metadata.txt` と checksum（チェックサム／ファイルが後から書き換えられていないか確かめるための短い要約値）が作られる。
- **失敗時**: 必要なコマンドが入っていない場合は、追加インストールをする前に「何が無かったか」を記録する。後から環境を再現するときに、最初の状態が分かるようにするためである。今操作している環境が実機（自分の本物のパソコン）かVMか判断できないときは、そこで中止する。壊してよい環境か確信が持てないまま進めないためである。
- **合格条件**: OS、CPU、メモリ、ディスク、仮想化方式、削除方法を説明できる。

**初回だけの準備（Ubuntu のターミナル）:** [環境準備](./environment-setup.md)と[最初の30分](./first-30-minutes.md)を終え、`git --version` が表示されることを確認します。Git がなければ、その不足を記録してから練習用 Ubuntu 内で `sudo apt update`、`sudo apt install git` を実行します。次を1行ずつ実行し、途中で失敗したらその行で止まります。

```bash
mkdir -p ~/server-lab
cd ~/server-lab
git clone https://github.com/ns7jp/ns7jp.github.io.git
cd ns7jp.github.io
pwd
ls scripts/capture-lab-evidence.sh infra-evidence/measured
bash scripts/capture-lab-evidence.sh preflight
```

`clone` は教材一式を自分の環境へコピーする操作、`cd` は作業するフォルダーを移る操作です。次回は `cd ~/server-lab/ns7jp.github.io` から再開し、同じ場所へもう一度 clone しません。別の場所へ取得済みなら、そのフォルダーへ移動して `ls` の行から確認します。記録の初期表示 `MEASURED_REVIEW_REQUIRED` は「採録できたので内容を確認する」という意味です。この実行だけでは、サーバー構築や各試験の成功は証明できません。

## Step 1 — 要件と設計

- **目的**: 構築前に完成条件を決める。
- **前提**: 利用者、用途、許容停止時間を仮定できる。
- **操作**: 利用者、入口、通信元/先/port（ポート番号。1台の中で通信の相手先サービスを分ける番号）、データ、RTO/RPO、監視、除外範囲を記入する。RTOは障害から復旧するまでの目標時間、RPOは失ってもよいデータの時間の上限である。構成図の通信には1本ずつ番号を付ける。後の試験結果と「何番の通信を確かめたか」を対応づけるためである。
- **期待結果**: 要件の各項目が設計、試験、運用手順のどれかへ追跡できる。
- **失敗時**: 技術名だけの要件は「誰の何を解決するか」へ書き直す。
- **合格条件**: 目的、構成、非対象を1分で説明できる。

## Step 2 — 最小OS

- **目的**: 構築前の初期状態を再現する。
- **前提**: 2 CPU、4 GB RAM（メモリ）、20 GB disk（ディスク＝保存領域）を目安としたUbuntu 24.04のVMを用意する。実際に用意できた値は、目安ではなく実測した値のほうを記録する。
- **操作**: 次の順で進める。(1) 日常作業に使う一般ユーザーを作る（例: `sudo adduser <username>`）。強い権限を持つ管理者のまま作業を続けないためである。(2) `sudo apt update && sudo apt upgrade`で、導入済みのソフトを最新の状態へ更新する。(3) `timedatectl`で時刻が自動で合わせられているか確認する。時刻がずれると、記録の前後関係を追えなくなるためである。(4) 管理端末で`ssh-keygen -t ed25519`を実行し、SSHの鍵を作る。SSHは通信を暗号化して遠くのサーバーを操作する仕組みで、鍵はパスワードの代わりになる本人確認用のデータである。作った公開鍵をサーバー側へ登録し、鍵だけで接続できることを確かめる。(5) `sudo reboot`で再起動し、もう一度接続する。設定が再起動後も残ることを確認するためである。
- **期待結果**: passwordをGitへ残さず、再起動後も鍵で接続できる。
- **失敗時**: sshd（SSHの接続を受け付けるサービス）を再起動する前に、必ず`sshd -t`で設定ファイルの文法を検査する。設定を間違えたまま再起動すると、二度と接続できなくなるためである。作業中の接続（セッション）は閉じずに残しておく。閉じてしまった場合は、VMの管理画面から使えるconsole（コンソール＝画面から直接操作する経路）で入り直し、設定を戻す。
- **合格条件**: 入れたばかりのclean OS（何も設定していないまっさらな状態のOS）から行った操作ログと、再起動後の確認結果を、MEASURED（実際に自分の環境で測った結果、という区分）として残す。この記録があれば「同じ手順をもう一度再現できる」と説明できる。

> このリポジトリでは上記の独立VM実測は **NOT RUN**（手順は用意してあるが、まだ実行していない、という区分）です。実際に実施したあとで初めて、この区分の表示を変更します。

## Step 3 — 最小サービスを手動構築

- **目的**: 自動化対象を理解する。
- **前提**: Docker が動く自分専用の練習環境。`docker version` で Client と Server の両方を確認する。以下は標準の bridge ネットワークを使う Docker Engine 28.0.0 以降を前提とし、独自のネットワーク設定は追加しない。
- **操作 A — Docker の Web**: 次のコマンドを Docker が動く Ubuntu 側で1行ずつ実行する。`127.0.0.1` はその環境自身を指す。`127.0.0.1:8080:80` は「この環境の8080番から、コンテナ内の80番へ渡す」という対応である。

```bash
docker run -d --name lab-web -p 127.0.0.1:8080:80 nginx:stable
docker port lab-web
curl -I http://127.0.0.1:8080/
docker logs --tail 20 lab-web
```

- **期待結果 A**: ポート表示が `127.0.0.1:8080`、HTTP の応答が `200 OK` になる。名前やポートが使用中なら、新しく起動を繰り返さず `docker ps -a` で対象を確認する。使ったイメージの版も記録する。片付けは `docker stop lab-web`、再開は `docker start lab-web`。`stable` タグの中身は更新されるため、タグ名だけで同じ版を再現できたとは判断しない。
- **操作 B — VM ホストの SSH と Firewall**: これは A とは別の通信試験。Step 2 を終えた Ubuntu VM で、snapshot と console を確保し、現在の SSH 接続を残す。`sudo ufw status verbose` で既存ルールを確認してから、実際の管理元の範囲へ置き換えた `sudo ufw allow from <管理CIDR> to any port 22 proto tcp`、`sudo ufw default deny incoming`、`sudo ufw enable` を順に実行する。CIDR は IP アドレスの範囲を表す記法で、`<管理CIDR>` はそのまま入力しない。管理元から新しい SSH 接続を開き、許可範囲外の自分の試験端末からは接続できないことを確認する。
- **期待結果 B**: VM ホストの SSH について、許可・拒否の両方を接続結果と UFW の表示で説明できる。拒否側の端末を用意できない場合は、その確認を **NOT RUN** と記録する。通信失敗だけでは UFW が原因とは断定せず、経路や他のルールも確認する。
- **失敗時**: DNS（名前をIPアドレスへ変換する仕組み）、route（宛先までの通り道）、TCP（相手へ届いたか確認しながら送る通信方式）、service（動き続けて機能を提供するプログラム）、application（利用目的のために動くプログラム）の順で確認する。土台に近いものから順に見ていくと、どこで通信が止まっているかを1つずつ絞り込めるためである。
- **合格条件**: A と B を別々に記録し、接続元 → 宛先 → protocol/port → process → logを図と結果票で対応づける。

**Docker と UFW の違い:** Docker が公開するポートへの通信は UFW の処理を迂回するため、「UFW を有効にしたから Docker も外部から遮断できた」とは言えません。[Docker 公式の UFW 説明](https://docs.docker.com/engine/network/packet-filtering-firewalls/#docker-and-ufw)を確認してください。A は loopback（自分自身への通信先）へ明示的に割り当てるローカル練習です。Docker 28.0.0 より前には同じ LAN から到達できる例外があるため、古い版なら先に更新します。[ポート公開の公式説明](https://docs.docker.com/engine/network/port-publishing/)も参照してください。A の成功は、別端末からの Web 接続や外部遮断試験の成功を意味しません。

## Step 4 — Ansibleで自動化

> **かんたんに言うと** Ansibleという道具に「ほしい状態」を書き、同じ構成を繰り返し作る練習です。以下の最小サンプルは、Ubuntu VM 本体に nginx を入れる独立した入門演習です。Step 3 A の Docker コンテナを自動化する内容ではありません。

- **目的**: 再現性と冪等性を確認する。冪等性（べきとうせい）とは、同じ操作を何度実行しても結果が変わらない性質のことである。
- **前提**: Ansible を実行する Linux 側の管理端末と、Step 2・Step 3 B の確認を終えた使い捨て Ubuntu VM。管理端末から鍵で SSH 接続できること。VM は公開用のポート転送がない隔離した Lab とし、既存 nginx のある環境ではこの例を適用しない。サンプルは VM 本体の80番を使い、Docker の8080番とは別のサービスになる。
- **操作**: 次の順で実行する。(1) `ansible-playbook --syntax-check`で、手順書の書き方に誤りがないか調べる。(2) `--check --diff`で、実際には変更せずに「何が変わる予定か」だけを表示させる。(3) 問題がなければapply（実際に適用する実行）を行う。(4) もう一度applyして、2回目の結果を見る。いきなり本番を変更せず、影響を先に確認するためである。
- **期待結果**: 1回目の直後にもう一度実行して `changed=0` を確認する。これは「変更した項目が0件」という意味で、1回目ですでに目的の状態になっていることを示す。差分も、自分が意図したものだけが出る。
- **失敗時**: task名、対象host、変数、権限、moduleの順に読む。いきなり `ignore_errors` を足さない。
- **合格条件**: 実行版、inventory、結果、差分、切り戻し方法がそろう。

### 付録: 最小構成のplaybook/inventory例

以下はStep 4で使う最小構成のサンプルです（IPやhost名は架空。実際の値は各自の環境に置き換えます）。YAMLはtabを使わず半角スペースのインデントで階層を表し、`key: value`の形と`-`で始まるリストだけで書けます。

`inventory.ini`:

```ini
[web]
lab-vm ansible_host=192.0.2.10 ansible_user=deploy ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

`playbook.yml`:

```yaml
---
- name: Deploy minimal web service
  hosts: web
  become: true
  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Install nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Ensure nginx is running
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
```

実行例: `ansible-playbook -i inventory.ini playbook.yml --syntax-check`

`inventory.ini` と `playbook.yml` は管理端末の同じ作業フォルダーに保存します。`192.0.2.10` は説明用のアドレスなので実機の値に置き換え、`deploy` と鍵の場所も Step 2 で確認したものを指定します。以後は同じフォルダーで、`ansible-playbook -i inventory.ini playbook.yml --check --diff`、`ansible-playbook -i inventory.ini playbook.yml`、もう一度同じ適用コマンド、の順に実行します。対象 VM の `sudo` にパスワードが必要なら、これらのコマンドへ `--ask-become-pass` を付け、画面の質問に入力します。鍵やパスワードはファイル例に書き込みません。

`cache_valid_time: 3600` は、パッケージ一覧の更新を1時間以内は繰り返さない指定です。1時間後に一覧更新で `changed` が出ても、それだけで冪等性の失敗とは判断しません。[apt モジュールの説明](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/apt_module.html)を参照してください。`--check` は予測であり、未導入のサービスなどを完全には検証できません。[check mode の説明](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_checkmode.html)も確認します。適用後は **対象 VM 内** で `systemctl status nginx` と `curl -I http://127.0.0.1/` を確認します。`changed=0` だけでは Web 応答や通信制限の成功を証明できません。

## Step 5 — 監視と通知

- **目的**: 異常を利用者より先に検知する。
- **操作**: 監視の対象（target）、CPU、memory（メモリ）、disk（ディスクの空き）、service（動作中のサービス）、log（記録）を確認する。テストアラート（試験用の警報）を、自分の環境の中だけで動くwebhook（何かが起きた時に、決めたURLへ自動で通知を送る仕組み）へ送る。外部へ情報を出さずに通知の経路を試すためである（例: `curl -X POST -H 'Content-Type: application/json' -d '{"text":"test alert"}' http://localhost:5001/webhook`）。
- **期待結果**: 発生、通知、確認、復旧の時刻がつながる。
- **失敗時**: 監視される側だけでなく、監視する側そのものも確認する。具体的には、Prometheus（数値を集めて警報の条件を判定する監視ツール）、collector（数値やログを集めて送る役割）、notification経路（通知が届くまでの道すじ）が止まっていないかを見る。監視の仕組み自体が止まっていると、異常が起きても何も鳴らないためである。
- **合格条件**: alertから対応Runbookへ移動でき、正常復帰も確認できる。

> Slack実通知と72時間連続試験は **NOT RUN**。送信先、個人情報、rate limitを確認後に行います。

## Step 6 — 障害対応

- **目的**: 勘ではなく仮説と事実で原因を狭める。
- **操作**: [failure-drills.md](./failure-drills.md)から、必要な構成を用意できたものを最低3件選ぶ。復旧前に現象、影響、時刻、直前変更、仮説を記入する。Step 3 A だけでは監視、CPU・メモリ制限、HTTPS、バックアップは未準備であり、該当する演習へはまだ進めない。
- **期待結果**: 各確認が「何を否定/肯定したか」を説明できる。
- **失敗時**: 記録なしの再起動、同時に複数変更、証拠の削除を避ける。
- **合格条件**: 原因、復旧、再発防止、残課題を第三者が追える。

調べる対象に合わせて、コマンドを選びます。

| 対象 | 状態とログの確認 | 停止後の再開 |
|---|---|---|
| Step 3 A の Docker コンテナ `lab-web` | `docker ps -a`、`docker logs --tail 20 lab-web` | `docker start lab-web` |
| Step 4 の VM 本体の nginx | `systemctl status nginx`、`sudo journalctl -u nginx -n 20 --no-pager`。HTTP のアクセス記録は `/var/log/nginx/access.log` | 対象 VM 内で `sudo systemctl start nginx` |

障害演習表の `docker compose` は Compose の設定ファイルで作った環境向けです。Step 3 A の `docker run` で作った環境では、上表のコマンドを使います。D-01 のアラート復旧まで確認するには Step 5 の監視が必要です。D-02 の UFW 試験は VM ホストの通信を対象とし、Docker の公開ポートを UFW で遮断する演習には読み替えません。準備できない項目は **NOT RUN** と記録します。

## Step 7 — 別ホスト復元と引き渡し

> **かんたんに言うと** バックアップは、取っただけでは「戻せる」と言えません。そこで、元のサーバーとは別の新しいサーバー（別ホスト）へ実際に復元し、そこでサービスが動くところまで確かめます。元のサーバーが完全に壊れても復旧できる、という確認です。

- **目的**: バックアップが実際に使えることを確認する。
- **操作**: 新しいVMを用意し、次を順に行う。(1) checksumで、バックアップが壊れていないか確認する。(2) 復元する。(3) service（サービス）を起動する。(4) データが欠けていないか確かめる。(5) 復旧にかかった時間と、失われたデータの時間幅を測り、RTO/RPOの実測値として記録する。目標値だけでなく実測値を持てば、面接でも「何分で戻せたか」を数字で説明できる。
- **期待結果**: 元hostを参照せず新規hostで受入試験に合格する。
- **失敗時**: 元データを変更せず、別世代、権限、version互換性を確認する。
- **合格条件**: 結果票、実測RTO/RPO、切り戻し、残課題、廃棄方法を引き渡せる。

> 別host復元は **NOT RUN**。同一環境への復元実績と混同しません。
