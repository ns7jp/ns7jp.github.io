# 退職者アカウント停止手順書

退職・異動者の **Active Directory / Microsoft 365 アカウント停止と関連リソース引き継ぎ**の標準手順書です。情報漏洩・不正アクセス・ライセンス無駄消費を防ぎ、引き継ぎ漏れを発生させないことを目的とします。

---

## 📋 想定環境

| 項目 | 想定 |
|---|---|
| 認証基盤 | Active Directory + Microsoft 365（同期環境） |
| メール | Exchange Online |
| ストレージ | OneDrive for Business / SharePoint Online |
| デバイス | Windows 11 Pro（Intune または GPO 管理） |
| 想定読者 | ヘルプデスク／社内SE／IT管理者 |
| 想定対象 | 退職者・グループ会社転籍者・長期休職者 |

---

## 🎯 ゴール

- 退職日 17:30（または最終勤務時刻）以降、本人による業務システムへのアクセスをすべて遮断する
- 業務メール・ファイル・チャットを後任者へ確実に引き継ぐ
- ライセンスを速やかに解放し、別ユーザーへ再割当できる状態にする
- 法令・社内規程で定める保管期限まで、対象データを安全に保持する

---

## ⏰ 全体タイムライン

| タイミング | 主担当 | 主なタスク |
|---|---|---|
| 退職決定〜最終日 1 週間前 | 人事＋IT | 通知受領、後任確定、データ移管計画 |
| 最終勤務日 当日 17:30 | IT | サインイン無効化、デバイス回収開始 |
| 翌営業日 | IT | メール自動応答、ファイル共有引き継ぎ |
| 退職後 30 日 | IT | ライセンス解放、メールボックス共有メールボックス化 |
| 退職後 90 日 | IT | アカウント完全削除（社内規程に従う） |

---

## 🧰 事前準備チェックリスト（最終日 1 週間前まで）

### 人事から取得する情報

- [ ] 退職者氏名（フルネーム）
- [ ] 部署・役職
- [ ] 最終勤務日 / 退職日（異なる場合あり）
- [ ] 後任者・引き継ぎ担当者の指名
- [ ] 退職事由カテゴリ（自己都合 / 会社都合 / 定年 / 転籍）
- [ ] アクセス遮断の即時性要件（通常 / 即時 / 段階的）

### 退職者本人と確認する事項

- [ ] 個人スマホへ業務メール転送設定の有無 → 解除依頼
- [ ] 個人ストレージへのファイル退避有無 → 削除依頼
- [ ] OneDrive 個人領域に共有設定された業務ファイル → 共有先確認

### 後任者・上長と確認する事項

- [ ] メールの自動応答文（例：「●●は退職しました。◆◆へご連絡ください」）
- [ ] OneDrive ファイルの引き継ぎ先（後任者 / チームサイト）
- [ ] 共有メールボックスの利用要否（顧客対応用アドレスの場合）
- [ ] Teams プライベートチャットの取り扱い（保存対象か）

---

## 1️⃣ 最終勤務日 17:30: 即時遮断作業

> ⚠️ **時系列で記録すること**: 各タスクの実行時刻と実行者を残す。後日、不正アクセス調査が発生した場合の証跡となる。

### A. Microsoft 365 / Azure AD

- [ ] サインインブロック（Azure AD ユーザー → サインインのブロック ON）
- [ ] パスワードリセット（推測不能な値に変更、本人へ通知しない）
- [ ] MFA セッション失効（`Revoke-MgUserSignInSession`）
- [ ] アクティブなセッション数を確認し、強制サインアウト

### B. Active Directory（オンプレ）

- [ ] AD ユーザーアカウントを **無効化**（削除はしない）
- [ ] 「Account Disabled - YYYYMMDD - 退職」を Description に追記
- [ ] 専用 OU「DisabledUsers」へ移動
- [ ] グループメンバーシップを CSV へエクスポートして削除（後で復元可能にする）

```powershell
# 例: グループ所属を退避してから外す
$user = Get-ADUser -Identity yamada.taro -Properties MemberOf
$user.MemberOf | Set-Content "C:\offboarding\yamada.taro_groups.txt"
$user.MemberOf | ForEach-Object { Remove-ADGroupMember -Identity $_ -Members $user -Confirm:$false }
Disable-ADAccount -Identity yamada.taro
```

### C. デバイス

- [ ] Intune / Endpoint Manager から該当デバイスを **Wipe** または **Retire** 指示
- [ ] デバイスが返却済みの場合、回収後に再キッティング前提で初期化
- [ ] BitLocker 回復キーが取得済みであることを確認

### D. 主要 SaaS / 業務システム

