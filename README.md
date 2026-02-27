# FISC準拠 金融機関向け Azure Cloud Adoption Framework

> FISC安全対策基準・解説書（第13版)参照 日本の金融機関向け Azure Cloud Adoption Framework および Well-Architected Framework 

## 概要

本フレームワークは、金融情報システムセンター（FISC）が策定した「金融機関等コンピュータシステムの安全対策基準・解説書（第13版、2025年3月）」および「コンティンジェンシープラン策定のための手引書（第5版）」の要件を、Microsoft Azure のクラウドサービス上で実現するための包括的なガイダンスです。

Azure Cloud Adoption Framework（CAF）の導入方法論と Well-Architected Framework（WAF）の5つの柱を基盤とし、FISC基準の324項目（統制基準36項目、実務基準152項目、設備基準134項目、監査基準2項目）をAzureサービスにマッピングしています。

#本資料は個人で作成したものかつレビュー中であり、FISCおよびAzure CAF/WAFへの準拠における完全性を担保するものではないことをご了承ください。

## 対象読者

- 金融機関等のIT部門・システムリスク管理部門
- クラウド移行を検討する金融機関等の経営層・CIO/CISO
- 金融機関等を支援するSIer・コンサルタント
- Azure上で金融システムを構築するアーキテクト・エンジニア

## フレームワーク構成

### 📘 ドキュメント

| # | ドキュメント | 概要 | 対応FISC基準 |
|---|------------|------|------------|
| 01 | [フレームワーク概要](docs/01-overview.md) | 全体構造・FISC×CAF×WAFの統合 | 全体 |
| 02 | [ITガバナンス・統制](docs/02-governance.md) | 経営層の役割・方針策定・体制整備 | 統1〜統28 |
| 03 | [セキュリティ](docs/03-security.md) | 認証・暗号化・ネットワーク・サイバー対策 | 実1〜実19, 実25〜実30 |
| 04 | [信頼性・事業継続](docs/04-reliability.md) | DR・バックアップ・コンティンジェンシープラン | 実39〜実45, 実71〜実73-1 |
| 05 | [運用管理](docs/05-operations.md) | システム運用・監視・変更管理 | 実34〜実62 |
| 06 | [セキュア開発](docs/06-development.md) | 開発プロセス・テスト・品質管理 | 実75〜実101 |
| 07 | [クラウドガバナンス](docs/07-cloud-governance.md) | クラウド固有リスク・責任分界・外部委託 | 統20〜統24, 統28 |
| 08 | [AI安全対策](docs/08-ai-safety.md) | AI/生成AIの利用方針・リスク管理 | 実150〜実153 |
| 09 | [監査](docs/09-audit.md) | システム監査・サイバーセキュリティ監査 | 監1, 監1-1 |

### 📊 マッピング

| ドキュメント | 概要 |
|------------|------|
| [FISC基準→Azureサービス マッピング](mapping/fisc-to-azure-services.md) | FISC全324基準項目とAzureサービスの対応表 |

### 🏗️ ランディングゾーン

| ドキュメント | 概要 |
|------------|------|
| [FSI向けAzureランディングゾーン](landing-zone/reference-architecture.md) | 全体アーキテクチャ・システム一覧 |

#### システム別ランディングゾーン

| 区分 | システム | 重要度 | ドキュメント |
|------|---------|-------|------------|
| 基幹系 | 勘定系（コアバンキング） | Tier 1 | [core-banking.md](landing-zone/core-banking.md) |
| 基幹系 | 為替・決済系 | Tier 1 | [payment-settlement.md](landing-zone/payment-settlement.md) |
| 基幹系 | 融資系 | Tier 2 | [lending.md](landing-zone/lending.md) |
| 基幹系 | 市場系・トレーディング | Tier 1〜2 | [market-trading.md](landing-zone/market-trading.md) |
| 基幹系 | 対外接続系（全銀/SWIFT等） | Tier 1 | [external-connectivity.md](landing-zone/external-connectivity.md) |
| チャネル系 | インターネットバンキング | Tier 2〜3 | [internet-banking.md](landing-zone/internet-banking.md) |
| チャネル系 | モバイルバンキング | Tier 2〜3 | [mobile-banking.md](landing-zone/mobile-banking.md) |
| チャネル系 | ATM系 | Tier 2〜3 | [atm.md](landing-zone/atm.md) |
| 情報系 | DWH/BI | Tier 3 | [dwh-bi.md](landing-zone/dwh-bi.md) |
| 情報系 | リスク管理 | Tier 2〜3 | [risk-management.md](landing-zone/risk-management.md) |
| 情報系 | AML/KYC（マネロン対策） | Tier 2 | [aml-kyc.md](landing-zone/aml-kyc.md) |
| AI基盤 | AI・生成AI基盤 | Tier 3〜4 | [ai-platform.md](landing-zone/ai-platform.md) |

## FISC基準とAzure WAF 5つの柱の対応

