# FISC安全対策基準 → Azureサービス マッピング表

> FISC安全対策基準・解説書 第13版（2025年3月）全324基準項目のAzureサービスマッピング

## 凡例

- 🆕 第13版で新設された基準
- ✏️ 第13版で変更された基準

---

## 統制基準（36項目）

### 1. 内部の統制

#### (1) 方針・計画

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 統1 ✏️ | システムの安全対策に係る重要事項を定めた規程を整備すること | 基礎 | Azure Policy, Microsoft Defender for Cloud |
| 統1-1 🆕 | サイバーセキュリティ対策に関する基本方針を整備すること | 基礎 | Microsoft Defender for Cloud, Microsoft Sentinel |
| 統1-2 🆕 | サイバーセキュリティ対策に関する規程等及び業務プロセスを整備すること | 基礎 | Azure DevOps, Microsoft Purview |
| 統2 ✏️ | 中長期的視点に立ったシステムの企画・開発・運用に関する計画を策定すること | 基礎 | Azure CAF, Azure Migrate, Azure Advisor |
| 統3 ✏️ | システム開発計画は中長期システム計画との整合性を確認するとともに承認を得ること | 基礎 | Azure DevOps Boards |

#### (2) 組織体制

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 統4 ✏️ | セキュリティ管理体制を整備すること | 基礎 | Microsoft Entra ID, Microsoft Entra PIM |
| 統4-1 🆕 | サイバーセキュリティを管理するための経営資源及び人材に関する計画を策定すること | 基礎 | Microsoft Defender for Cloud（セキュアスコア） |
| 統4-2 🆕 | サイバーセキュリティ管理態勢の監視及び牽制を行うこと | 基礎 | Microsoft Defender for Cloud, Microsoft Sentinel |
| 統5 | （欠番） | — | — |
| 統5-1 🆕 | サイバーセキュリティリスクを特定するため情報資産を適切に管理すること | 基礎 | Microsoft Purview, Defender for Cloud（資産インベントリ） |
| 統5-2 🆕 | サイバーセキュリティリスクの特定・評価及びリスク対応計画を策定すること | 基礎 | Microsoft Defender 脆弱性管理 |
| 統5-3 🆕 | ハードウェア・ソフトウェア等の脆弱性管理に関する手続き等を策定すること | 基礎 | Azure Update Manager, Defender 脆弱性管理 |
| 統5-4 🆕 | サイバーセキュリティに関する演習・訓練を行うこと | 基礎 | Attack Simulation Training, Azure Chaos Studio |
| 統5-5 🆕 | サイバーセキュリティに係る教育・研修を行うこと | 基礎 | Microsoft Learn |
| 統6 | システム管理体制を整備すること | 基礎 | Azure Management Groups, Azure RBAC |
| 統7 ✏️ | データ管理体制を整備すること | 基礎 | Microsoft Purview |
| 統8 | ネットワーク管理体制を整備すること | 基礎 | Azure Network Watcher |
| 統9 | 業務組織を整備すること | 基礎 | Microsoft Entra ID |
| 統10 | 安全管理組織を整備すること | 基礎 | Microsoft Defender for Cloud |
| 統11 ✏️ | 防犯組織を整備すること | 基礎 | Azure データセンター物理セキュリティ |
| 統12 ✏️ | 各種業務の規則を整備すること | 基礎 | Azure Policy, Compliance Manager |
| 統13 ✏️ | セキュリティ遵守状況を確認すること | 基礎 | Defender for Cloud（規制コンプライアンス） |
| 統14 | システム運用に関する計画を策定すること | 基礎 | Azure Monitor, Azure Automation |
| 統15 | システムのセキュリティ要件を明確にすること | 基礎 | Azure Policy, Microsoft Defender for Cloud |
| 統16 | 情報セキュリティに係る教育・研修を行うこと | 基礎 | Microsoft Learn, Security Awareness Training |
| 統17 | 要員管理を行うこと | 基礎 | Microsoft Entra ID Governance |
| 統18 | 業務の委託を行う場合はセキュリティに関する事項を明確にすること | 基礎 | Microsoft Service Trust Portal |
| 統19 ✏️ | 要員の健康管理を行うこと | 基礎 | — (組織管理) |

