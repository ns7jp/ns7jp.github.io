# 共有フォルダ・アクセス権限管理手順書

社内の **ファイルサーバー / SharePoint / OneDrive 共有フォルダのアクセス権限**を、最小権限の原則に沿って付与・変更・削除・棚卸しするための標準手順書です。

---

## 📋 想定環境

| 項目 | 想定 |
|---|---|
| ファイルサーバー | Windows Server 2019/2022（共有 + NTFS 権限） |
| クラウド | SharePoint Online / OneDrive for Business |
| 認証 | Active Directory ドメイン |
| アクセス制御 | AD セキュリティグループ単位（個人ユーザー直付与は避ける） |
| 想定読者 | ヘルプデスク／社内SE／IT管理者 |

---

## 🎯 設計の基本原則

1. **最小権限の原則（PoLP）**: 業務に必要な最小限の権限のみ付与する
2. **グループ単位で管理**: ユーザー個人を ACL に直接書かない。AD グループに対して権限を付与する
3. **2 階層の権限分離**: 共有レベル（誰がパスを開けるか）と NTFS レベル（何ができるか）を分離する
4. **読み取りはデフォルト許可、書き込みは申請ベース**
5. **棚卸しは四半期ごと**: 異動・退職に伴う権限付け替え漏れを定期的に検出する

---

## 🗂 標準フォルダ構造例

```text
\\fileserver\corp\
├── 01_経営         (取締役・経営企画のみ)
├── 02_営業         (Sales-AllUsers)
│   ├── 01_顧客資料  (Sales-AllUsers / 一般読み取り、担当者書き込み)
│   ├── 02_受注      (Sales-AllUsers + Accounting-Read)
│   └── 99_引継ぎ    (Sales-Mgr のみ書き込み)
├── 03_開発         (Engineering-AllUsers)
├── 04_経理         (Accounting-AllUsers / 個人情報含むため強制 MFA)
├── 05_全社共有     (Domain Users)
└── 99_アーカイブ   (Read-Only / 5 年保存規程)
```

---

## 1️⃣ 新規部署フォルダ作成手順

### A. AD セキュリティグループの作成

部署 1 つにつき最低 3 つのグループを作成します。

| グループ名 | 用途 |
|---|---|
| `<部署名>-AllUsers` | 部署メンバー全員（読み書き） |
| `<部署名>-ReadOnly` | 関連部署など参照のみ |
| `<部署名>-Mgr` | 管理職限定（権限変更・引き継ぎ領域への書き込み） |

```powershell
# 例：マーケティング部の3グループ
"Marketing-AllUsers", "Marketing-ReadOnly", "Marketing-Mgr" | ForEach-Object {
    New-ADGroup -Name $_ -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=Corp,DC=corp,DC=local"
}
```

### B. 共有フォルダ作成

- [ ] 物理ディスクの空き容量と RAID 健全性を確認
- [ ] フォルダパスを決める（標準命名規則: `\\fileserver\corp\<番号>_<部署名>`）
- [ ] 共有を作成し、共有レベルは **Authenticated Users: Full Control**（NTFS で実質制御）
- [ ] NTFS 権限を設定（下表参照）
- [ ] 監査ログ（オブジェクトアクセス監査）を有効化

### C. NTFS 権限設定（推奨）

| プリンシパル | 権限 | 適用先 |
|---|---|---|
| SYSTEM | フルコントロール | このフォルダ・サブフォルダ・ファイル |
| Administrators | フルコントロール | 同上 |
| `<部署名>-Mgr` | 変更（Modify） | 同上 |
| `<部署名>-AllUsers` | 読み取り＋書き込み | 同上 |
| `<部署名>-ReadOnly` | 読み取り | 同上 |
| Creator Owner | フルコントロール | サブフォルダ・ファイルのみ |

> ⚠️ **継承の停止は最後の手段**: トップレベルで設定し、できるだけ継承で運用する。継承を止めると棚卸しが困難になる。

### D. 検証

- [ ] テストアカウント（部署メンバー）でアクセスし、書き込み・読み取りができること
- [ ] 別部署のテストアカウントでアクセスし、エラーになる（または見えない）こと
- [ ] イベントログ Security に `4663` (アクセス) が記録されること

---

## 2️⃣ ユーザー追加手順

新メンバー入社・部署異動時の標準フローです。

### 入力

- 対象ユーザー（SamAccountName）
- 配属部署 / 役割（一般 or 管理職）
- 例外的な権限要件（追加グループ）

### 手順

- [ ] AD ユーザーを `<部署名>-AllUsers` グループに追加
- [ ] 管理職の場合は `<部署名>-Mgr` も追加
- [ ] 関連部署への参照権限が必要なら `<関連部署>-ReadOnly` も追加
- [ ] 追加内容を申請チケットに記録（誰が・いつ・何のために）
- [ ] ユーザー本人にアクセス可能になった旨と該当パスを通知

