<#
.SYNOPSIS
    SQL Server / Azure SQL データベースの一次ヘルスチェック（読み取り中心）。

.DESCRIPTION
    社内 SE / 情シス補助で問い合わせを受ける小規模なデータベース（業務 SQL Server、
    Microsoft Access の SQL バックエンド、Azure SQL など）について、状態確認・スロークエリ抽出・
    最終バックアップ確認をワンライナーで取得するためのサンプルです。

    既定では SQL Server 認証情報を要求せず、Integrated Security (Windows 認証) で接続します。
    削除・更新・設定変更は行いません。読み取りクエリのみです。

    必要モジュール:
        SqlServer モジュール (Install-Module -Name SqlServer -Scope CurrentUser)

.PARAMETER ServerInstance
    SQL Server インスタンス名。例: 'sqldb01' / 'sqldb01\SQLEXPRESS' / 'mydb.database.windows.net'

.PARAMETER Database
    対象データベース名。省略時は master を使用してサーバー全体を確認。

.PARAMETER OutputPath
    結果出力先 JSON のパス。省略時は ./db-health-yyyyMMdd-HHmmss.json

.PARAMETER SlowQueryTopN
    スロークエリ抽出件数。既定 10。

.EXAMPLE
    .\Test-DatabaseHealth.ps1 -ServerInstance 'sqldb01'
    # サーバー全体のヘルスと TOP 10 スロークエリを JSON 出力

.EXAMPLE
    .\Test-DatabaseHealth.ps1 -ServerInstance 'sqldb01' -Database 'CoreApp' -SlowQueryTopN 20

.NOTES
    Author: Noriyuki Shimada
    Lab/Portfolio sample. 本番 DB に対して実行する場合は、業務時間外 / 読み取り権限のみの
    アカウント / コネクションタイムアウト短縮を必ず確認してください。
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ServerInstance,

    [string]$Database = 'master',

    [string]$OutputPath = (".\db-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"),

    [int]$SlowQueryTopN = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name SqlServer)) {
    throw "SqlServer モジュールが見つかりません。Install-Module -Name SqlServer -Scope CurrentUser を実行してください。"
}

Import-Module SqlServer

