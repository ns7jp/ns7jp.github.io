# Microsoft 365 ライセンス管理手順書

Microsoft 365 ライセンスの **新規割当・変更・取消・棚卸し** の標準手順書です。コスト最適化・契約遵守・配布漏れ防止を目的とします。

---

## 📋 想定環境

| 項目 | 想定 |
|---|---|
| テナント | Microsoft 365 Business / Enterprise（E3 / E5 / Business Premium 等） |
| 認証 | Azure AD（Microsoft Entra ID） |
| 同期 | Azure AD Connect でオンプレ AD を同期 |
| 想定読者 | ヘルプデスク／社内SE／IT管理者 |
| 想定操作場所 | Microsoft 365 管理センター / Azure ポータル / PowerShell |

---

## 🎯 管理の基本方針

1. **グループベースライセンス（GBL）を優先する**: 個別割当は最小限。グループ所属で自動付与・自動解除する仕組みを使う
2. **割当ログを残す**: 誰が・いつ・どの SKU を・誰に割当てたか追跡可能にする
3. **月次棚卸し**: 利用率（Consumed / Purchased）と未使用ライセンスを定期確認する
4. **退職処理と連動**: 退職フローでライセンス解除を必ず実施する
5. **コスト最適化**: 利用率 < 50% の SKU は減数を検討、> 95% は増数または運用見直し

---

## 📦 SKU と用途のマッピング例

| SKU | 主な用途 | 配布対象例 |
|---|---|---|
| Microsoft 365 E3 | 一般従業員（フルセット） | 正社員 |
| Microsoft 365 F3 | 現場・製造ライン作業者 | パート・現場社員 |
| Exchange Online Plan 1 | メール送受信のみ | 業務委託・短期契約 |
| Power BI Pro | ダッシュボード閲覧者 | 経営企画・営業企画 |
| Visio / Project | 特定業務担当 | プロジェクトマネージャー等 |

> 自社の契約状況は `Get-MgSubscribedSku` で確認できます。

---

## 1️⃣ 新規ユーザーへのライセンス割当

### A. グループベースライセンス（推奨）

事前に Azure AD グループにライセンスを紐付けておけば、グループに追加するだけで自動付与されます。

- [ ] 該当グループ（例: `M365-E3-Users`）にユーザーを追加
- [ ] 5〜30 分以内にライセンスが反映される
- [ ] 反映後、ユーザーが Outlook / Teams / OneDrive にサインインできることを確認

```powershell
# AD グループにユーザー追加（同期で Azure AD にも反映）
Add-ADGroupMember -Identity M365-E3-Users -Members yamada.taro
```

### B. 個別割当（例外時のみ）

特殊な SKU や試用ユーザーへのみ使用します。

- [ ] 管理センター → ユーザー → ライセンスとアプリ → 該当 SKU をチェック
- [ ] 不要なサービス（例: Sway, Lists）はオフにできる（コスト同じだが認知度を下げられる）
- [ ] 30 日以内に GBL 化を検討

```powershell
# 個別割当の例（PowerShell）
$sku = Get-MgSubscribedSku | Where-Object SkuPartNumber -eq "ENTERPRISEPACK"
Set-MgUserLicense -UserId yamada.taro@corp.com `
    -AddLicenses @{SkuId=$sku.SkuId} -RemoveLicenses @()
```

---

## 2️⃣ ライセンス変更（昇格・降格・部署異動）

### 標準的な切替パターン

| Before | After | 例 |
|---|---|---|
| F3 → E3 | パート→正社員昇格 | グループを切替 |
| Exchange Plan 1 → E3 | 業務委託→正社員 | 同上 |
| E3 → E5 | 一般→管理職への昇格でセキュリティ強化が必要 | グループを切替 |

### 手順

- [ ] 異動元グループから削除
- [ ] 異動先グループに追加
- [ ] 30 分後に管理センターで反映を確認
- [ ] 必要なら追加 SKU（Visio など）を別途付与
- [ ] ユーザーへ「ライセンスが切り替わりました。一度サインアウト→サインインしてください」と通知

> ⚠️ ライセンス変更時に Outlook プロファイルが切れることがあります。事前にユーザー通知を行い、業務時間外（昼休み等）の実施を推奨。

---

## 3️⃣ ライセンス取り消し（退職時）

[退職者アカウント停止手順書](./account-offboarding-guide.md) と連動します。

### 段階的な取り消し

| タイミング | アクション |
|---|---|
| 最終日 当日 | サインインブロックのみ（ライセンスは保持） |
| 退職後 30 日 | メールボックスを共有メールボックスに変換、ライセンスを取り消し |
| 退職後 90 日 | アカウント完全削除 |

### 取り消しコマンド例

```powershell
# 全ライセンス解除
$user = Get-MgUser -UserId yamada.taro@corp.com -Property AssignedLicenses
$skuIds = $user.AssignedLicenses.SkuId
Set-MgUserLicense -UserId yamada.taro@corp.com `
    -AddLicenses @() -RemoveLicenses $skuIds
```

