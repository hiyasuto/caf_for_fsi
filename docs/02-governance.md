# 02 — ITガバナンス・統制

> FISC統制基準（統1〜統28）→ Azure Governance / Microsoft Entra ID / Azure Policy

## 概要

FISC統制基準は、金融機関等の経営層・管理者が果たすべきITガバナンス・ITマネジメントに関する基準です。Azure上では、Azure Policy、Microsoft Entra ID、Microsoft Defender for Cloud、Azure Management Groups等を活用して、これらの統制要件を実現します。

## 1. 方針・計画（統1〜統3）

### 統1: 安全対策に係る規程の整備

**FISC要件**: システムの安全対策に係る重要事項を定めた規程を整備すること。

**Azure対応**:
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| セキュリティポリシーの定義 | Azure Policy | 組織全体のセキュリティポリシーをコードとして管理 |
| コンプライアンス評価 | Microsoft Defender for Cloud | 規制コンプライアンスダッシュボードで準拠状況を可視化 |
| ポリシーの階層管理 | Management Groups | 組織階層に沿ったポリシーの適用・継承 |

### 統1-1: サイバーセキュリティ基本方針の整備（第13版新設）

**FISC要件**: サイバーセキュリティ対策に関する基本方針を整備すること。

**Azure対応**:
- **Microsoft Defender for Cloud** — セキュリティポスチャ管理（CSPM）で基本方針を定量的に評価
- **Microsoft Sentinel** — サイバーセキュリティの統合監視基盤
- **Azure Policy（規制コンプライアンス）** — 金融業界向けのコンプライアンスイニシアチブ

### 統1-2: サイバーセキュリティ規程等・業務プロセスの整備（第13版新設）

**FISC要件**: サイバーセキュリティ対策に関する規程等及び業務プロセスを整備すること。

**Azure対応**:
- **Azure DevOps / GitHub** — セキュリティ規程のバージョン管理と変更プロセスの管理
- **Microsoft Purview** — データガバナンスと分類ポリシーの一元管理

### 統2: 中長期的システム計画の策定

**FISC要件**: 中長期的視点に立ったシステムの企画・開発・運用に関する計画を策定すること。

**Azure対応**:
- **Azure Cloud Adoption Framework（CAF）** — 戦略（Strategy）・計画（Plan）フェーズに基づくクラウド移行計画の策定
- **Azure Migrate** — 現行システムのアセスメントと移行計画の策定
- **Azure Advisor** — コスト最適化・パフォーマンスに関する推奨事項

### 統3: システム開発計画の整合性確認・承認

**FISC要件**: システム開発計画は中長期システム計画との整合性を確認するとともに、承認を得ること。

**Azure対応**:
- **Azure DevOps Boards** — 開発計画の策定・進捗管理・承認ワークフロー
- **Azure Policy（ガバナンス）** — 開発環境のガードレール設定

## 2. 組織体制（統4〜統19）

### 統4: セキュリティ管理体制の整備

**FISC要件**: セキュリティ管理体制を整備すること。

**Azure対応**:
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| ID・アクセス管理 | Microsoft Entra ID | RBAC による役割ベースアクセス制御 |
| 特権アクセス管理 | Microsoft Entra PIM | JIT（Just-In-Time）特権アクセス |
| セキュリティ態勢評価 | Microsoft Defender for Cloud | セキュアスコアによる態勢評価 |

### 統4-1: サイバーセキュリティ経営資源・人材計画（第13版新設）

**FISC要件**: サイバーセキュリティを管理するための経営資源及び人材に関する計画を策定すること。

**Azure対応**:
- **Microsoft Defender for Cloud（セキュアスコア）** — セキュリティ態勢の定量評価による投資判断
- **Microsoft Learn** — セキュリティ人材育成のための学習コンテンツ
- **Microsoft Entra ID Governance** — アクセス権のライフサイクル管理

### 統4-2: サイバーセキュリティ管理態勢の監視・牽制（第13版新設）

**FISC要件**: サイバーセキュリティ管理態勢の監視及び牽制を行うこと。