#### (3) 外部の統制

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 統20 ✏️ | 外部委託の目的・範囲等の明確化、委託先選定手続き | 基礎 | Azure認証・認定（SOC, ISO等） |
| 統21 ✏️ | 外部委託先と安全対策に関する契約を締結すること | 基礎 | Microsoft Product Terms, DPA |
| 統22 | 外部委託先の再委託管理 | 基礎 | Microsoft サブプロセッサーリスト |
| 統23 ✏️ | 外部委託における管理体制の整備と遂行状況確認 | 基礎 | Azure Service Health, Azure Monitor |
| 統24 ✏️ | クラウドサービス固有のリスクを考慮した安全対策 | 基礎 | 責任共有モデル, Azure Policy, Private Link |
| 統25 | FinTech企業等との連携に係る安全対策 | 基礎 | Azure API Management, Microsoft Entra External ID |
| 統26 | FinTech企業等が提供するサービスの安全性確認 | 基礎 | Microsoft Defender for Cloud Apps |
| 統27 | FinTech企業等との関係における利用者保護 | 基礎 | Azure Front Door（WAF） |
| 統28 🆕 | サプライチェーンを考慮したサイバーセキュリティリスク管理 | 基礎 | GitHub Advanced Security, Defender for Cloud CSPM |

---

## 実務基準（152項目） — 主要項目抜粋

### 技術的安全対策

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実1 ✏️ | 暗証番号・パスワード等の保護 | 基礎 | Microsoft Entra ID（MFA, パスワードレス） |
| 実2 | 暗証番号の安全管理 | 基礎 | Azure Key Vault |
| 実3 ✏️ | 蓄積データの漏えい防止 | 基礎 | Azure Storage暗号化, TDE, Microsoft Purview |
| 実4 ✏️ | 伝送データの漏えい防止 | 基礎 | TLS 1.2+, ExpressRoute, Private Link |
| 実5 | データの破壊・改ざん防止 | 基礎 | 不変ストレージ, Azure Backup |
| 実6 | プログラムの不正使用防止 | 基礎 | Azure RBAC, Microsoft Defender for Cloud |
| 実7 | プログラムの改ざん防止 | 基礎 | Azure DevOps（ブランチポリシー）, コード署名 |
| 実8 ✏️ | 本人確認機能 | 基礎 | Microsoft Entra ID, MFA, ID Protection |
| 実9 ✏️ | IDの不正使用防止 | 基礎 | Microsoft Entra ID Protection |
| 実10 ✏️ | アクセス履歴の管理 | 基礎 | Azure Monitor, Microsoft Sentinel |
| 実11 | 出力帳票のアクセス管理 | 基礎 | Microsoft Purview Information Protection |
| 実12 | 残留データの保護 | 基礎 | Azure Disk（安全な消去） |
| 実13 ✏️ | 暗号鍵の保護 | 基礎 | Azure Key Vault, Managed HSM, Payment HSM |
| 実14 ✏️ | 外部ネットワークからの不正侵入防止 | 基礎 | Azure Firewall, WAF, DDoS Protection |
| 実14-1 🆕 | サイバー攻撃端緒の検知・監視 | 基礎 | Microsoft Sentinel, Defender XDR |
| 実14-2 🆕 | 脆弱性診断・ペネトレーションテスト | 基礎 | Defender 脆弱性管理 |
| 実15 ✏️ | 接続機器の最小化 | 基礎 | Azure Private Link, Azure Bastion |
| 実16 ✏️ | 不正アクセスの監視 | 基礎 | Microsoft Sentinel, Defender for Cloud |
| 実17 ✏️ | 異常な取引状況の把握 | 基礎 | Microsoft Sentinel（カスタム検出ルール） |
| 実18 ✏️ | 異例取引の監視 | 基礎 | Microsoft Sentinel, Azure Stream Analytics |
| 実19 ✏️ | 不正アクセス対応策・復旧策 | 基礎 | Microsoft Sentinel（SOAR）, ASR |

