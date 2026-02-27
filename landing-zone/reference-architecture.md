# FSI向け Azure ランディングゾーン リファレンスアーキテクチャ

> FISC安全対策基準準拠のAzureランディングゾーン設計ガイダンス

## 概要

本ドキュメントは、Azure Cloud Adoption Framework のランディングゾーン概念に基づき、FISC安全対策基準に準拠した金融機関向けAzureランディングゾーンのリファレンスアーキテクチャを示します。

## システム別ランディングゾーン一覧

各金融システムの特性に応じた個別ランディングゾーン設計ガイダンスを用意しています。

### 基幹系システム

| システム | ドキュメント |
|---------|------------|
| 勘定系（コアバンキング） | [アーキテクチャ: 勘定系（コアバンキング）](core-banking.md) |
| 為替・決済系 | [アーキテクチャ: 為替・決済系](payment-settlement.md) |
| 融資系 | [アーキテクチャ: 融資系](lending.md) |
| 市場系・トレーディング | [アーキテクチャ: 市場系・トレーディング](market-trading.md) |
| 対外接続系（全銀/SWIFT等） | [アーキテクチャ: 対外接続系（全銀/SWIFT等）](external-connectivity.md) |

### チャネル系システム

| システム | ドキュメント |
|---------|------------|
| インターネットバンキング | [アーキテクチャ: インターネットバンキング](internet-banking.md) |
| モバイルバンキング | [アーキテクチャ: モバイルバンキング](mobile-banking.md) |
| ATM系 | [アーキテクチャ: ATM系](atm.md) |
| APIバンキング（オープンAPI） | [アーキテクチャ: APIバンキング（オープンAPI）](api-banking.md) |

### 情報・管理系システム

| システム | ドキュメント |
|---------|------------|
| 情報系・DWH/BI | [アーキテクチャ: 情報系・DWH/BI](dwh-bi.md) |
| リスク管理系 | [アーキテクチャ: リスク管理系](risk-management.md) |
| AML/KYC（マネロン対策） | [アーキテクチャ: AML/KYC（マネロン対策）](aml-kyc.md) |

### セキュリティ・レジリエンス基盤

| システム | ドキュメント |
|---------|------------|
| サイバーレジリエンス | [アーキテクチャ: サイバーレジリエンス](cyber-resilience.md) |

### メインフレーム連携・移行

| システム | ドキュメント |
|---------|------------|
| メインフレーム連携・移行 | [アーキテクチャ: メインフレーム連携・移行](mainframe-integration.md) |

### イノベーション・開発基盤

| システム | ドキュメント |
|---------|------------|
| 生成AI/エージェント基盤 | [アーキテクチャ: 生成AI/エージェント基盤](ai-platform.md) |
| 開発基盤（Engineering Platform） | [アーキテクチャ: 開発基盤（Engineering Platform）](engineering-platform.md) |