```
┌─────────────────────────────────────────────────────────────────┐
│                    FISC 安全対策基準 (第13版)                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ 統制基準   │ │ 実務基準   │ │ 設備基準   │ │ 監査基準   │            │
│  │  (36項目)  │ │ (152項目)  │ │ (134項目)  │ │  (2項目)   │            │
│  └─────┬────┘ └─────┬────┘ └─────┬────┘ └─────┬────┘            │
│        │            │            │            │                    │
│        ▼            ▼            ▼            ▼                    │
│  ┌───────────────────────────────────────────────────────┐        │
│  │           Azure Well-Architected Framework            │        │
│  │  ┌─────────┐┌──────┐┌────────┐┌──────────┐┌────────┐ │        │
│  │  │信頼性    ││セキュ││コスト  ││オペレー  ││パフォー│ │        │
│  │  │Reliability││リティ││最適化  ││ショナル  ││マンス  │ │        │
│  │  │         ││Security││Cost   ││Excellence││Efficiency│        │
│  │  └─────────┘└──────┘└────────┘└──────────┘└────────┘ │        │
│  └───────────────────────────────────────────────────────┘        │
│                              │                                     │
│                              ▼                                     │
│  ┌───────────────────────────────────────────────────────┐        │
│  │         Azure Cloud Adoption Framework                │        │
│  │  戦略 → 計画 → 準備 → 導入 → ガバナンス → 管理       │        │
│  └───────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

## FISC第13版 主な改訂ポイント（2025年3月）

1. **経済安全保障推進法への対応** — 特定社会基盤事業者としての義務
2. **オペレーショナル・レジリエンス** — 金融庁ガイドラインへの対応
3. **サイバーセキュリティガイドライン** — 金融庁2024年10月公表ガイドライン
4. **AI安全対策** — 生成AI利用のリスク管理基準を新設（実150〜153）
5. **サプライチェーンセキュリティ** — 統28を新設

## Azure 金融機関 公開事例（Microsoft 発表）

Microsoftが公式に発表している金融機関のAzure活用事例です。

### 🇯🇵 国内事例

| 企業名 | 概要 | リンク |
|--------|------|--------|
| 山梨中央銀行 | Azure OpenAI Service を全行導入し、生成AIによる業務効率化・インサイト営業を推進 | [Microsoft Customer Story](https://www.microsoft.com/ja-jp/customers/story/24415-yamanashi-chuo-bank-azure-openai) |
| BIPROGY（BankVision） | 国内初の Microsoft Azure を稼働基盤とする銀行勘定系システムを構築（12行で採用） | [Microsoft Customer Story](https://www.microsoft.com/ja-jp/customers/story/22503-biprogy-azure) |
| 三井住友フィナンシャルグループ | 日本の大手銀行として初めてMicrosoftと複数年の戦略的クラウド提携を締結、Azure を優先クラウド基盤に選定 | [Microsoft News（APAC）](https://news.microsoft.com/apac/2022/10/28/how-smbc-group-became-a-leader-in-transformation-and-digital-perseverance/) |
| 第一生命ホールディングス | Microsoftとの複数年にわたる戦略的グローバルパートナーシップを締結、Azure を優先クラウド基盤として「保険サービス業」への変革を推進 | [Microsoft News（Japan）](https://news.microsoft.com/ja-jp/2024/08/23/240823-dai-ichi-life-holdings-x-microsoft-global-strategic-partnership-to-accelerate-digital-innovation/) |

### 🌍 海外事例

| 企業名 | 国・地域 | 概要 | リンク |
|--------|---------|------|--------|
| Discovery Bank | 南アフリカ | Azure と Azure Databricks で AI 駆動のパーソナライズド金融サービスを構築、500% ROI を達成 | [Microsoft Customer Story](https://www.microsoft.com/en/customers/story/23562-discovery-bank-azure) |
| Ally Financial | 米国 | Azure OpenAI Service で顧客サービスの手動タスクを自動化、担当者がより顧客対応に集中できる環境を実現 | [Microsoft Customer Story](https://www.microsoft.com/en/customers/story/1715820133841482699-ally-azure-banking-en-united-states) |
| Banco Bradesco | ブラジル | Azure AI Foundry 上にマルチエージェント生成AI基盤「Bridge」を構築、デジタル顧客対応で解決率83%・技術コスト30%以上削減 | [Microsoft Customer Story](https://www.microsoft.com/en/customers/story/25660-banco-bradesco-sa-azure-ai-foundry/) |
| Capitec Bank | 南アフリカ | Microsoft 365 Copilot と Azure OpenAI Service で従業員の生産性向上（週1時間以上の時間節約） | [Microsoft Customer Story](https://www.microsoft.com/en/customers/story/19093-capitec-bank-azure-open-ai-service) |

> **注記:** 上記は Microsoft が公式に発表した事例の一部です。最新の事例は [Microsoft Customer Stories](https://www.microsoft.com/en-us/customers/) および [Azure Customer Stories](https://azure.microsoft.com/en-us/resources/customer-stories/) で確認できます。

## 関連リソース

- [Azure Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Microsoft for Financial Services](https://learn.microsoft.com/industry/financial-services/)
- [Azure コンプライアンス認証](https://learn.microsoft.com/azure/compliance/)
- [FISC 金融情報システムセンター](https://www.fisc.or.jp/)

## ライセンス

本リポジトリのドキュメントは情報提供目的であり、FISC安全対策基準の公式な解釈を提供するものではありません。正式な基準内容はFISCの原本を参照してください。

---

*本フレームワークは FISC安全対策基準・解説書 第13版（2025年3月）および コンティンジェンシープラン策定のための手引書 第5版（2025年3月）に基づいています。*
