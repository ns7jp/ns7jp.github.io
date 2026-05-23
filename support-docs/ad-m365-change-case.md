# AD / Microsoft 365 変更作業ケース: 部署異動に伴う権限変更

> このドキュメントは公開ポートフォリオ用の架空ケースです。実在のユーザー、部署、テナント、共有フォルダ、承認フローは含みません。

ITサポート・社内SE補助でよく発生する「部署異動に伴う AD / Microsoft 365 / 共有フォルダ権限の変更」を、**変更申請 → 事前確認 → 作業 → 検証 → 証跡保存 → クローズ** の流れでまとめた実務寄りのサンプルです。

---

## 1. 変更概要

| 項目 | 内容 |
|---|---|
| 変更ID | CHG-2026-0520-AD-M365-001 |
| 種別 | 権限変更 / ライセンス見直し / 共有フォルダアクセス変更 |
| 対象 | `sample.user@corp.example` |
| 変更理由 | 2026-06-01 付で営業部から情報システム部へ異動 |
| 承認者 | 営業部長、情報システム部長、人事担当 |
| 作業予定 | 2026-05-31 18:30 - 19:00 JST |
| 影響 | 旧部署共有フォルダの編集権限を削除、新部署共有フォルダへ読み書き権限付与 |
| ロールバック | 変更前グループ一覧を保存し、旧グループへ戻す |

---

## 2. 事前確認

### 2.1 申請内容

- [ ] 異動日が人事台帳と一致している
- [ ] 旧部署 / 新部署の承認者がそろっている
- [ ] 付与・削除するグループ名が明記されている
- [ ] ライセンス変更の有無が記載されている
- [ ] 共有フォルダの所有者が確認済み

### 2.2 変更前証跡

PowerShell 例:

```powershell
$User = "sample.user"
$EvidenceDir = ".\evidence\CHG-2026-0520-AD-M365-001"
New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null

Get-ADUser $User -Properties Department,Title,MemberOf |
    Select-Object SamAccountName,Department,Title,MemberOf |
    ConvertTo-Json -Depth 5 |
    Set-Content "$EvidenceDir\before-ad-user.json" -Encoding UTF8

Get-ADPrincipalGroupMembership $User |
    Select-Object Name,SamAccountName,GroupCategory,GroupScope |
    Sort-Object Name |
    Export-Csv "$EvidenceDir\before-ad-groups.csv" -NoTypeInformation -Encoding UTF8
```

Microsoft 365 例:

```powershell
Connect-MgGraph -Scopes User.Read.All,Directory.Read.All,Organization.Read.All

Get-MgUser -UserId "sample.user@corp.example" -Property Id,DisplayName,UserPrincipalName,AssignedLicenses |
    Select-Object Id,DisplayName,UserPrincipalName,AssignedLicenses |
    ConvertTo-Json -Depth 5 |
    Set-Content "$EvidenceDir\before-m365-user.json" -Encoding UTF8
```

---

## 3. 作業手順

### 3.1 AD 属性更新

```powershell
Set-ADUser sample.user `
    -Department "Information Systems" `
    -Title "IT Support Assistant"
```

### 3.2 旧部署グループの削除

```powershell
Remove-ADGroupMember -Identity "GG-Sales-Share-Modify" `
    -Members sample.user `
    -Confirm:$false
```

### 3.3 新部署グループの追加

```powershell
Add-ADGroupMember -Identity "GG-IT-Share-Modify" `
    -Members sample.user
```

### 3.4 M365 ライセンス確認

```powershell
.\Get-M365LicenseInventory.ps1 -OutputDir "$EvidenceDir\m365-license-after"
```

ライセンス変更が必要な場合は、グループベースライセンスの対象グループに追加し、直接割当を避けます。

---

## 4. 検証

| 確認対象 | コマンド / 画面 | OK条件 |
|---|---|---|
| AD 属性 | `Get-ADUser sample.user -Properties Department,Title` | 新部署・役職に更新済み |
| AD グループ | `Get-ADPrincipalGroupMembership sample.user` | 旧部署グループなし / 新部署グループあり |
| 共有フォルダ | テスト端末でアクセス確認 | 旧部署は権限なし、新部署は読み書き可能 |
| M365 | 管理センター / Graph PowerShell | 必要ライセンスが有効 |
| サインイン影響 | ユーザー確認 | Outlook / Teams / OneDrive に業務影響なし |

検証後証跡:

```powershell
Get-ADPrincipalGroupMembership sample.user |
    Select-Object Name,SamAccountName,GroupCategory,GroupScope |
    Sort-Object Name |
    Export-Csv "$EvidenceDir\after-ad-groups.csv" -NoTypeInformation -Encoding UTF8
```

---

## 5. ロールバック

問題が起きた場合は、`before-ad-groups.csv` をもとに旧グループへ戻します。

```powershell
Add-ADGroupMember -Identity "GG-Sales-Share-Modify" -Members sample.user
Remove-ADGroupMember -Identity "GG-IT-Share-Modify" -Members sample.user -Confirm:$false
```

ロールバック後も、共有フォルダアクセスと M365 サインイン影響を再確認します。

---

## 6. チケット記録テンプレート

```text
変更ID:
対象ユーザー:
作業日時:
作業者:
承認:
変更前グループ:
変更後グループ:
M365ライセンス変更:
検証結果:
利用者確認:
添付証跡:
ロールバック要否:
残課題:
```

---

## 7. エスカレーション基準

- 承認者が不足している
- 削除対象グループの業務影響が不明
- 共有フォルダ所有者が不明
- M365 ライセンス変更が契約数上限に影響する
- 条件付きアクセスや Intune 準拠状態に影響する
- ユーザーが異動日当日に業務停止している

---

## 関連

- [退職者アカウント停止手順書](./account-offboarding-guide.md)
- [共有フォルダ・アクセス権限管理手順書](./shared-folder-access-management.md)
- [Microsoft 365 ライセンス管理手順書](./m365-license-management.md)
- [Infra Lab](../infra-lab.html)
- [support-scripts](../support-scripts/)
