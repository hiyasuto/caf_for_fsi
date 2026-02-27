# FSI向け Azure ランディングゾーン リファレンスアーキテクチャ

> FISC安全対策基準準拠のAzureランディングゾーン設計ガイダンス

## 概要

本ドキュメントは、Azure Cloud Adoption Framework のランディングゾーン概念に基づき、FISC安全対策基準に準拠した金融機関向けAzureランディングゾーンのリファレンスアーキテクチャを示します。

## システム別ランディングゾーン一覧

各金融システムの特性に応じた個別ランディングゾーン設計ガイダンスを用意しています。

### 基幹系システム

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| 勘定系（コアバンキング） | Tier 1 | 重大な外部性 | [アーキテクチャ: 勘定系（コアバンキング）](core-banking.md) |
| 為替・決済系 | Tier 1 | 重大な外部性 | [アーキテクチャ: 為替・決済系](payment-settlement.md) |
| 融資系 | Tier 2 | 機微性 | [アーキテクチャ: 融資系](lending.md) |
| 市場系・トレーディング | Tier 1〜2 | 業態による | [アーキテクチャ: 市場系・トレーディング](market-trading.md) |
| 対外接続系（全銀/SWIFT等） | Tier 1 | 重大な外部性 | [アーキテクチャ: 対外接続系（全銀/SWIFT等）](external-connectivity.md) |

### チャネル系システム

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| インターネットバンキング | Tier 2〜3 | 判断による | [アーキテクチャ: インターネットバンキング](internet-banking.md) |
| モバイルバンキング | Tier 2〜3 | 判断による | [アーキテクチャ: モバイルバンキング](mobile-banking.md) |
| ATM系 | Tier 2〜3 | 判断による | [アーキテクチャ: ATM系](atm.md) |
| APIバンキング（オープンAPI） | Tier 2 | 機微性 | [アーキテクチャ: APIバンキング（オープンAPI）](api-banking.md) |

### 情報・管理系システム

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| 情報系・DWH/BI | Tier 3 | なし | [アーキテクチャ: 情報系・DWH/BI](dwh-bi.md) |
| リスク管理系 | Tier 2〜3 | なし | [アーキテクチャ: リスク管理系](risk-management.md) |
| AML/KYC（マネロン対策） | Tier 2 | 機微性 | [アーキテクチャ: AML/KYC（マネロン対策）](aml-kyc.md) |

### イノベーション基盤

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| AI・生成AI基盤 | Tier 3〜4 | 用途による | [アーキテクチャ: AI・生成AI基盤](ai-platform.md) |

### メインフレーム連携・移行

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| メインフレーム連携・移行 | 連携先に依存 | 連携先に準ずる | [アーキテクチャ: メインフレーム連携・移行](mainframe-integration.md) |

### セキュリティ・レジリエンス基盤

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| サイバーレジリエンス | Tier 1 | 横断的基盤 | [アーキテクチャ: サイバーレジリエンス](cyber-resilience.md) |

### 開発基盤

| システム | 重要度 | FISC外部性 | ドキュメント |
|---------|-------|-----------|------------|
| 開発基盤（Engineering Platform） | Tier 3〜4 | なし | [アーキテクチャ: 開発基盤（Engineering Platform）](engineering-platform.md) |

