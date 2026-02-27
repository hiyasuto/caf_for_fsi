# 07 — クラウドガバナンス

> FISC統制基準（統20〜統24, 統28）→ Azure Cloud Governance / Shared Responsibility

## 概要

FISC統制基準における外部委託管理・クラウドサービス利用に関する基準を、Azureのクラウドガバナンス機能と責任共有モデルに基づいて実現します。クラウド特有のリスク管理は、金融機関がAzureを採用する際の最重要事項です。

## 1. 統24: クラウドサービス固有の安全対策

**FISC要件**: クラウドサービスを利用する場合は、クラウドサービス固有のリスクを考慮した安全対策を講ずること。

### 責任共有モデル（Shared Responsibility）

Azureでは、サービスモデルに応じてMicrosoftと顧客の責任範囲が異なります：

```
                    IaaS        PaaS        SaaS
──────────────────────────────────────────────────
アプリケーション     顧客        顧客        MS/顧客
ネットワーク制御     顧客        MS/顧客     Microsoft
OS                  顧客        Microsoft   Microsoft
物理ホスト          Microsoft   Microsoft   Microsoft
物理ネットワーク     Microsoft   Microsoft   Microsoft
物理データセンター   Microsoft   Microsoft   Microsoft
──────────────────────────────────────────────────
```

### FISC要件に対するAzure対応

| FISC観点 | リスク | Azure対応 |
|---------|-------|----------|
| データ所在地 | データが国外に保存されるリスク | 日本リージョン（東日本・西日本）での明示的なデータ所在地指定 |
| データ分離 | 他テナントとのデータ混在リスク | 論理的テナント分離、Confidential Computing、Dedicated Host |
| 可用性 | クラウドサービス障害リスク | SLA保証（99.9%〜99.999%）、可用性ゾーン、マルチリージョン |
| 監査権限 | クラウド環境の監査困難 | Microsoft Service Trust Portal、SOC報告書、ISO認証 |
| データ消去 | サービス終了時のデータ残存リスク | Microsoft DPA（データ処理契約）による消去保証、暗号鍵削除 |
| ベンダーロックイン | 特定クラウドへの依存リスク | オープンスタンダード技術の利用、IaCによる移植性確保 |
| 法規制 | 国外法規制の適用リスク | 日本の法令準拠、Microsoft の透明性レポート |

### データ所在地（Data Residency）

金融機関にとってデータ所在地の管理は特に重要です：

| 要件 | Azure機能 | 説明 |
|------|----------|------|
| リージョン指定 | Azure 日本リージョン | 東日本（東京）・西日本（大阪）でのデータ格納 |
| データ境界 | EU Data Boundary（参考） | リージョン外へのデータ流出防止 |
| 暗号化制御 | 顧客管理キー（CMK） | 顧客が暗号鍵を管理し、データアクセスを制御 |
| 秘匿処理 | Azure Confidential Computing | 処理中もデータを暗号化（TEE） |

## 2. 外部委託管理（統20〜統23）

### Azure利用における外部委託としての考え方

| FISC基準 | 要件 | Azure対応 |
|---------|------|----------|
| 統20 | 委託先選定手続き | Azureの認証・認定（SOC, ISO, PCI DSS等）の確認 |
| 統21 | 安全対策に関する契約 | Microsoft Product Terms, DPA, SLA |
| 統23 | 委託業務の遂行状況確認 | Azure Service Health, Azure Monitor, Service Trust Portal |

### Azureの第三者認証・認定

| 認証・規格 | 内容 |
|-----------|------|
| ISO/IEC 27001 | 情報セキュリティマネジメント |
| ISO/IEC 27017 | クラウドセキュリティ |
| ISO/IEC 27018 | クラウド上の個人情報保護 |
| SOC 1 Type II | 財務報告に関する内部統制 |
| SOC 2 Type II | セキュリティ・可用性・処理の完全性・機密性・プライバシー |
| PCI DSS Level 1 | クレジットカード業界データセキュリティ基準 |
| CSA STAR | クラウドセキュリティアライアンス |
| ISMAP | 政府情報システムのためのセキュリティ評価制度 |

