# Azure CAF/WAF 標準ガイダンスとの差分

## 概要

本リポジトリは、Microsoft が提供する Azure Cloud Adoption Framework（CAF）および Well-Architected Framework（WAF）を基盤としつつ、FISC 安全対策基準・解説書（第13版、2025年3月）に準拠するための金融機関固有の拡張を行ったフレームワークです。標準の Azure CAF はクラウド導入方法論（Strategy / Plan / Ready / Adopt / Govern / Manage）を、Azure WAF はアーキテクチャの5つの柱（信頼性・セキュリティ・コスト最適化・オペレーショナルエクセレンス・パフォーマンス効率）を提供しますが、いずれも FISC 安全対策基準への対応を具体的にカバーしていません。本リポジトリはそのギャップを埋めるものです。

> **注:** AWS における [BLEA for FSI](https://github.com/aws-samples/baseline-environment-on-aws-for-financial-services-institute) が標準 BLEA に対して金融固有の差分を追加しているのと同様のアプローチです。

---

## 標準 Azure CAF/WAF と本フレームワークの関係

```
Standard Azure CAF/WAF（ベース）
├── Cloud Adoption Framework
│   ├── Strategy / Plan / Ready / Adopt / Govern / Manage
│   └── Azure Landing Zones (ALZ)
├── Well-Architected Framework
│   └── Reliability / Security / Cost / Operational Excellence / Performance
│
▼ 本フレームワークによる拡張
│
FISC準拠 金融機関向け Azure CAF（本リポジトリ）
├── FISC第13版 全324基準マッピング               [追加]
├── 金融ワークロード別ランディングゾーン（17システム）[追加]
├── FISC × Azure Policy ガードレール             [追加]
├── ガバナンスベース Bicep テンプレート            [追加]
├── AI安全対策基準（実150〜153）対応              [追加]
└── サイバーレジリエンス基盤                      [追加]
```

---

## FISC準拠のために追加した要素

### 1. FISC基準マッピング（ドキュメント）

標準の CAF/WAF には FISC 基準へのマッピングが存在しません。本リポジトリでは以下を追加しています。

| 追加コンテンツ | 説明 |
|--------------|------|
| [FISC全324基準 → Azure サービスマッピング](../mapping/fisc-to-azure-services.md) | 統制基準36項目・実務基準152項目・設備基準134項目・監査基準2項目の全基準を Azure サービスに対応付け |
| [ワークロード別 FISC 実務基準マッピング](../mapping/fisc-workload-mapping.md) | ランディングゾーンごとの FISC 実務基準適用要件と Azure 実装の横断マッピング |
| FISC × Azure Policy マッピング | Azure Policy 定義と FISC 基準項目の紐付け |

### 2. 金融ワークロード別ランディングゾーン

標準の Azure Landing Zones（ALZ）は汎用的な Hub-Spoke アーキテクチャを提供しますが、金融システム固有の要件には対応していません。本リポジトリでは17の FSI 固有ランディングゾーンを追加しています。

| 分類 | 対象システム |
|------|------------|
| **基幹系** | 勘定系（コアバンキング）、為替・決済系、融資系、市場系・トレーディング、対外接続系（全銀/SWIFT等） |
| **チャネル系** | インターネットバンキング、モバイルバンキング、ATM系、APIバンキング（オープンAPI） |
| **情報・管理系** | 情報系・DWH/BI、リスク管理系、AML/KYC（マネロン対策） |
| **セキュリティ・レジリエンス** | サイバーレジリエンス |
| **メインフレーム** | メインフレーム連携・移行 |
| **イノベーション** | 生成AI/エージェント基盤、開発基盤（Engineering Platform） |

各ランディングゾーンには以下を含みます:
- **FISC Tier 分類** — 基準が求める可用性・セキュリティレベルに基づくシステム分類
- **FISC 基準参照** — 当該システムに適用される FISC 基準項目の一覧
- **DR 設計** — RTO/RPO を明示した災害復旧設計
- **閉域ネットワークアーキテクチャ** — Private Endpoint / VNet Integration による閉域構成

### 3. ガバナンスベース IaC テンプレート

標準の ALZ Bicep モジュールは存在しますが、FISC 基準を意識した構成にはなっていません。本リポジトリでは以下を追加しています。

| 追加要素 | 対応 FISC 基準 | 説明 |
|---------|--------------|------|
| FISC Tier 別 Management Group 階層 | 統20 | Tier1〜Tier3 に応じた管理グループ設計 |
| FISC 基準対応 Azure Policy 割当 | 複数基準 | FISC 要件を Azure Policy で自動検出・是正 |
| 730日ログ保持 | 実25 | 法定保存期間に対応した Log Analytics / Storage 保持設定 |
| 日本リージョン限定ポリシー | 統20 | データ所在地を日本国内に制限する Azure Policy |

### 4. AI安全対策基準（FISC第13版 新設）

標準の WAF Security pillar は AI/生成AI に関する FISC 固有の基準に対応していません。本リポジトリでは [AI安全対策](08-ai-safety.md) として以下を追加しています。

| 追加要素 | 対応 FISC 基準 |
|---------|--------------|
| 実150〜実153 の Azure 実装ガイダンス | 実150, 実151, 実152, 実153 |
| Azure AI Foundry / Agent Service の FISC 準拠設計 | 実150〜実153 |
| AI Content Safety / Microsoft Defender for AI 統合 | 実151, 実152 |

### 5. サイバーレジリエンス基盤

標準の CAF には DR ガイダンスが含まれますが、FISC 基準や金融庁ガイドラインに特化した設計は提供されていません。本リポジトリでは以下を追加しています。

- **金融庁オペレーショナル・レジリエンスガイドライン対応** — 重要業務の特定と許容停止時間の設定
- **サイバーインシデント時の証拠保全設計** — イミュータブルログ、フォレンジック用スナップショット
- **隔離されたフォレンジック環境** — インシデント調査用の分離されたサブスクリプション設計
- **イミュータブルバックアップによるランサムウェア対策** — Azure Backup の不変ストレージ活用

### 6. メインフレーム連携・移行

標準の CAF には汎用的な移行ガイダンスがありますが、金融機関のメインフレーム特有の課題には対応していません。本リポジトリでは以下を追加しています。

- **COBOL/PL-I/JCL 資産のリファクタリング戦略** — 段階的な移行アプローチ
- **メインフレーム連携アーキテクチャ** — API Gateway パターンによるハイブリッド連携
- **GitHub Copilot による Code to Doc / Doc to Code** — レガシーコードの理解と移行を支援

### 7. 日本固有要件への対応

標準の CAF/WAF はグローバル向けであり、日本の金融制度固有の要件をカバーしていません。本リポジトリでは以下を追加しています。

- **対外接続** — 全銀ネット、SWIFT、CAFIS 等の金融ネットワークとの接続設計
- **経済安全保障推進法への対応** — 特定社会基盤事業者としての義務への対応
- **コンティンジェンシープラン** — FISC コンティンジェンシープラン策定手引書（第5版）に準拠した設計

---

## Azure Landing Zones (ALZ) との共存

本リポジトリは標準の Azure Landing Zones を**置き換える**ものではなく、**共存して利用する**設計です。

```
┌─────────────────────────────────────────┐
│  標準 ALZ Bicep/Terraform モジュール     │  ← 基盤として利用
│  (Hub-Spoke, Management Group, Policy)  │
├─────────────────────────────────────────┤
│  本リポジトリによる FSI オーバーレイ      │  ← 上乗せ
│  ├── FISC Tier 別 Management Group 拡張 │
│  ├── FSI 固有 Azure Policy 追加         │
│  ├── 17 ワークロード別 LZ 設計          │
│  └── FISC 基準マッピングドキュメント     │
└─────────────────────────────────────────┘
```

- **標準 ALZ** の Bicep/Terraform モジュールを基盤レイヤーとしてそのまま活用可能
- 本リポジトリは FSI 固有のオーバーレイ（Policy、ランディングゾーン設計、FISC マッピング）を追加
- Management Group 階層は ALZ の標準階層を拡張し、FISC Tier 分類を組み込み

---

## 参考リソース

| リソース | リンク |
|---------|-------|
| Azure Cloud Adoption Framework | [learn.microsoft.com/azure/cloud-adoption-framework/](https://learn.microsoft.com/azure/cloud-adoption-framework/) |
| Azure Well-Architected Framework | [learn.microsoft.com/azure/well-architected/](https://learn.microsoft.com/azure/well-architected/) |
| Azure Landing Zones (ALZ) | [learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/) |
| ALZ Bicep モジュール（GitHub） | [github.com/Azure/ALZ-Bicep](https://github.com/Azure/ALZ-Bicep) |
| AWS BLEA for FSI（比較参考） | [github.com/aws-samples/baseline-environment-on-aws-for-financial-services-institute](https://github.com/aws-samples/baseline-environment-on-aws-for-financial-services-institute) |
| FISC 金融情報システムセンター | [fisc.or.jp](https://www.fisc.or.jp/) |

---

## 次のステップ

本リポジトリの主要ドキュメントを以下の順序で参照してください。

1. [README.md](../README.md) — リポジトリ全体の概要と構成
2. [フレームワーク概要](01-overview.md) — FISC × CAF × WAF の統合フレームワーク
3. [FISC基準 → Azure サービスマッピング](../mapping/fisc-to-azure-services.md) — 全324基準の対応表
4. [ワークロード別 FISC 実務基準マッピング](../mapping/fisc-workload-mapping.md) — ランディングゾーンごとの適用要件

---

*本ドキュメントは FISC 安全対策基準・解説書 第13版（2025年3月）に基づいています。*