```powershell
# 例：山田さんを営業部に追加
Add-ADGroupMember -Identity Sales-AllUsers -Members yamada.taro
```

> **承認ワークフロー推奨**: 申請者・部署長承認・IT 実施の 3 段階を残し、誰が許可したかを後から追えるようにする。

---

## 3️⃣ 部署異動時の権限付け替え

人事異動の処理は「**追加してから削除する**」順序で行うと、業務影響を最小化できます。

### 手順

- [ ] 異動先部署のグループに追加
- [ ] 業務引き継ぎが完了したことを当人・上長に確認（通常 1〜2 週間）
- [ ] 異動元部署のグループから削除
- [ ] 個人ユーザー直付与の権限が残っていないかチェック（下記スクリプト）

```powershell
# 個人ユーザー直接付与を検出
Get-Acl "\\fileserver\corp\02_営業" | Select-Object -ExpandProperty Access |
    Where-Object { $_.IdentityReference -like "CORP\*" -and $_.IdentityReference -notlike "*Group*" }
```

---

## 4️⃣ 退職時の権限削除

[退職者アカウント停止手順書](./account-offboarding-guide.md) と連動します。

- [ ] 全ての `<部署名>-*` グループから削除
- [ ] 個人専用フォルダがある場合、上長または後任者の OneDrive へ移管
- [ ] 共有 OneDrive リンク（"組織内の全員"設定など）を退職者本人が作成していないか確認
- [ ] 削除前に当該ユーザーが所有しているファイルの一覧をエクスポート

```powershell
# 退職者所有ファイル一覧を取得
Get-ChildItem "\\fileserver\corp\" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { (Get-Acl $_.FullName).Owner -eq "CORP\yamada.taro" } |
    Select-Object FullName, Length, LastWriteTime |
    Export-Csv "C:\offboarding\yamada-files.csv" -NoTypeInformation -Encoding UTF8
```

---

## 5️⃣ 四半期棚卸し（権限監査）

四半期ごとに以下を実施し、権限肥大化・退職者残存を防ぎます。

### A. グループメンバー一覧のスナップショット

```powershell
$departments = "Sales", "Marketing", "Engineering", "Accounting"
foreach ($d in $departments) {
    Get-ADGroupMember -Identity "$d-AllUsers" |
        Select-Object SamAccountName, Name, ObjectClass |
        Export-Csv "C:\audits\$d-members-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation -Encoding UTF8
}
```

### B. 部署長へ確認依頼

- [ ] 各部署長に CSV をメール送付
- [ ] 「異動済み・退職者・委託終了者がいないか」を確認
- [ ] 是正対象を返信してもらう（期限: 2 週間以内）

### C. 是正実施

- [ ] 報告された是正対象を削除
- [ ] 是正履歴を監査ログに保存

### D. 個人ユーザー直接 ACL の検出と是正

```powershell
# 共有のトップレベルで個人 ACL を検出
$paths = Get-ChildItem "\\fileserver\corp" -Directory
foreach ($p in $paths) {
    Get-Acl $p.FullName | Select-Object -ExpandProperty Access |
        Where-Object { $_.IdentityReference -like "CORP\[a-z]*" -and $_.IdentityReference -notlike "*-AllUsers" }
}
```

---

## ⚠️ よくある落とし穴

| 症状 | 原因 | 対策 |
|---|---|---|
| 異動先のフォルダにアクセスできない | グループ所属の更新がレプリケーション中（最大 8 時間） | サインアウト→再ログインで `gpupdate /force`、改善しなければ DC 確認 |
| 退職者の名前で作成されたファイルが残る | Creator Owner で個人付与されたまま | 棚卸しスクリプトで検出し、所有者をグループまたは管理者に変更 |
| 「全員」「Everyone」が ACL に残る | フォルダ作成時の既定設定を変更し忘れ | 標準テンプレート ACL を策定し、新規作成時に適用 |
| 個人ユーザーがフォルダ ACL に直接書かれる | 一時的な対応で個別追加した結果 | 棚卸し時に検出し、グループへ移行 |

---

## 🔗 関連リソース

- [退職者アカウント停止手順書](./account-offboarding-guide.md)
- [Microsoft 365 ライセンス管理手順書](./m365-license-management.md)
- [障害対応事例集 > 共有フォルダにアクセスできない](./troubleshooting-case-studies.md#8-共有フォルダにアクセスできない)
- [`Get-StaleUserAccounts.ps1`](../support-scripts/Get-StaleUserAccounts.ps1)

---

**注意**: 本書はサンプルです。実運用では自社のアクセス制御ポリシー・情報資産分類基準に従ってカスタマイズしてください。