## 3. サプライチェーンセキュリティ（統28）

### 統28: サプライチェーンを考慮したサイバーセキュリティリスク管理（第13版新設）

**FISC要件**: サプライチェーンを考慮したサイバーセキュリティリスクを適切に管理すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| サプライチェーン可視化 | Microsoft Defender for Cloud（CSPM） | クラウド環境のサプライチェーンリスク評価 |
| ソフトウェアサプライチェーン | GitHub Advanced Security | 依存関係の脆弱性検出、SBOM生成 |
| 委託先セキュリティ | Microsoft Secure Score | サプライチェーン全体のセキュリティ態勢評価 |
| ゼロトラスト | Microsoft Entra ID + Conditional Access | サプライチェーン接続のゼロトラスト検証 |

## 4. Azure管理グループ設計（金融機関向け）

```
テナントルートグループ
├── 金融機関等 (Management Group)
│   ├── プラットフォーム (Management Group)
│   │   ├── ID管理 (Subscription)
│   │   │   └── Microsoft Entra ID, Key Vault
│   │   ├── 接続性 (Subscription)
│   │   │   └── Hub VNet, ExpressRoute, Firewall
│   │   └── 管理 (Subscription)
│   │       └── Log Analytics, Sentinel, Automation
│   ├── ランディングゾーン (Management Group)
│   │   ├── 基幹系 (Management Group)
│   │   │   ├── 勘定系 (Subscription)
│   │   │   └── 為替系 (Subscription)
│   │   ├── 情報系 (Management Group)
│   │   │   ├── CRM (Subscription)
│   │   │   └── DWH (Subscription)
│   │   └── チャネル系 (Management Group)
│   │       ├── インターネットバンキング (Subscription)
│   │       └── モバイルバンキング (Subscription)
│   └── サンドボックス (Management Group)
│       └── 開発・検証 (Subscription)
└── (FISC準拠 Azure Policy を各レベルに適用)
```

## 5. Azure Policy によるFISC準拠のガードレール

### 推奨ポリシー例

| ポリシー | FISC基準 | 効果 |
|---------|---------|------|
| 許可リージョンの制限（日本のみ） | 統24（データ所在地） | Deny |
| ストレージ暗号化の強制 | 実3 | Deny |
| TLS 1.2以上の強制 | 実4 | Deny |
| パブリックIPの制限 | 実15 | Deny |
| ネットワークアクセスの制限 | 実14 | Audit/Deny |
| 診断ログの有効化 | 実10, 実16 | DeployIfNotExists |
| Key Vaultの利用強制 | 実13, 実30 | Audit |
| タグの必須化（分類情報） | 統7 | Deny |
| マネージドディスク暗号化 | 実3 | Audit |
| SQL Database監査の有効化 | 実10 | DeployIfNotExists |

## 参考リンク

- [Azure Cloud Adoption Framework — Landing Zone](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Policy](https://learn.microsoft.com/azure/governance/policy/)
- [Azure Management Groups](https://learn.microsoft.com/azure/governance/management-groups/)
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [Azure の日本リージョン](https://azure.microsoft.com/explore/global-infrastructure/geographies/)
- [Azure コンプライアンス認証](https://learn.microsoft.com/azure/compliance/)


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [08. AI安全対策](08-ai-safety.md) | AI/生成AIの利用方針・リスク管理 |
| → | [FSI向けランディングゾーン リファレンスアーキテクチャ](../landing-zone/reference-architecture.md) | 全体アーキテクチャ・Hub-Spoke 設計 |
| → | [FISC基準→Azureサービス マッピング](../mapping/fisc-to-azure-services.md) | FISC全324基準のAzureサービス対応表 |