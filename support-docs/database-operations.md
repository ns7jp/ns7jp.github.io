# データベース運用メモ (MySQL / PostgreSQL)

業務系で頻出する MySQL / PostgreSQL の **バックアップ・リストア・レプリケーション・チューニング** を、社内 100-500 名規模の DB を想定して整理します。「いざという時に手が止まらない」 ことを目的に、コマンドと判断基準をセットで残します。

> 監視は `monitoring-stack/` の Prometheus + `mysqld_exporter` / `postgres_exporter` を使う前提です。

---

## 1. バックアップ戦略

### 1.1 3-2-1 ルール

- **3 つのコピー**: 本番 + ローカルバックアップ + オフサイト
- **2 つの媒体**: ディスク + オブジェクトストレージ (S3 / Blob)
- **1 つは隔離**: WORM / Immutable / Air-gapped

### 1.2 RPO / RTO の目安

| サービス層 | RPO | RTO | 実装 |
|---|---|---|---|
| 業務クリティカル (会計, 受発注) | 15 分 | 1 時間 | binlog + 毎時 snapshot |
| 業務系 (CRM, 勤怠) | 1 時間 | 4 時間 | 1h logical backup + 日次 snapshot |
| 補助系 (ナレッジ DB) | 24 時間 | 1 営業日 | 日次 dump のみ |

---

## 2. MySQL バックアップ・リストア

### 2.1 論理バックアップ (`mysqldump` / `mydumper`)

```bash
# 単一ホスト・小規模: mysqldump で十分
mysqldump --single-transaction --routines --triggers --events \
    --master-data=2 --hex-blob \
    --databases app_prod \
    | gzip > /backup/app_prod.$(date +%Y%m%d_%H%M).sql.gz

# 大規模 (>50GB): mydumper で並列化 (4-8 並列で 5-10 倍高速)
mydumper --threads 8 --compress --rows 500000 \
    --triggers --events --routines \
    --outputdir /backup/$(date +%Y%m%d_%H%M) \
    --database app_prod
```

**`--single-transaction` が必須な理由**: InnoDB の MVCC を利用して、テーブルロックなしに一貫性のあるスナップショットを取る。MyISAM テーブルがあると一貫性は保証されないので注意。

### 2.2 物理バックアップ (`xtrabackup`)

```bash
# Percona XtraBackup: 数 TB クラスの InnoDB を停止せずバックアップ
xtrabackup --backup --target-dir=/backup/full_$(date +%Y%m%d) \
    --user=backup --password=*** --parallel=4

# Prepare (リストア前の必須処理)
xtrabackup --prepare --target-dir=/backup/full_20260518

# リストア (mysqld 停止状態で)
xtrabackup --copy-back --target-dir=/backup/full_20260518
chown -R mysql:mysql /var/lib/mysql
```

### 2.3 Point-in-Time Recovery (PITR)

binlog があれば任意時刻に戻せます。誤 UPDATE / DROP の救済策。

```bash
# 1. 最後のフルバックアップをリストア (上の手順)

# 2. binlog から特定時刻までを適用
mysqlbinlog --start-datetime="2026-05-18 09:00:00" \
            --stop-datetime="2026-05-18 14:25:00" \
            /var/lib/mysql/mysql-bin.000123 \
            /var/lib/mysql/mysql-bin.000124 \
    | mysql -u root -p

# 誤 DROP の直前で止めるなら --stop-position=<binlog position>
mysqlbinlog --stop-position=4567890 ... | mysql -u root -p
```

---

## 3. PostgreSQL バックアップ・リストア

### 3.1 論理バックアップ (`pg_dump` / `pg_dumpall`)

```bash
# 個別 DB (custom format 推奨: 並列リストア可、選択リストア可)
pg_dump -Fc -j 4 -f /backup/app_prod.$(date +%Y%m%d).dump app_prod

# 全体 (ロール / tablespace 含む)
pg_dumpall --globals-only > /backup/globals.$(date +%Y%m%d).sql

# リストア
pg_restore -d app_prod -j 4 --clean --if-exists /backup/app_prod.20260518.dump
```

### 3.2 物理 + PITR (`pg_basebackup` + WAL archiving)

```bash
# postgresql.conf:
#   wal_level = replica
#   archive_mode = on
#   archive_command = 'test ! -f /archive/%f && cp %p /archive/%f'

# 1. ベースバックアップ
pg_basebackup -D /backup/base_$(date +%Y%m%d) -Ft -z -P -X stream

# 2. PITR: recovery.conf (PG12+ は postgresql.auto.conf + recovery.signal)
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2026-05-18 14:25:00 JST'
recovery_target_action = 'promote'
```

---

## 4. レプリケーション

### 4.1 MySQL 非同期レプリケーション (Source/Replica)

```sql
-- Source 側
CREATE USER 'repl'@'10.0.20.%' IDENTIFIED WITH caching_sha2_password BY '***';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'10.0.20.%';

-- バイナリログとサーバーIDを設定 (my.cnf)
-- [mysqld]
-- server-id = 1
-- log-bin = mysql-bin
-- binlog-format = ROW
-- gtid-mode = ON
-- enforce-gtid-consistency = ON

-- Replica 側
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='10.0.20.10',
    SOURCE_USER='repl',
    SOURCE_PASSWORD='***',
    SOURCE_AUTO_POSITION=1;
START REPLICA;
SHOW REPLICA STATUS\G   -- Seconds_Behind_Source を監視対象に
```