> 共有メールボックス変換前にライセンスを取り消すと、メールデータが 30 日後に削除されてしまう。**必ず先に Set-Mailbox -Type Shared を実行**すること。

---

## 4️⃣ 月次ライセンス棚卸し（コスト最適化）

毎月初に実施し、未使用ライセンスを解放します。

### A. 全社ライセンス使用状況のスナップショット

```powershell
.\..\support-scripts\Get-M365LicenseInventory.ps1 -OutputDir ".\m365-audit\$(Get-Date -Format 'yyyy-MM')"
```

出力される 3 ファイル:

- `user-license-assignments.csv` — ユーザー × ライセンス
- `sku-summary.csv` — SKU 毎の購入数 / 割当数 / 残数 / 利用率
- `by-department.csv` — 部署 × ライセンス利用人数

### B. 利用率に応じた判断基準

| 利用率 | 状態 | アクション |
|---|---|---|
| ≥ 95% | NearlyFull | 増数の検討、または利用見直し |
| 50% 〜 94% | Normal | 維持 |
| ≤ 50%（購入数 ≥ 10） | Underutilized | 減数を検討、契約更新時に調整 |

### C. 退職処理漏れの検出

```powershell
# サインイン無効なのにライセンスが残っているユーザー（退職処理漏れの可能性）
Get-MgUser -All -Filter "accountEnabled eq false" -Property AssignedLicenses, DisplayName |
    Where-Object { $_.AssignedLicenses.Count -gt 0 } |
    Select-Object DisplayName, UserPrincipalName, @{N='LicenseCount';E={$_.AssignedLicenses.Count}} |
    Export-Csv ".\m365-audit\disabled-with-licenses.csv" -NoTypeInformation -Encoding UTF8
```

### D. 部署長への確認

- [ ] `by-department.csv` を各部署長に共有
- [ ] 「異動済みなのに古い部署のライセンスが残っているメンバーはいないか」を確認
- [ ] 是正対象は一括変更グループへ移動

---

## 5️⃣ ライセンス追加購入の判断フロー

```text
利用率 ≥ 95% を 2 ヶ月連続検知
        ↓
未使用 SKU の有無を確認（5% 残っていれば棚卸し優先）
        ↓
直近 6 ヶ月の入退社推移を確認
        ↓
今後 3 ヶ月の採用予定を人事と確認
        ↓
増数案を稟議（リセラー経由 or M365 管理センター直接）
        ↓
購入後、グループ追加で自動配布
```

---

## ⚠️ よくある落とし穴

| 症状 | 原因 | 対策 |
|---|---|---|
| 「ライセンスがありません」エラー | GBL のグループへの追加が同期前 | 30 分待機、または管理センターで強制再評価 |
| Outlook がサインインできない | E3 → F3 へダウングレード時に Exchange Plan が含まれない可能性 | 切替前に SKU 内訳を確認 |
| メールが消えた | 共有メールボックス化前にライセンスを外した | 復元期間（30 日）内に再付与で復旧、以降は注意 |
| ライセンス重複付与 | グループベースと個別付与が両方有効 | 個別付与を解除（グループベースに統一） |
| 課金が増えている | 退職処理漏れ、または使われない高額 SKU | 月次棚卸し、`disabled-with-licenses.csv` を確認 |

---

## 📊 月次レポートのテンプレート

棚卸し結果を経営層・部署長に共有するためのテンプレートです。

```markdown
# Microsoft 365 ライセンス利用状況レポート（YYYY 年 MM 月）

## サマリー
- 総購入数: XXX
- 総割当数: XXX (XX%)
- 月額コスト概算: ¥XXX,XXX

## SKU 別利用状況
| SKU | 購入 | 割当 | 残数 | 利用率 | 状態 |
|---|---|---|---|---|---|
| Microsoft 365 E3 | XX | XX | X | XX% | Normal |
| ...

## 是正アクション
- 退職処理漏れの ライセンス解除: X 件
- Underutilized SKU の契約見直し提案: 1 件（次回更新時）

## 次月のフォーカス
- 採用予定 X 名分のライセンス確保
- F3 → E3 アップグレード需要の確認
```

---

## 🔗 関連リソース

- [`Get-M365LicenseInventory.ps1`](../support-scripts/Get-M365LicenseInventory.ps1) — 棚卸し PowerShell
- [退職者アカウント停止手順書](./account-offboarding-guide.md) — 退職時の連動処理
- [PC キッティング手順書](./pc-kitting-guide.md) — 入社時の連動処理
- [Microsoft 365 管理センター](https://admin.microsoft.com/)（リンク先 Microsoft）

---

**注意**: 本書はサンプルです。実運用では自社の契約形態（CSP / EA / MCA）、コンプライアンス要件、コスト管理方針を踏まえてカスタマイズしてください。