## アーキテクチャ全体像

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Azure テナント（金融機関等）                        │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │              テナントルート管理グループ                           │  │
│  │                  (FISC共通ポリシー適用)                          │  │
│  │                                                               │  │
│  │  ┌─────────────────────┐  ┌─────────────────────────────────┐│  │
│  │  │ プラットフォーム       │  │  ランディングゾーン               ││  │
│  │  │                     │  │                                 ││  │
│  │  │ ┌─────────────────┐ │  │ ┌──────────┐ ┌──────────────┐ ││  │
│  │  │ │ID管理            │ │  │ │基幹系     │ │情報系         │ ││  │
│  │  │ │・Entra ID        │ │  │ │・勘定系   │ │・DWH/BI      │ ││  │
│  │  │ │・Entra PIM       │ │  │ │・為替系   │ │・CRM         │ ││  │
│  │  │ │・Key Vault       │ │  │ │・融資系   │ │・データ分析   │ ││  │
│  │  │ └─────────────────┘ │  │ └──────────┘ └──────────────┘ ││  │
│  │  │ ┌─────────────────┐ │  │ ┌──────────┐ ┌──────────────┐ ││  │
│  │  │ │接続性            │ │  │ │チャネル系 │ │AI/イノベーション││  │
│  │  │ │・Hub VNet        │ │  │ │・IB      │ │・Azure OpenAI│ ││  │
│  │  │ │・ExpressRoute    │ │  │ │・MB      │ │・ML          │ ││  │
│  │  │ │・Azure Firewall  │ │  │ │・API     │ │・PoC環境     │ ││  │
│  │  │ │・DNS             │ │  │ └──────────┘ └──────────────┘ ││  │
│  │  │ └─────────────────┘ │  │                                 ││  │
│  │  │ ┌─────────────────┐ │  └─────────────────────────────────┘│  │
│  │  │ │管理・監視         │ │  ┌─────────────────────────────────┐│  │
│  │  │ │・Log Analytics   │ │  │ サンドボックス                     ││  │
│  │  │ │・Sentinel        │ │  │ ・開発/検証環境                    ││  │
│  │  │ │・Defender        │ │  │ ・PoC環境                         ││  │
│  │  │ │・Azure Monitor   │ │  └─────────────────────────────────┘│  │
│  │  │ └─────────────────┘ │                                     │  │
│  │  └─────────────────────┘                                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ オンプレミス接続                                                 │  │
│  │ ・ExpressRoute（専用線）                                         │  │
│  │ ・Site-to-Site VPN（バックアップ）                                │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## ネットワーク設計（Hub-Spoke）

### Hub VNet（プラットフォーム接続性）

```
Hub VNet (10.0.0.0/16)
├── GatewaySubnet (10.0.0.0/24)
│   ├── ExpressRoute Gateway
│   └── VPN Gateway (バックアップ)
├── AzureFirewallSubnet (10.0.1.0/24)
│   └── Azure Firewall Premium
├── AzureBastionSubnet (10.0.2.0/24)
│   └── Azure Bastion
├── DNS Subnet (10.0.3.0/24)
│   └── Azure Private DNS Resolver
└── Management Subnet (10.0.4.0/24)
    └── 管理用VM（必要時のみ）
```

### Spoke VNet（ランディングゾーン）

```
Spoke VNet - 勘定系 (10.1.0.0/16)
├── App Subnet (10.1.1.0/24)
│   └── App Service Environment v3 / AKS
├── DB Subnet (10.1.2.0/24)
│   └── Azure SQL MI / Cosmos DB
├── Integration Subnet (10.1.3.0/24)
│   └── API Management, Service Bus
└── Private Endpoint Subnet (10.1.4.0/24)
    └── Key Vault, Storage PE
```

## FISC準拠のセキュリティ設計

### ネットワークセキュリティ

| レイヤー | Azureサービス | FISC対応 |
|---------|-------------|---------|
| 境界防御 | Azure Firewall Premium | 実14: 不正侵入防止 |
| Web防御 | Azure WAF (Front Door) | 実14: 不正侵入防止 |
| DDoS防御 | Azure DDoS Protection | 実14: 不正侵入防止 |
| セグメンテーション | NSG + ASG | 実15: 接続機器最小化 |
| プライベート接続 | Private Link / Private Endpoint | 実15: 接続機器最小化 |
| DNS | Azure Private DNS Zone | 実15: 接続機器最小化 |

### ID・アクセス管理

| 対策 | Azureサービス | FISC対応 |
|------|-------------|---------|
| 統合認証 | Microsoft Entra ID | 実8: 本人確認 |
| MFA | Microsoft Entra MFA | 実1: パスワード保護 |
| 特権管理 | Microsoft Entra PIM | 実25: アクセス権限管理 |
| 条件付きアクセス | Conditional Access | 実9: ID不正使用防止 |
| ゼロトラスト | ゼロトラストアーキテクチャ | 統4: セキュリティ管理 |

### データ保護

| 対策 | Azureサービス | FISC対応 |
|------|-------------|---------|
| 保存時暗号化 | TDE / Azure Disk Encryption | 実3: 蓄積データ保護 |
| 転送中暗号化 | TLS 1.2+ / IPsec | 実4: 伝送データ保護 |
| 鍵管理 | Azure Key Vault (HSM) | 実13: 暗号鍵保護 |
| 決済用鍵管理 | Azure Payment HSM | 実13: 暗号鍵保護 |
| データ分類 | Microsoft Purview | 統7: データ管理 |

