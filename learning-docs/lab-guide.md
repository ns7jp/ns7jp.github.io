# 8段階ハンズオン

各段階で `目的 → 前提 → 操作 → 期待結果 → 失敗時 → 合格条件` を確認します。コマンドの意味を説明できない場合は、先に[用語集](./glossary.md)と[CUI入門](../cui-manual.html)を確認します。

## Step 0 — 安全境界と環境採録

- **目的**: 壊してよい対象を一意にする。
- **前提**: 自分が所有し、削除してよい Ubuntu VM / WSL2。
- **操作**: `bash scripts/capture-lab-evidence.sh preflight`。出力を読み、秘密情報がないことを確認する。
- **期待結果**: `infra-evidence/measured/<日時>-preflight/metadata.txt` と checksum が作られる。
- **失敗時**: コマンド不足はインストール前に記録する。実機かVMか判断できなければ中止する。
- **合格条件**: OS、CPU、メモリ、ディスク、仮想化方式、削除方法を説明できる。

## Step 1 — 要件と設計

- **目的**: 構築前に完成条件を決める。
- **前提**: 利用者、用途、許容停止時間を仮定できる。
- **操作**: 利用者、入口、通信元/先/port、データ、RTO/RPO、監視、除外範囲を記入。構成図の通信へ番号を付ける。
- **期待結果**: 要件の各項目が設計、試験、運用手順のどれかへ追跡できる。
- **失敗時**: 技術名だけの要件は「誰の何を解決するか」へ書き直す。
- **合格条件**: 目的、構成、非対象を1分で説明できる。

## Step 2 — 最小OS

- **目的**: 構築前の初期状態を再現する。
- **前提**: 2 CPU、4 GB RAM、20 GB diskを目安としたUbuntu 24.04 VM。値は実測に合わせて記録する。
- **操作**: 一般ユーザー作成（例: `sudo adduser <username>`）、`sudo apt update && sudo apt upgrade`で更新、`timedatectl`で時刻同期を確認、管理端末で`ssh-keygen -t ed25519`により鍵を作成し公開鍵を登録してSSH鍵接続、`sudo reboot`で再起動、再接続。
- **期待結果**: passwordをGitへ残さず、再起動後も鍵で接続できる。
- **失敗時**: sshdを再起動する前に `sshd -t`。別セッションを閉じず、consoleから戻す。
- **合格条件**: clean OSからの操作ログと再起動後の確認をMEASUREDで残す。

> このリポジトリでは上記の独立VM実測は **NOT RUN**。実施後だけ状態を変更します。

## Step 3 — 最小サービスを手動構築

- **目的**: 自動化対象を理解する。
- **操作**: Docker導入、最小Webサービス起動、`ss -lntp`、`curl`、Firewall（`ufw`を使用。例: `sudo ufw allow from <管理CIDR> to any port 22 proto tcp`、`sudo ufw default deny incoming`、`sudo ufw enable`）の許可/拒否、`sudo ufw status verbose`とログで確認。
- **期待結果**: 管理元から許可portだけ接続でき、不要portは拒否される。
- **失敗時**: DNS、route、TCP、service、applicationの順で確認する。
- **合格条件**: 接続元 → 宛先 → protocol/port → process → logを図と結果票で対応づける。

## Step 4 — Ansibleで自動化

- **目的**: 再現性と冪等性を確認する。
- **操作**: `ansible-playbook --syntax-check` → `--check --diff` → apply → 2回目apply。
- **期待結果**: 2回目は `changed=0`。意図した差分だけが出る。
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

## Step 5 — 監視と通知

- **目的**: 異常を利用者より先に検知する。
- **操作**: target、CPU、memory、disk、service、logを確認。テストアラートをローカルwebhookへ送る（例: `curl -X POST -H 'Content-Type: application/json' -d '{"text":"test alert"}' http://localhost:5001/webhook`）。
- **期待結果**: 発生、通知、確認、復旧の時刻がつながる。
- **失敗時**: 監視対象だけでなく、Prometheus / collector / notification経路自身を確認する。
- **合格条件**: alertから対応Runbookへ移動でき、正常復帰も確認できる。

> Slack実通知と72時間連続試験は **NOT RUN**。送信先、個人情報、rate limitを確認後に行います。

## Step 6 — 障害対応

- **目的**: 勘ではなく仮説と事実で原因を狭める。
- **操作**: [failure-drills.md](./failure-drills.md)から最低3件。復旧前に現象、影響、時刻、直前変更、仮説を記入する。
- **期待結果**: 各確認が「何を否定/肯定したか」を説明できる。
- **失敗時**: 記録なしの再起動、同時に複数変更、証拠の削除を避ける。
- **合格条件**: 原因、復旧、再発防止、残課題を第三者が追える。

## Step 7 — 別ホスト復元と引き渡し

- **目的**: バックアップが実際に使えることを確認する。
- **操作**: 新規VMを用意し、checksum確認、復元、service起動、データ整合性、RTO/RPOを採録する。
- **期待結果**: 元hostを参照せず新規hostで受入試験に合格する。
- **失敗時**: 元データを変更せず、別世代、権限、version互換性を確認する。
- **合格条件**: 結果票、実測RTO/RPO、切り戻し、残課題、廃棄方法を引き渡せる。

> 別host復元は **NOT RUN**。同一環境への復元実績と混同しません。