### 運用管理

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実25 ✏️ | アクセス権限の明確化 | 基礎 | Azure RBAC, Microsoft Entra PIM |
| 実26 ✏️ | パスワード保護 | 基礎 | Microsoft Entra ID, Azure Key Vault |
| 実27 ✏️ | アクセス権限の付与・見直し | 基礎 | Microsoft Entra Access Reviews |
| 実28 ✏️ | データファイルの授受・管理 | 基礎 | Azure Storage, Microsoft Purview |
| 実30 ✏️ | 暗号鍵の運用管理 | 基礎 | Azure Key Vault |
| 実34 ✏️ | 外部接続の運用管理 | 基礎 | Azure ExpressRoute, VPN Gateway |
| 実36 ✏️ | オペレーション依頼・承認手続き | 基礎 | Microsoft Entra PIM, Azure DevOps |
| 実39 ✏️ | データファイルのバックアップ | 基礎 | Azure Backup, GRS |
| 実41 ✏️ | プログラムファイルのバックアップ | 基礎 | GitHub/Azure DevOps, ACR Geo-replication |
| 実45 ✏️ | ドキュメントのバックアップ | 基礎 | SharePoint Online, Azure Blob Storage |
| 実48 ✏️ | ハードウェア・ソフトウェアの管理 | 基礎 | Azure Resource Graph, Azure Arc |
| 実51 ✏️ | 機器の保守 | 基礎 | Azure Service Health, Azure Advisor |
| 実53 ✏️ | コンピュータ関連設備の管理 | 基礎 | Azure Monitor |
| 実56 ✏️ | 入館（室）の資格付与・鍵管理 | 基礎 | Azure DC 物理セキュリティ |
| 実57 ✏️ | データセンターの入退管理 | 基礎 | Azure DC（ISO 27001, SOC認証） |

### 障害・災害対策

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実71 ✏️ | 障害時・災害時復旧手順 | 基礎 | Azure Site Recovery, Availability Zones |
| 実73 ✏️ | コンティンジェンシープランの策定 | 基礎 | ASR, Azure Backup, Azure Chaos Studio |
| 実73-1 🆕 | サイバー攻撃想定のインシデント対応計画 | 基礎 | Microsoft Sentinel（SOAR） |

### 開発・変更管理

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実75 ✏️ | システムの開発・変更手順 | 基礎 | Azure DevOps, GitHub |
| 実76 ✏️ | テスト環境の整備 | 基礎 | Azure Dev/Test, Azure Load Testing |
| 実89 ✏️ | セキュリティ機能の取込み | 基礎 | GitHub Advanced Security, CodeQL |
| 実90 ✏️ | 設計段階のソフトウェア品質確保 | 基礎 | Azure DevOps Boards |
| 実94 ✏️ | パッケージ導入時の品質確保 | 基礎 | Dependabot, Azure Artifacts |
| 実101 ✏️ | 負荷状態の監視制御 | 基礎 | Azure Monitor, Application Insights, Autoscale |

### AI安全対策

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実150 🆕 | AIの利用に係る方針策定・態勢整備 | 基礎 | Azure Policy, Azure AI Content Safety |
| 実151 🆕 | AIの適切な運用管理方法 | 基礎 | Azure Machine Learning, Azure AI Foundry |
| 実152 🆕 | AIに係る安全対策 | 基礎 | Azure AI Content Safety, Azure OpenAI |
| 実153 🆕 | AIの利用に係る教育・注意喚起 | 基礎 | Microsoft Learn |

---

## 設備基準（134項目） — クラウドでの対応

設備基準は主に物理的なデータセンター・営業店等に関する基準です。Azure利用時は以下のように対応します：

| 区分 | FISC設備基準 | Azure対応 |
|-----|-------------|----------|
| データセンター立地 | 設1: 災害・障害が発生しやすい地域を避ける | Azure日本リージョンは地理的リスクを考慮して設計 |
| 建物構造 | 設2〜設14: 耐震・防火・防水等 | Microsoftデータセンターが対応（SOC 2/ISO 27001認証） |
| 侵入防止 | 設15〜設16: 不法侵入防止 | Azure DCの多層物理セキュリティ |
| 電源設備 | 設20〜設40: 電源・空調・UPS | Azure DCの冗長電源・冷却システム |
| 通信設備 | 設50〜設70: 通信回線・機器 | Azure ネットワークインフラ |
| 営業店 | 設80〜設100: 営業店の安全対策 | 顧客責任（オンプレミス設備） |
| ATM | 設110〜設138: ATM関連 | 顧客責任（オンプレミス設備） |

> **Note**: Azure利用時、データセンター関連の設備基準（設1〜設70相当）はMicrosoftの責任範囲として、第三者認証（SOC 2 Type II、ISO 27001等）により充足されます。営業店・ATM等の顧客施設に関する設備基準は引き続き顧客の責任範囲です。

---

## 監査基準（2項目）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 監1 | システム監査の実施 | 基礎 | Defender for Cloud, Azure Policy, Service Trust Portal |
| 監1-1 🆕 | サイバーセキュリティを対象とした内部監査 | 基礎 | Defender for Cloud CSPM, Microsoft Sentinel |