### 監視・検知

| 対策 | Azureサービス | FISC対応 |
|------|-------------|---------|
| SIEM | Microsoft Sentinel | 実14-1: サイバー攻撃検知 |
| CSPM | Defender for Cloud | 統13: セキュリティ遵守確認 |
| EDR | Defender for Endpoint | 実16: 不正アクセス監視 |
| NDR | Network Watcher + Flow Logs | 実16: 不正アクセス監視 |
| ログ管理 | Log Analytics Workspace | 実10: アクセス履歴管理 |

## 可用性・DR設計

### リージョン構成

```
┌──────────────────────┐     ┌──────────────────────┐
│    東日本リージョン      │     │    西日本リージョン      │
│    (プライマリ)         │     │    (DR)               │
│                        │     │                       │
│  ┌──────────────────┐ │     │ ┌──────────────────┐  │
│  │ 可用性ゾーン1      │ │     │ │ ASR レプリカ       │  │
│  │ 可用性ゾーン2      │ │ ──▶ │ │ GRS バックアップ   │  │
│  │ 可用性ゾーン3      │ │     │ │ SQL Geo-Rep       │  │
│  └──────────────────┘ │     │ └──────────────────┘  │
│                        │     │                       │
│  RTO: 数分（AZ内FO）    │     │  RTO: 1-4時間（DR）    │
│  RPO: 0（同期）         │     │  RPO: 5分〜1時間       │
└──────────────────────┘     └──────────────────────┘
```

### 重要度別の構成パターン

| 重要度 | 構成 | RTO | RPO | 主なサービス |
|-------|------|-----|-----|------------|
| Tier 1（外部性大） | Active-Active マルチリージョン | < 5分 | ≈ 0 | Azure Front Door + AZ + SQL Auto-FO |
| Tier 2（基幹系） | Active-Passive マルチリージョン | < 1時間 | < 15分 | ASR + SQL Geo-Rep |
| Tier 3（重要業務） | Single Region + AZ | < 15分 | < 5分 | AZ + Azure Backup (GRS) |
| Tier 4（一般） | Single Region | < 4時間 | < 1時間 | Azure Backup |

## Azure Policy（FISC準拠ポリシー一覧）

### 必須ポリシー

```
# リージョン制限（日本のみ）
allowedLocations: ["japaneast", "japanwest"]

# ストレージ暗号化必須
storageAccountEncryption: "Deny if not encrypted"

# TLS 1.2以上
minimumTlsVersion: "1.2"

# パブリックIPの制限
denyPublicIp: "Deny"

# 診断ログの有効化
enableDiagnosticLogs: "DeployIfNotExists"

# Key Vault論理削除の有効化
keyVaultSoftDelete: "Deny if not enabled"

# SQLデータベース監査の有効化
sqlAuditing: "DeployIfNotExists"

# ネットワークアクセス制限
denyPublicNetworkAccess: "Deny"
```

## 導入ステップ

```
Phase 1: 基盤構築
  ├── 管理グループ・サブスクリプション設計
  ├── Azure Policy（FISC準拠）の適用
  ├── Microsoft Entra ID の設定
  └── Hub VNet・ExpressRoute の構築

Phase 2: セキュリティ基盤
  ├── Microsoft Defender for Cloud の有効化
  ├── Microsoft Sentinel の展開
  ├── Key Vault の構築
  └── ログ基盤（Log Analytics）の構築

Phase 3: ワークロード展開
  ├── Spoke VNet の展開
  ├── アプリケーションランディングゾーンの構築
  ├── DR/バックアップの設定
  └── 監視・アラートの設定

Phase 4: 運用最適化
  ├── セキュアスコアの改善
  ├── コンプライアンス評価の定期実施
  ├── DR訓練の実施
  └── Well-Architected Review の実施
```

## 参考リンク

- [Azure Landing Zone](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Landing Zone Design Areas](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [Microsoft for Financial Services](https://learn.microsoft.com/industry/financial-services/)
- [Azure リージョン（日本）](https://azure.microsoft.com/explore/global-infrastructure/geographies/)
- [Azure 可用性ゾーン](https://learn.microsoft.com/azure/reliability/availability-zones-overview)
- [Azure ExpressRoute](https://learn.microsoft.com/azure/expressroute/)
