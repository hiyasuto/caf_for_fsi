# FISC準拠 Azure ガバナンスベースライン

## 概要

本リポジトリは、**FISC安全対策基準（第13版）**に準拠した Azure ガバナンスベースラインの IaC（Infrastructure as Code）テンプレートです。日本の金融機関が Azure クラウドを安全に利用するための基盤を提供します。

### ガバナンスベースが提供する機能

| コンポーネント | 説明 | 対応するFISC基準 |
|---|---|---|
| 管理グループ階層 | 金融機関向けのリソース管理階層 | 統20, 統21 |
| Azure Policy | セキュリティ・コンプライアンスポリシーの自動適用 | 実1, 実7, 実13, 実25, 実39, 実150, 統20 |
| Microsoft Defender for Cloud | 脅威検知・セキュリティ態勢管理 | 実7, 実14, 実25, 統20 |
| Log Analytics | 中央ログ管理基盤（730日保持） | 実25, 実26 |
| 診断設定 | アクティビティログ転送・WORM アーカイブ | 実25, 実26 |

## 管理グループ階層

```
Tenant Root Group
└── fsi-root (金融機関ルート)
    ├── fsi-platform (プラットフォーム)
    │   ├── fsi-connectivity (ネットワーク)
    │   ├── fsi-identity (ID管理)
    │   └── fsi-management (管理)
    ├── fsi-workloads (ワークロード)
    │   ├── fsi-tier1 (Tier1: 勘定系・決済系)
    │   ├── fsi-tier2 (Tier2: チャネル系・情報系)
    │   └── fsi-tier3 (Tier3: 開発・検証)
    └── fsi-sandbox (サンドボックス)
```

### 階層設計の考え方

- **Tier1（勘定系・決済系）**: 最も厳格なポリシーを適用。本番環境の基幹系システム
- **Tier2（チャネル系・情報系）**: インターネットバンキング等のチャネル系、情報系システム
- **Tier3（開発・検証）**: 開発・テスト環境。本番データの利用を制限
- **サンドボックス**: 技術検証用。本番とは完全に分離

## 前提条件

### 必要なツール

| ツール | バージョン | 用途 |
|---|---|---|
| Azure CLI | 2.60 以上 | Azure リソースの管理 |
| Bicep CLI | 0.28 以上 | テンプレートのビルド・デプロイ |

### 必要な権限

- **テナントルートグループ**に対する `Owner` または `Management Group Contributor` ロール
- **管理用サブスクリプション**に対する `Owner` ロール
- Azure AD の `Global Administrator` または `Security Administrator` ロール（Defender for Cloud の構成に必要）

### Azure CLI のインストールとサインイン

```bash
# Azure CLI のインストール（Windows）
winget install Microsoft.AzureCLI

# サインイン
az login

# テナントIDの確認
az account show --query tenantId -o tsv

# 管理グループ操作の権限昇格（テナントルートへのアクセスが必要な場合）
az rest --method post --url "https://management.azure.com/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
```

## デプロイ手順

### 1. パラメータファイルの編集

`parameters/production.bicepparam` を環境に合わせて編集します。

```bash
# 必ず以下の値を設定してください
# - tenantRootGroupId: テナントルートグループのID
# - managementSubscriptionId: 管理用サブスクリプションのID
# - securityContactEmail: セキュリティ連絡先メールアドレス
# - securityContactPhone: セキュリティ連絡先電話番号
# - archiveStorageAccountName: 監査ログアーカイブ用ストレージアカウント名
```

テナントルートグループIDの確認:

```bash
az account management-group list --query "[?displayName=='Tenant Root Group'].name" -o tsv
```

### 2. テンプレートの検証

デプロイ前にテンプレートの検証を実行します。

```bash
# Bicep のビルド確認
az bicep build --file main.bicep

# What-if（デプロイのプレビュー）
az deployment mg create \
  --management-group-id <テナントルートグループID> \
  --location japaneast \
  --template-file main.bicep \
  --parameters parameters/production.bicepparam \
  --what-if
```

### 3. デプロイの実行