- [ ] Slack / Teams / Zoom / Salesforce / Box 等、社内利用サービスのアカウント無効化
- [ ] SSO 設定なら Azure AD 側で自動失効するが、ローカルアカウントは個別対応

---

## 2️⃣ 翌営業日: メール・ファイル引き継ぎ

### メール

- [ ] メールボックスを **共有メールボックスに変換**（30 日以内、ライセンス解放）
  ```powershell
  Set-Mailbox -Identity yamada.taro@corp.com -Type Shared
  ```
- [ ] 共有メールボックスへのアクセス権を後任者・上長に付与
- [ ] 自動応答（不在通知）を設定。例：
  > 山田太郎は●年●月●日をもって退職いたしました。お問い合わせは◆◆（mailto:saki@corp.com）までお願いいたします。
- [ ] 受信転送ルールを後任者宛に設定（必要に応じて 90 日間）

### OneDrive / SharePoint

- [ ] OneDrive のアクセス権を上長または後任者へ付与（30 日間維持後にアーカイブ）
- [ ] 退職者個人の OneDrive を後任者の OneDrive または共有 SharePoint サイトに **手動コピー**
- [ ] 個人領域のサイズが大きい場合は OneDrive 引き継ぎ機能を利用

### Teams

- [ ] 退職者が所有していたチームの **所有者を別メンバーに変更**
- [ ] プライベートチャネルがある場合、新所有者を追加
- [ ] チャット履歴は **退職者削除後も自動的にコンプライアンスホールドで保持される**（保管期限内）

---

## 3️⃣ 退職後 30 日: ライセンス解放

- [ ] 共有メールボックス化が完了していることを確認
- [ ] M365 ライセンスを解除（コスト削減）
  ```powershell
  Set-MgUserLicense -UserId yamada.taro@corp.com -RemoveLicenses @("...") -AddLicenses @()
  ```
- [ ] 解除した SKU 数を `Get-M365LicenseInventory.ps1` で再確認（[scripts/](../support-scripts/Get-M365LicenseInventory.ps1)）
- [ ] 物理デバイスの返却完了を資産管理台帳に記録
- [ ] OneDrive 上のファイルは後任者へ **完全移管済み** であることを確認

---

## 4️⃣ 退職後 90 日: アカウント完全削除

社内規程に従い保管期限を超えたアカウントを削除します。

- [ ] 法務・労務・コンプライアンス部門の最終確認を取得
- [ ] 共有メールボックスで保留中の事案がないか確認
- [ ] AD アカウントを **削除**
- [ ] Azure AD ユーザーを削除（30 日以内なら復元可能）
- [ ] 退職者アカウント停止記録を保管（監査証跡として最低 1 年）

---

## 📊 監査・棚卸し用クエリ

退職処理が漏れていないか、月次で確認します。

```powershell
# 90 日以上未ログインの有効アカウントを検出（退職処理漏れの可能性）
.\..\support-scripts\Get-StaleUserAccounts.ps1 -InactiveDaysThreshold 90 `
    -OutputPath .\stale-quarterly.csv

# ライセンスが割り当たっているのに無効化済みのアカウントを抽出
Get-MgUser -Filter "accountEnabled eq false" -Property AssignedLicenses, DisplayName |
    Where-Object { $_.AssignedLicenses.Count -gt 0 }
```

---

## ⚠️ よくある落とし穴

| 失敗例 | 原因 | 対策 |
|---|---|---|
| 退職翌日もメールが受信できる状態だった | サインインブロックのみで MFA セッションを失効していなかった | `Revoke-MgUserSignInSession` を必ず実行 |
| 後任者がファイルにアクセスできない | OneDrive 自動共有期限が切れていた | 30 日以内に手動コピー or 共有設定延長 |
| ライセンス解放を忘れて月額料金が継続発生 | 共有メールボックス化のみで満足し、ライセンス解除を失念 | チェックリスト最終項目で必ず確認 |
| 退職後にメンバーシップグループだけ残ったまま再雇用 | 復職時にグループ復元手順がなかった | グループ所属を CSV にエクスポートして退避 |

---

## 🔗 関連リソース

- [`Get-StaleUserAccounts.ps1`](../support-scripts/Get-StaleUserAccounts.ps1) — 棚卸し用 PowerShell
- [`Get-M365LicenseInventory.ps1`](../support-scripts/Get-M365LicenseInventory.ps1) — ライセンス棚卸し
- [PC キッティング手順書](./pc-kitting-guide.md) — 入社時手順（対になる）
- [障害対応事例集](./troubleshooting-case-studies.md) — パスワードロック・サインイン障害

---

**注意**: 本書はサンプルです。実運用では自社の就業規則・個人情報保護方針・電子帳簿保存法等の法令要件を踏まえてカスタマイズしてください。