function Invoke-Query {
    param(
        [string]$Server,
        [string]$Db,
        [string]$Query,
        [int]$TimeoutSec = 15
    )
    try {
        Invoke-Sqlcmd -ServerInstance $Server `
                      -Database $Db `
                      -Query $Query `
                      -QueryTimeout $TimeoutSec `
                      -TrustServerCertificate `
                      -ErrorAction Stop
    }
    catch {
        return @{ Error = $_.Exception.Message }
    }
}

Write-Host "===== Test-DatabaseHealth.ps1 =====" -ForegroundColor Cyan
Write-Host "Server   : $ServerInstance"
Write-Host "Database : $Database"
Write-Host "Output   : $OutputPath"
Write-Host

$result = [ordered]@{
    timestamp        = (Get-Date).ToString('o')
    server           = $ServerInstance
    database         = $Database
    serverInfo       = $null
    databaseList     = @()
    backupStatus     = @()
    waitStats        = @()
    slowQueries      = @()
    blockingSessions = @()
    diskSpace        = @()
    connectivity     = 'ok'
}

# 1) サーバー情報
$infoSql = @"
SELECT
  @@SERVERNAME           AS ServerName,
  @@VERSION              AS Version,
  SERVERPROPERTY('Edition')           AS Edition,
  SERVERPROPERTY('ProductLevel')      AS ProductLevel,
  SERVERPROPERTY('Collation')         AS Collation,
  GETDATE()              AS CurrentTime;
"@
$info = Invoke-Query -Server $ServerInstance -Db 'master' -Query $infoSql
if ($info -is [hashtable] -and $info.ContainsKey('Error')) {
    $result.connectivity = 'failed'
    $result.serverInfo   = $info
    $result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
    throw "Server connectivity failed: $($info.Error)"
}
$result.serverInfo = $info

# 2) データベース一覧（状態 / 復旧モデル / 最終バックアップ）
$dbListSql = @"
SELECT
  d.name                            AS DatabaseName,
  d.state_desc                      AS State,
  d.recovery_model_desc             AS RecoveryModel,
  d.compatibility_level             AS CompatLevel,
  ISNULL(b.LastFullBackup,   'never')  AS LastFullBackup,
  ISNULL(b.LastDiffBackup,   'never')  AS LastDiffBackup,
  ISNULL(b.LastLogBackup,    'never')  AS LastLogBackup
FROM sys.databases d
LEFT JOIN (
  SELECT
    database_name,
    MAX(CASE WHEN type = 'D' THEN backup_finish_date END) AS LastFullBackup,
    MAX(CASE WHEN type = 'I' THEN backup_finish_date END) AS LastDiffBackup,
    MAX(CASE WHEN type = 'L' THEN backup_finish_date END) AS LastLogBackup
  FROM msdb.dbo.backupset
  GROUP BY database_name
) b ON b.database_name = d.name
WHERE d.database_id > 4  -- ユーザー DB のみ (system 除外)
ORDER BY d.name;
"@
$result.databaseList = Invoke-Query -Server $ServerInstance -Db 'master' -Query $dbListSql

# 3) Wait Stats (上位)
$waitSql = @"
SELECT TOP 10
  wait_type,
  waiting_tasks_count,
  wait_time_ms,
  signal_wait_time_ms,
  max_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
  'CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK',
  'WAITFOR','HADR_FILESTREAM_IOMGR_IOCOMPLETION','CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH',
  'XE_TIMER_EVENT','XE_DISPATCHER_WAIT','BROKER_TO_FLUSH','BROKER_TASK_STOP','BROKER_EVENTHANDLER',
  'TRACEWRITE','FT_IFTSHC_MUTEX','SQLTRACE_INCREMENTAL_FLUSH_SLEEP','DIRTY_PAGE_POLL'
)
ORDER BY wait_time_ms DESC;
"@
$result.waitStats = Invoke-Query -Server $ServerInstance -Db 'master' -Query $waitSql

# 4) スロークエリ (top N)
$slowSql = @"
SELECT TOP $SlowQueryTopN
  qs.total_elapsed_time / 1000      AS TotalElapsedMs,
  qs.execution_count                AS ExecCount,
  qs.total_elapsed_time / NULLIF(qs.execution_count,0) / 1000 AS AvgElapsedMs,
  qs.total_worker_time / 1000       AS TotalCpuMs,
  qs.total_logical_reads            AS LogicalReads,
  SUBSTRING(st.text,
            (qs.statement_start_offset / 2) + 1,
            ((CASE qs.statement_end_offset
                  WHEN -1 THEN DATALENGTH(st.text)
                  ELSE qs.statement_end_offset END
              - qs.statement_start_offset) / 2) + 1) AS QueryText
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE qs.execution_count > 1
ORDER BY qs.total_elapsed_time DESC;
"@
$result.slowQueries = Invoke-Query -Server $ServerInstance -Db 'master' -Query $slowSql

# 5) ブロッキングセッション
$blockingSql = @"
SELECT
  s.session_id,
  s.login_name,
  s.host_name,
  s.program_name,
  r.blocking_session_id,
  r.wait_type,
  r.wait_time / 1000 AS WaitSec,
  r.command,
  r.status,
  st.text AS QueryText
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.blocking_session_id <> 0;
"@
$result.blockingSessions = Invoke-Query -Server $ServerInstance -Db 'master' -Query $blockingSql

# 6) ディスク空き容量
$diskSql = @"
SELECT DISTINCT
  vs.volume_mount_point,
  vs.logical_volume_name,
  CAST(vs.total_bytes  / 1024.0 / 1024 / 1024 AS DECIMAL(10,2)) AS TotalGB,
  CAST(vs.available_bytes / 1024.0 / 1024 / 1024 AS DECIMAL(10,2)) AS AvailableGB,
  CAST(100.0 * vs.available_bytes / NULLIF(vs.total_bytes,0) AS DECIMAL(5,2)) AS PercentFree
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs;
"@
$result.diskSpace = Invoke-Query -Server $ServerInstance -Db 'master' -Query $diskSql

# 7) JSON 出力
$result | ConvertTo-Json -Depth 12 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Saved: $OutputPath" -ForegroundColor Green

# 8) サマリー (チケット添付用)
Write-Host
Write-Host "===== サマリー（チケット添付用） =====" -ForegroundColor Cyan
Write-Host ("接続性          : " + $result.connectivity)
Write-Host ("DB 数 (ユーザー): " + (($result.databaseList | Measure-Object).Count))
Write-Host ("ブロッキング    : " + (($result.blockingSessions | Measure-Object).Count) + " セッション")
Write-Host ("スロークエリ    : 上位 $SlowQueryTopN 件を JSON に記録")

# バックアップ警告 (24h 以内に Full が無い DB)
$cutoff = (Get-Date).AddHours(-24)
$stale  = $result.databaseList | Where-Object {
    $_.LastFullBackup -ne 'never' -and
    [datetime]$_.LastFullBackup -lt $cutoff
}
if ($stale) {
    Write-Host
    Write-Host "[警告] 24h 以内に Full バックアップが取れていない DB:" -ForegroundColor Yellow
    $stale | ForEach-Object { Write-Host (" - " + $_.DatabaseName + " (" + $_.LastFullBackup + ")") }
}