**監視ポイント**:
- `Seconds_Behind_Source` > 60 でアラート (Loki / Prometheus)
- `Replica_IO_Running` / `Replica_SQL_Running` が `Yes` でない場合 critical
- `Last_Error` を Slack 通知

### 4.2 PostgreSQL Streaming Replication

```bash
# Primary の postgresql.conf
wal_level = replica
max_wal_senders = 10
hot_standby = on

# Primary の pg_hba.conf
host replication replicator 10.0.20.0/24 scram-sha-256

# Standby 構築
pg_basebackup -h 10.0.20.10 -D /var/lib/postgresql/data \
    -U replicator -P -R --wal-method=stream
# -R で standby.signal と primary_conninfo を自動生成
```

---

## 5. パフォーマンスチューニング

### 5.1 まず見るべき箇所 (MySQL)

```sql
-- 1. スロークエリ (slow_query_log を ON にしておく)
SELECT * FROM mysql.slow_log ORDER BY query_time DESC LIMIT 20;
-- or pt-query-digest /var/log/mysql/slow.log

-- 2. 現在実行中の重いクエリ
SELECT id, user, host, db, time, state, LEFT(info, 200) AS query
  FROM information_schema.processlist
 WHERE command != 'Sleep' AND time > 5
 ORDER BY time DESC;

-- 3. インデックス未使用のテーブル
SELECT object_schema, object_name, count_read
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NULL AND count_read > 0
 ORDER BY count_read DESC LIMIT 20;

-- 4. innodb_buffer_pool ヒット率 (99% 以上を維持)
SELECT
  (1 - (
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads')
    /
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests')
  )) * 100 AS hit_rate_percent;
```

### 5.2 PostgreSQL

```sql
-- スロークエリ (pg_stat_statements が必要)
SELECT query, calls, mean_exec_time, total_exec_time
  FROM pg_stat_statements
 ORDER BY total_exec_time DESC LIMIT 20;

-- インデックスサイズと使用回数
SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read
  FROM pg_stat_user_indexes
 WHERE idx_scan = 0 AND schemaname NOT IN ('pg_catalog', 'information_schema');
-- → idx_scan = 0 のインデックスは削除候補

-- VACUUM 状況
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup::numeric / NULLIF(n_live_tup, 0), 3) AS dead_ratio,
       last_vacuum, last_autovacuum
  FROM pg_stat_user_tables
 ORDER BY dead_ratio DESC NULLS LAST LIMIT 20;
```

### 5.3 主要パラメータの目安 (RAM 16GB の DB 専用ホスト)

| パラメータ | MySQL (InnoDB) | PostgreSQL | 目安 |
|---|---|---|---|
| バッファ | `innodb_buffer_pool_size = 12G` | `shared_buffers = 4GB` | 物理 RAM の 25-75% |
| ログ | `innodb_log_file_size = 1G` | `wal_buffers = 16MB` | 書き込み量に応じる |
| 同時接続 | `max_connections = 200` | `max_connections = 200` | アプリ側プーリング前提 |
| 一時 | `tmp_table_size = 64M` | `work_mem = 16MB` | 接続数 × work_mem に注意 |

---

## 6. 障害対応ランブック

### 6.1 レプリ遅延が増えている

1. `SHOW REPLICA STATUS\G` で `Seconds_Behind_Source` 確認
2. Replica 側の I/O wait (`iostat -x 1`) → ディスク律速か
3. Source 側のロングトランザクション (`SHOW ENGINE INNODB STATUS\G`)
4. ネットワーク帯域 (`iftop`, `nethogs`)
5. それでも追いつかなければ並列レプリ (`replica_parallel_workers`) を有効化

### 6.2 ディスク 95% 到達

1. `du -sh /var/lib/mysql/* | sort -h | tail` で巨大テーブル特定
2. `binlog` の蓄積なら `PURGE BINARY LOGS BEFORE 'YYYY-MM-DD'` で削除 (バックアップ取得後)
3. `general_log` / `slow_log` がオンのままなら off
4. テーブル単位の `OPTIMIZE TABLE` (オフライン作業窓が必要)

### 6.3 誤 UPDATE / DELETE

1. **絶対に何もしない**。書き込みを止める (アプリを read-only に)
2. binlog から「実行された SQL」を確認: `mysqlbinlog --start-datetime=... --base64-output=DECODE-ROWS -v`
3. リストア戦略を決定: フル + binlog で PITR が基本
4. 部分復旧なら別 DB に PITR → 該当テーブルだけ `INSERT ... SELECT`

---

## 7. 関連

- [`monitoring-stack/`](../monitoring-stack/) — Prometheus exporters の追加先
- [`support-docs/backup-restore-runbook.md`](backup-restore-runbook.md) — OS / ファイルサーバー側のバックアップ
- [`support-docs/incident-response-playbook.md`](incident-response-playbook.md) — 重大インシデント時の連絡フロー