**Azure対応**:
- **Microsoft Defender for Cloud** — 継続的なセキュリティ態勢の監視
- **Microsoft Sentinel** — セキュリティインシデントの検知・調査・対応
- **Azure Monitor / Azure Activity Log** — 管理操作の監査ログ

### 統5-1〜統5-5: サイバーセキュリティリスク管理（第13版新設）

| FISC基準 | 要件 | Azure対応 |
|---------|------|----------|
| 統5-1 | 情報資産の適切な管理 | Microsoft Purview（データカタログ・分類）、Microsoft Defender for Cloud（資産インベントリ） |
| 統5-2 | リスクの特定・評価・対応計画 | Microsoft Defender for Cloud（脆弱性評価）、Microsoft Defender 脅威インテリジェンス |
| 統5-3 | 脆弱性管理手続き | Microsoft Defender 脆弱性管理、Azure Update Manager |
| 統5-4 | 演習・訓練 | Microsoft Sentinel（シミュレーション）、Attack Simulation Training |
| 統5-5 | 教育・研修 | Microsoft Learn Security、Security Awareness Training |

### 統6〜統19: その他の組織体制

| FISC基準 | 要件 | Azure対応 |
|---------|------|----------|
| 統6 | システム管理体制 | Azure Management Groups、Azure RBAC |
| 統7 | データ管理体制 | Microsoft Purview、Azure Data Catalog |
| 統8 | ネットワーク管理体制 | Azure Network Watcher、Azure Firewall Manager |
| 統9 | 業務組織の整備 | Microsoft Entra ID（組織構造のモデリング） |
| 統10 | 安全管理組織の整備 | Microsoft Defender for Cloud（セキュリティチーム向けダッシュボード） |
| 統11 | 防犯組織の整備 | 物理セキュリティ（Azure データセンターで対応） |
| 統12 | 各種業務規則の整備 | Azure Policy、Compliance Manager |
| 統13 | セキュリティ遵守状況の確認 | Microsoft Defender for Cloud（規制コンプライアンス） |

## 3. 外部委託管理（統20〜統23）

### 統20: 外部委託の目的・範囲・選定手続き

**FISC要件**: 外部委託を行う場合は、事前に目的、範囲等を明確にするとともに、外部委託先選定の手続きを明確にすること。

**Azure対応**:
- **Azure の認証・認定**: SOC 1/2/3、ISO 27001/27017/27018、PCI DSS等の第三者認証
- **Microsoft Service Trust Portal** — Azureのコンプライアンスレポート・監査報告書の閲覧
- **Azure の SLA**: 各サービスのSLA（99.9%〜99.999%）

### 統21: 安全対策に関する契約

**FISC要件**: 外部委託先と安全対策に関する項目を盛り込んだ契約を締結すること。

**Azure対応**:
- **Microsoft Product Terms / DPA** — データ処理契約（DPA）によるデータ保護義務の明確化
- **Azure のデータ所在地保証** — 日本リージョン（東日本・西日本）でのデータ所在地の保証

### 統23: 外部委託管理体制と遂行状況確認

**FISC要件**: 外部委託における管理体制を整備し、委託業務の遂行状況を確認すること。

**Azure対応**:
- **Azure Service Health** — サービス正常性の監視
- **Azure Monitor** — SLA達成状況の監視・レポート
- **Microsoft Defender for Cloud** — セキュリティ態勢の継続的な評価

## 参考リンク

- [Azure Cloud Adoption Framework — Govern](https://learn.microsoft.com/azure/cloud-adoption-framework/govern/)
- [Azure Policy の概要](https://learn.microsoft.com/azure/governance/policy/overview)
- [Microsoft Entra ID](https://learn.microsoft.com/entra/identity/)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/)
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [03. セキュリティ](03-security.md) | 認証・暗号化・ネットワーク・サイバー対策の技術的実装 |
| → | [07. クラウドガバナンス](07-cloud-governance.md) | クラウド固有リスク・責任分界・Azure Policy ガードレール |
| → | [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md) | 各ランディングゾーンへの FISC 基準適用要件 |