## アーキテクチャ全体像

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      Azure テナント（金融機関等）                           │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │               テナントルート管理グループ                                │  │
│  │                   (FISC共通ポリシー適用)                               │  │
│  │                                                                    │  │
│  │  ┌──────────────────────┐  ┌────────────────────────────────────┐ │  │
│  │  │ プラットフォーム        │  │  ランディングゾーン                    │ │  │
│  │  │                      │  │                                    │ │  │
│  │  │ ┌──────────────────┐ │  │ ┌────────────┐ ┌────────────────┐│ │  │
│  │  │ │ID管理             │ │  │ │基幹系       │ │チャネル系       ││ │  │
│  │  │ │・Entra ID         │ │  │ │・勘定系     │ │・IB            ││ │  │
│  │  │ │・Entra PIM        │ │  │ │・為替・決済 │ │・MB            ││ │  │
│  │  │ │・Key Vault        │ │  │ │・融資系     │ │・ATM           ││ │  │
│  │  │ │・Managed HSM      │ │  │ │・市場系     │ │・APIバンキング  ││ │  │
│  │  │ └──────────────────┘ │  │ │・対外接続   │ └────────────────┘│ │  │
│  │  │ ┌──────────────────┐ │  │ └────────────┘ ┌────────────────┐│ │  │
│  │  │ │接続性             │ │  │ ┌────────────┐ │情報・管理系     ││ │  │
│  │  │ │・Hub VNet         │ │  │ │横断基盤     │ │・DWH/BI        ││ │  │
│  │  │ │・ExpressRoute     │ │  │ │・サイバー   │ │・リスク管理     ││ │  │
│  │  │ │・Azure Firewall   │ │  │ │  レジリエンス│ │・AML/KYC       ││ │  │
│  │  │ │・DNS              │ │  │ │・開発基盤   │ └────────────────┘│ │  │
│  │  │ └──────────────────┘ │  │ └────────────┘ ┌────────────────┐│ │  │
│  │  │ ┌──────────────────┐ │  │ ┌────────────┐ │イノベーション    ││ │  │
│  │  │ │管理・監視          │ │  │ │メインフレーム│ │・AI/生成AI基盤  ││ │  │
│  │  │ │・Log Analytics    │ │  │ │連携・移行   │ └────────────────┘│ │  │
│  │  │ │・Sentinel         │ │  │ └────────────┘                    │ │  │
│  │  │ │・Defender         │ │  └────────────────────────────────────┘ │  │
│  │  │ │・Azure Monitor    │ │                                        │  │
│  │  │ └──────────────────┘ │                                        │  │
│  │  └──────────────────────┘                                        │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ オンプレミス接続                                                      │  │
│  │ ・ExpressRoute（専用線）                                              │  │
│  │ ・Site-to-Site VPN（バックアップ）                                     │  │
│  │ ・メインフレーム連携（CDC / MQ / HULFT）                               │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
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

### Spoke VNet CIDR 割り当て一覧

各ランディングゾーンに対して、以下の CIDR ブロックを割り当てています。

| システム | VNet CIDR | 用途 |
|---------|----------|------|
| 勘定系（本番） | 10.1.0.0/16 | コアバンキング |
| 勘定系（DR） | 10.2.0.0/16 | DR環境 |
| 為替・決済（本番） | 10.3.0.0/16 | 為替・決済処理 |
| 為替・決済（DR） | 10.4.0.0/16 | DR環境 |
| SWIFT 専用 | 10.5.0.0/16 | SWIFT CSP準拠 |
| 融資系（本番） | 10.6.0.0/16 | 融資業務 |
| 融資系（DR） | 10.7.0.0/16 | DR環境 |
| 市場系（本番） | 10.8.0.0/16 | トレーディング |
| 市場系（DR） | 10.9.0.0/16 | DR環境 |
| 対外接続系（本番） | 10.10.0.0/16 | 全銀等 |
| 対外接続系（DR） | 10.11.0.0/16 | DR環境 |
| SWIFT対外接続専用 | 10.12.0.0/16 | SWIFT CSP準拠 |
| IB（本番） | 10.14.0.0/16 | インターネットバンキング |
| IB（DR） | 10.15.0.0/16 | DR環境 |
| DWH/BI（本番） | 10.16.0.0/16 | 情報系 |
| DWH/BI（DR） | 10.17.0.0/16 | DR環境 |
| AML/KYC（本番） | 10.18.0.0/16 | マネロン対策 |
| AML/KYC（DR） | 10.19.0.0/16 | DR環境 |
| AI基盤（本番） | 10.20.0.0/16 | 生成AI/エージェント |
| AI基盤（DR） | 10.21.0.0/16 | DR環境 |
| モバイル（本番） | 10.22.0.0/16 | モバイルバンキング |
| モバイル（DR） | 10.23.0.0/16 | DR環境 |
| リスク管理（本番） | 10.24.0.0/16 | リスク管理 |
| リスク管理（DR） | 10.25.0.0/16 | DR環境 |
| ATM（本番） | 10.26.0.0/16 | ATM系 |
| ATM（DR） | 10.27.0.0/16 | DR環境 |
| 開発基盤（本番） | 10.28.0.0/16 | Engineering Platform |
| 開発基盤（DR） | 10.29.0.0/16 | DR環境 |
| APIバンキング（本番） | 10.30.0.0/16 | オープンAPI |
| APIバンキング（DR） | 10.31.0.0/16 | DR環境 |
| サイバーレジリエンス（Data Bunker） | 10.32.0.0/16 | 隔離バックアップ |
| サイバーレジリエンス（Restore） | 10.33.0.0/16 | 復旧環境 |
| サイバーレジリエンス（Forensic） | 10.34.0.0/16 | フォレンジック |
| メインフレーム連携（本番） | 10.35.0.0/16 | MF連携 |
| メインフレーム連携（DR） | 10.36.0.0/16 | DR環境 |