```bash
# 管理グループスコープでデプロイ
az deployment mg create \
  --management-group-id <テナントルートグループID> \
  --location japaneast \
  --name "fisc-governance-baseline-$(date +%Y%m%d%H%M%S)" \
  --template-file main.bicep \
  --parameters parameters/production.bicepparam
```

### 4. デプロイ後の確認

#### 管理グループ階層の確認

```bash
az account management-group list --query "[?starts_with(name, 'fsi-')]" -o table
```

#### ポリシー割り当ての確認

```bash
# ルート管理グループに割り当てられたポリシーの一覧
az policy assignment list \
  --scope "/providers/Microsoft.Management/managementGroups/fsi-root" \
  -o table
```

#### Defender for Cloud の確認

```bash
# 有効なプランの確認
az security pricing list -o table
```

#### Log Analytics ワークスペースの確認

```bash
# ワークスペースの設定確認
az monitor log-analytics workspace show \
  --resource-group rg-fsi-management-prod \
  --workspace-name law-fsi-central-prod \
  -o table
```

#### 診断設定の確認

```bash
# サブスクリプションレベルの診断設定
az monitor diagnostic-settings subscription list -o table
```

## FISC安全対策基準 対応マッピング

### 実務基準（実）

| FISC基準 | 基準名 | 本テンプレートでの対応 |
|---|---|---|
| 実1 | アクセス制御 | MCSB によるMFA要求、RBAC 適用 |
| 実7 | ネットワークセキュリティ | NSG強制、ストレージネットワーク制限、Private Link |
| 実13 | 暗号化 | CMK暗号化、SQL TDE、ストレージ暗号化 |
| 実14 | 不正プログラム対策 | Defender for Servers/Containers/Storage |
| 実25 | ログ管理 | Log Analytics（730日保持）、アクティビティログ転送 |
| 実26 | ログ改竄防止 | WORM ストレージ（イミュータブルBlob） |
| 実39 | バックアップ | Azure Backup ポリシー強制 |
| 実150 | AIガバナンス | Azure AI サービスのネットワーク制限 |

### 統制基準（統）

| FISC基準 | 基準名 | 本テンプレートでの対応 |
|---|---|---|
| 統20 | クラウドガバナンス | 管理グループ階層、許可リージョン制限、MCSB |
| 統21 | クラウド管理体制 | 管理グループによる責任分離 |

## ファイル構成

```
governance/
├── README.md                          # 本ドキュメント
├── main.bicep                         # メインオーケストレーション
├── bicepconfig.json                   # Bicep リンター設定
├── modules/
│   ├── management-groups.bicep        # 管理グループ階層
│   ├── policy-assignments.bicep       # Azure Policy 割り当て
│   ├── defender.bicep                 # Microsoft Defender for Cloud
│   ├── log-analytics.bicep            # 中央 Log Analytics
│   ├── diagnostics.bicep              # 診断設定・監査アーカイブ
│   └── resource-group.bicep           # リソースグループ（ヘルパー）
└── parameters/
    └── production.bicepparam          # 本番環境パラメータ
```

## 注意事項

- 本テンプレートは**管理グループスコープ**でデプロイされます。十分な権限を持つアカウントで実行してください
- パラメータファイル内のプレースホルダー（`<...>`）を必ず実際の値に置き換えてください
- 初回デプロイ時は管理グループの作成に数分かかる場合があります
- Defender for Cloud のプラン有効化は、対象サブスクリプションごとに実行する必要があります
- ストレージアカウントのイミュータビリティポリシーは、一度ロックすると解除できません。検証環境で十分にテストしてから本番に適用してください

## 参考資料

- [FISC安全対策基準（第13版）](https://www.fisc.or.jp/)
- [Microsoft Cloud Adoption Framework for Azure](https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/)
- [Azure ランディングゾーン](https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/landing-zone/)
- [Microsoft Cloud Security Benchmark](https://learn.microsoft.com/ja-jp/security/benchmark/azure/overview)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/ja-jp/azure/defender-for-cloud/)
- [Azure Policy 組み込み定義](https://learn.microsoft.com/ja-jp/azure/governance/policy/samples/built-in-policies)