### Spoke VNet サブネット構成例（勘定系）

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
| 転送中暗号化 | TLS 1.2+ / IPsec / MACsec | 実4: 伝送データ保護 |
| 鍵管理 | Azure Key Vault Managed HSM（FIPS 140-2 L3） | 実13: 暗号鍵保護 |
| 決済用鍵管理 | Azure Payment HSM | 実13: 暗号鍵保護 |
| 機密コンピューティング | Azure Confidential Computing（DCsv3/ACIセキュアエンクレーブ） | 実3: 蓄積データ保護 |
| データ改ざん防止 | 不変ストレージ（WORM）/ SQL Ledger テーブル | 実5: データ改ざん防止 |
| データ分類 | Microsoft Purview | 統7: データ管理 |

### 監視・検知

| 対策 | Azureサービス | FISC対応 |
|------|-------------|---------|
| SIEM | Microsoft Sentinel | 実14-1: サイバー攻撃検知 |
| CSPM | Defender for Cloud | 統13: セキュリティ遵守確認 |
| EDR | Defender for Endpoint | 実16: 不正アクセス監視 |
| NDR | Network Watcher + Flow Logs | 実16: 不正アクセス監視 |
| AI保護 | Defender for AI | 実152: AI安全対策 |
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

### DR テスト・検証

| 対策 | Azureサービス | FISC対応 |
|------|-------------|---------|
| 障害注入テスト | Azure Chaos Studio | 実72: 復旧テスト |
| フェイルオーバーテスト | ASR テストフェイルオーバー | 実72: 復旧テスト |
| バックアップ復元テスト | Azure Backup 復元検証 | 実44: リストアテスト |
| サイバー攻撃想定訓練 | Microsoft Sentinel + Chaos Studio | 実73-1: インシデント対応計画 |

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

> **参考**: Azure Policy の組み込みイニシアチブ [Microsoft Cloud Security Benchmark](https://learn.microsoft.com/azure/governance/policy/samples/microsoft-cloud-security-benchmark) および [Azure Landing Zone ポリシー](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/dine-guidance) をベースに、FISC 固有の要件（リージョン制限、暗号化強制等）を追加することを推奨します。

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

### Azure ランディングゾーン
- [Azure Landing Zone](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Landing Zone Design Areas](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-areas)
- [Azure Landing Zone ポリシー](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/enterprise-scale/dine-guidance)

### セキュリティ・コンプライアンス
- [Microsoft for Financial Services](https://learn.microsoft.com/industry/financial-services/)
- [Microsoft Cloud Security Benchmark](https://learn.microsoft.com/azure/governance/policy/samples/microsoft-cloud-security-benchmark)
- [Azure Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/overview)
- [Azure Chaos Studio](https://learn.microsoft.com/azure/chaos-studio/chaos-studio-overview)

### インフラストラクチャ
- [Azure リージョン（日本）](https://azure.microsoft.com/explore/global-infrastructure/geographies/)
- [Azure 可用性ゾーン](https://learn.microsoft.com/azure/reliability/availability-zones-overview)
- [Azure ExpressRoute](https://learn.microsoft.com/azure/expressroute/)

### 本フレームワーク関連
- [FISC × Azure フレームワーク ドキュメント](../docs/01-overview.md)
- [FISC基準→Azureサービス マッピング](../mapping/fisc-to-azure-services.md)
- [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md)

---

## 次のステップ

| 次のドキュメント | 概要 |
|----------------|------|
| [フレームワーク概要](../docs/01-overview.md) | FISC × CAF × WAF の統合フレームワーク全体像 |
| [勘定系（コアバンキング）](core-banking.md) | 最も重要度の高い基幹系 LZ の設計ガイダンス |
| [サイバーレジリエンス](cyber-resilience.md) | 横断的なセキュリティ・レジリエンス基盤 |
