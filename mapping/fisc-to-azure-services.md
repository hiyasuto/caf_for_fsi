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

## 実務基準（152項目）

### 技術的安全対策（実1〜実19）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実1 ✏️ | 暗証番号・パスワード等の保護 | 基礎 | Microsoft Entra ID（MFA, パスワードレス, FIDO2） |
| 実2 | 暗証番号の盗聴防止 | 基礎 | TLS 1.2+, Microsoft Entra ID（トークンベース認証）, Azure Payment HSM |
| 実3 ✏️ | 蓄積データの漏えい防止 | 基礎 | Azure Storage暗号化, TDE + CMK, Microsoft Purview DLP, Confidential Computing |
| 実4 ✏️ | 伝送データの漏えい防止 | 基礎 | TLS 1.2+, ExpressRoute（MACsec）, Private Link |
| 実5 | データの破壊・改ざん防止 | 基礎 | 不変ストレージ（WORM）, SQL MI Ledger テーブル, Azure Confidential Ledger |
| 実6 | プログラムの不正使用防止 | 基礎 | Azure RBAC, Defender for Cloud（適応型アプリケーション制御）, Pod Security Standards |
| 実7 | プログラムの改ざん防止 | 基礎 | GitHub（署名付きコミット, ブランチ保護）, コンテナイメージ署名（Notation）, Defender for Cloud FIM |
| 実8 ✏️ | 本人確認機能 | 基礎 | Microsoft Entra ID, MFA, ID Protection（リスクベース認証） |
| 実9 ✏️ | IDの不正使用防止 | 基礎 | Microsoft Entra ID Protection（異常サインイン検知）, 条件付きアクセス |
| 実10 ✏️ | アクセス履歴の管理 | 基礎 | Azure Monitor, Microsoft Sentinel, Log Analytics（1年以上保存） |
| 実11 | 出力帳票のアクセス管理 | 基礎 | Microsoft Purview Information Protection, IRM |
| 実12 | 残留データの保護 | 基礎 | Azure Disk Encryption, Confidential Computing, NIST 800-88準拠消去 |
| 実13 ✏️ | 暗号鍵の保護 | 基礎 | Azure Key Vault Managed HSM（FIPS 140-2 L3）, Payment HSM |
| 実14 ✏️ | 外部ネットワークからの不正侵入防止 | 基礎 | Azure Firewall Premium（IDS/IPS）, WAF, DDoS Protection |
| 実14-1 🆕 | サイバー攻撃端緒の検知・監視 | 基礎 | Microsoft Sentinel, Defender XDR, Network Watcher |
| 実14-2 🆕 | 脆弱性診断・ペネトレーションテスト | 基礎 | Defender 脆弱性管理, Defender for Containers |
| 実15 ✏️ | 接続機器の最小化 | 基礎 | Azure Private Link, Azure Bastion, NSG |
| 実16 ✏️ | 不正アクセスの監視 | 基礎 | Microsoft Sentinel, Defender for Cloud, Azure Monitor |
| 実17 ✏️ | 異常な取引状況の把握 | 基礎 | Microsoft Sentinel, Azure Stream Analytics |
| 実18 ✏️ | 異例取引の監視 | 基礎 | Microsoft Sentinel（カスタム分析ルール）, Stream Analytics |
| 実19 ✏️ | 不正アクセス対応策・復旧策 | 基礎 | Microsoft Sentinel SOAR（Logic Apps プレイブック）, ASR |

### アクセス管理（実20〜実30）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実20 ✏️ | オペレーティングシステムのアクセス制御 | 基礎 | Microsoft Entra ID, Azure RBAC, 条件付きアクセス |
| 実21 ✏️ | データベースのアクセス制御 | 基礎 | Azure SQL（行レベル/列レベルセキュリティ）, Always Encrypted |
| 実22 | ネットワークのアクセス制御 | 基礎 | NSG, Azure Firewall, Private Endpoint |
| 実23 ✏️ | プログラム資源のアクセス制御 | 基礎 | Azure RBAC, GitHub（リポジトリ権限）, ACR アクセス制御 |
| 実24 ✏️ | アクセス制御の一元管理 | 基礎 | Microsoft Entra ID（統合 ID 基盤）, Azure Lighthouse |
| 実25 ✏️ | アクセス権限の明確化 | 基礎 | Azure RBAC, Microsoft Entra PIM |
| 実26 ✏️ | パスワード保護 | 基礎 | Microsoft Entra ID（パスワード保護）, Azure Key Vault, Managed Identity |
| 実27 ✏️ | アクセス権限の付与・見直し | 基礎 | Microsoft Entra Access Reviews, Entitlement Management |
| 実28 ✏️ | データファイルの授受・管理 | 基礎 | Azure Storage（SFTP/FTPS）, SAS トークン, Purview |
| 実29 | 磁気テープ等の外部保管 | 基礎 | Azure Blob Storage（GRS, Archive層）, 不変ストレージ（WORM） |
| 実30 ✏️ | 暗号鍵の運用管理 | 基礎 | Azure Key Vault（ローテーション自動化）, Managed HSM |

### 外部接続管理（実31〜実38）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実31 ✏️ | 外部ネットワーク接続時のセキュリティ方針 | 基礎 | Azure Policy, Azure Firewall, ネットワークセキュリティアーキテクチャ |
| 実32 | 外部ネットワーク接続時の認証 | 基礎 | Microsoft Entra ID（外部 ID 連携）, 証明書認証, MTLS |
| 実33 ✏️ | 外部ネットワーク接続時の暗号化 | 基礎 | ExpressRoute（MACsec）, VPN Gateway（IPsec/IKE）, TLS 1.2+ |
| 実34 ✏️ | 外部接続の運用管理 | 基礎 | Azure ExpressRoute, VPN Gateway, Network Watcher |
| 実35 | ネットワーク構成の管理 | 基礎 | Azure Network Watcher, Azure Activity Log, Bicep/Terraform |
| 実36 ✏️ | オペレーション依頼・承認手続き | 基礎 | Microsoft Entra PIM, Azure DevOps（承認ゲート） |
| 実37 ✏️ | オペレーションの記録・検証 | 基礎 | Azure Activity Log, Azure Monitor, Microsoft Sentinel |
| 実38 | 特権的オペレーションの管理 | 基礎 | Microsoft Entra PIM（JIT）, Break-Glass アカウント, 二人制オペレーション |

### バックアップ（実39〜実45）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実39 ✏️ | データファイルのバックアップ | 基礎 | Azure Backup（Zone/Geo冗長）, 不変ボールト |
| 実40 | システムファイルのバックアップ | 基礎 | Azure VM イメージ（Shared Image Gallery）, IaC（Bicep/Terraform） |
| 実41 ✏️ | プログラムファイルのバックアップ | 基礎 | GitHub/Azure DevOps, ACR Geo-replication |
| 実42 | 重要ドキュメントの管理 | 基礎 | SharePoint Online, Microsoft Purview Information Protection |
| 実43 ✏️ | バックアップデータの保管管理 | 基礎 | Azure Backup（GRS）, Immutable Vault, Resource Guard（MUA） |
| 実44 | バックアップのリストアテスト | 基礎 | Azure Backup 復元テスト, Azure Chaos Studio |
| 実45 ✏️ | ドキュメントのバックアップ | 基礎 | SharePoint Online, Azure Blob Storage（GRS） |

### ハードウェア・ソフトウェア管理（実46〜実55）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実46 | 通信回線の管理 | 基礎 | Azure ExpressRoute モニタリング, VPN Gateway 監視 |
| 実47 | 通信機器の管理 | 基礎 | Azure Network Watcher, Azure Arc, Resource Health |
| 実48 ✏️ | ハードウェア・ソフトウェアの管理 | 基礎 | Azure Resource Graph, Azure Arc, Azure Update Manager |
| 実49 | ソフトウェアの導入・変更管理 | 基礎 | Azure Update Manager, Azure Automation DSC, Azure DevOps |
| 実50 | ソフトウェアの棚卸し | 基礎 | Defender for Cloud（ソフトウェアインベントリ）, Azure Resource Graph |
| 実51 ✏️ | 機器の保守 | 基礎 | Azure Service Health, Azure Advisor, Resource Health |
| 実52 | 媒体の管理 | 基礎 | Azure Managed Disks, Blob Storage, Microsoft Purview |
| 実53 ✏️ | コンピュータ関連設備の管理 | 基礎 | Azure Monitor, Azure Dashboards, Azure Workbooks |
| 実54 | 電源設備の管理 | 基礎 | Azure DC 管理（UPS/非常用発電機/冗長電源）, ISO 27001認証 |
| 実55 | 空調設備の管理 | 基礎 | Azure DC 管理（冗長冷却システム/温湿度管理）, ISO 27001認証 |

### 入退管理（実56〜実57）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実56 ✏️ | 入館（室）の資格付与・鍵管理 | 基礎 | Azure DC 物理セキュリティ（生体認証, マントラップ）, Azure Dedicated Host |
| 実57 ✏️ | データセンターの入退管理 | 基礎 | Azure DC（ISO 27001, SOC 1/2/3認証）, Service Trust Portal |

### 運用管理・監視（実58〜実70）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実58 | 運用状況の記録・報告 | 基礎 | Azure Activity Log, Azure Monitor Workbooks |
| 実59 ✏️ | 障害の記録・報告 | 基礎 | Azure Service Health（RCA）, Microsoft Sentinel インシデント |
| 実60 | 処理結果の検証 | 基礎 | Azure Monitor, Application Insights, Azure Data Factory データ品質 |
| 実61 | 出力結果の管理 | 基礎 | Microsoft Purview Information Protection, Azure Blob Storage |
| 実62 | 入出力情報の管理 | 基礎 | Azure API Management（ログ）, Application Insights |
| 実63 ✏️ | セキュリティに関する定期点検 | 基礎 | Defender for Cloud（セキュアスコア）, Azure Policy コンプライアンス |
| 実64 | コンピュータウイルス対策 | 基礎 | Microsoft Defender for Endpoint, Defender for Cloud, Defender for Containers |
| 実65 | 不正プログラム対策 | 基礎 | Microsoft Defender for Endpoint, 適応型アプリケーション制御 |
| 実66 ✏️ | ソフトウェアのぜい弱性対策 | 基礎 | Azure Update Manager, Defender 脆弱性管理, Dependabot |
| 実67 | 情報セキュリティに係る事象の管理 | 基礎 | Microsoft Sentinel, Defender XDR, Azure Monitor アラート |
| 実68 ✏️ | インシデント対応 | 基礎 | Microsoft Sentinel SOAR, Logic Apps プレイブック |
| 実69 | セキュリティ管理状況の評価 | 基礎 | Defender for Cloud（規制コンプライアンス）, Azure Policy |
| 実70 ✏️ | セキュリティ対策の是正 | 基礎 | Defender for Cloud 推奨事項, Azure Advisor |

### 障害・災害対策（実71〜実74）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実71 ✏️ | 障害時・災害時復旧手順 | 基礎 | Azure Site Recovery, Availability Zones, Failover Group |
| 実72 | 障害時の復旧テスト | 基礎 | Azure Site Recovery テストフェイルオーバー, Azure Chaos Studio |
| 実73 ✏️ | コンティンジェンシープランの策定 | 基礎 | ASR, Azure Backup, Azure Chaos Studio |
| 実73-1 🆕 | サイバー攻撃想定のインシデント対応計画 | 基礎 | Microsoft Sentinel（SOAR）, サイバーレジリエンス LZ |
| 実74 ✏️ | 業務継続計画（BCP）の策定 | 基礎 | Azure Availability Zones, リージョンペア, Azure Front Door |

### 開発・変更管理（実75〜実101）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実75 ✏️ | システムの開発・変更手順 | 基礎 | Azure DevOps, GitHub, Bicep/Terraform |
| 実76 ✏️ | テスト環境の整備 | 基礎 | Azure Dev/Test, Azure Load Testing, App Service スロット |
| 実77 | テスト計画の策定 | 基礎 | Azure DevOps Test Plans, GitHub Actions |
| 実78 | 単体テスト・結合テストの実施 | 基礎 | GitHub Actions（CI）, Azure Dev/Test 環境 |
| 実79 | システムテストの実施 | 基礎 | Azure Dev/Test 環境, Azure Load Testing |
| 実80 | 受入テストの実施 | 基礎 | Azure App Service スロット, Azure DevOps Test Plans |
| 実81 | 回帰テストの実施 | 基礎 | GitHub Actions（自動回帰テスト）, Azure Load Testing |
| 実82 | テスト結果の検証 | 基礎 | Azure DevOps Test Plans（レビュー・承認ワークフロー） |
| 実83 ✏️ | テスト環境と本番環境の分離 | 基礎 | Azure サブスクリプション分離, Azure Policy ガードレール |
| 実84 | テストデータの管理 | 基礎 | Azure SQL Dynamic Data Masking, テストデータ生成ツール |
| 実85 | 本番移行手順の策定 | 基礎 | GitHub Actions（Blue-Green / Canary デプロイ）, Azure Pipelines |
| 実86 | 本番移行後の確認 | 基礎 | Azure Monitor, Application Insights（ヘルスチェック） |
| 実87 | ロールバック手順の策定 | 基礎 | App Service スロットスワップ, AKS ロールバック, IaC |
| 実88 | 緊急変更の管理 | 基礎 | Microsoft Entra PIM（緊急アクセス）, Azure DevOps 緊急変更ワークフロー |
| 実89 ✏️ | セキュリティ機能の取込み | 基礎 | GitHub Advanced Security, CodeQL, Microsoft Security DevOps |
| 実90 ✏️ | 設計段階のソフトウェア品質確保 | 基礎 | Azure DevOps Boards, Pull Request レビュー, SonarQube |
| 実91 | 設計書の管理 | 基礎 | Azure DevOps Wiki, SharePoint（バージョン管理） |
| 実92 | 開発標準の策定 | 基礎 | GitHub リポジトリテンプレート, CODEOWNERS |
| 実93 | ソースコードの管理 | 基礎 | GitHub（署名付きコミット, ブランチ保護, CODEOWNERS） |
| 実94 ✏️ | パッケージ導入時の品質確保 | 基礎 | Dependabot, GitHub Advisory, Azure Artifacts, SBOM |
| 実95 | 運用テストの実施 | 基礎 | Azure Chaos Studio（障害注入テスト） |
| 実96 | 性能基準の設定 | 基礎 | Azure Monitor（SLI/SLO）, Application Insights |
| 実97 | 品質メトリクスの管理 | 基礎 | SonarQube, Azure DevOps（品質ゲート, コードカバレッジ） |
| 実98 | 不具合管理 | 基礎 | GitHub Issues, Azure DevOps Boards |
| 実99 | リリース管理 | 基礎 | GitHub Releases, Azure Pipelines |
| 実100 | 変更影響分析 | 基礎 | Azure Monitor Change Analysis |
| 実101 ✏️ | 負荷状態の監視制御 | 基礎 | Azure Monitor, Application Insights, Autoscale |

### ダイレクトチャネル・ATM 固有基準（実102〜実121）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実102 ✏️ | インターネットサービスの安全対策方針 | 基礎 | Azure Policy, Azure Front Door WAF, DDoS Protection |
| 実103 | インターネットサービスの認証 | 基礎 | Microsoft Entra ID（MFA, パスキー, FIDO2） |
| 実104 ✏️ | インターネットサービスの暗号化 | 基礎 | TLS 1.3, Azure Front Door（HTTPS 強制） |
| 実105 | インターネットサービスのセッション管理 | 基礎 | Microsoft Entra ID（セッションポリシー）, Azure Cache for Redis |
| 実106 ✏️ | インターネットサービスのログ管理 | 基礎 | Azure Monitor, Application Insights, Microsoft Sentinel |
| 実107 | カードの管理方法 | 基礎 | Azure Key Vault, Azure Payment HSM（マスターキー保管） |
| 実108 | カード取引犯罪の注意喚起 | 基礎 | IoT Hub（D2C メッセージ）, ATM 画面表示 |
| 実109 | ICカード利用促進 | 基礎 | Azure Payment HSM（ARQC/ARPC 検証） |
| 実110 ✏️ | カード取引監視 | 基礎 | Azure Stream Analytics, Microsoft Sentinel |
| 実111 | （欠番/予備） | — | — |
| 実112 ✏️ | 不正使用の防止 | 基礎 | Entra ID（MFA, リスクベース認証）, Bot Protection |
| 実113 | 利用状況の確認手段 | 基礎 | Application Insights, ログイン・取引履歴 |
| 実114 | （欠番/予備） | — | — |
| 実115 ✏️ | 顧客対応方法の明確化 | 基礎 | Azure Bot Service, Azure Communication Services |
| 実116 | （欠番/予備） | — | — |
| 実117 ✏️ | オンライン口座開設の本人確認 | 基礎 | Azure AI Document Intelligence, Face API（eKYC） |
| 実118 | （欠番/予備） | — | — |
| 実119 | ATMコーナー運用管理 | 基礎 | Azure Payment HSM（PIN検証/翻訳）, AKS 取引認可 |
| 実120 ✏️ | 不正払戻し等の防止 | 基礎 | Stream Analytics（MATCH_RECOGNIZE）, 自動ブロック |
| 実121 | ATMコーナー防犯体制 | 基礎 | IoT Hub（監視カメラ連携）, 異常検知イベント |

### AI安全対策（実150〜実153）

| 基準番号 | 基準小項目 | 分類 | 主なAzureサービス |
|---------|----------|------|-----------------|
| 実150 🆕 | AIの利用に係る方針策定・態勢整備 | 基礎 | Azure Policy, Azure AI Content Safety, Responsible AI ダッシュボード |
| 実151 🆕 | AIの適切な運用管理方法 | 基礎 | Azure AI Foundry, Azure Machine Learning（モデルレジストリ） |
| 実152 🆕 | AIに係る安全対策 | 基礎 | Azure AI Content Safety（Prompt Shields）, Defender for AI |
| 実153 🆕 | AIの利用に係る教育・注意喚起 | 基礎 | Microsoft Learn |

> **Note**: 実務基準の番号体系において、実111, 実114, 実116, 実118, 実122〜実149 等は FISC 第13版では欠番または予備番号です。上記は実際に定義されている基準項目を網羅しています。

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
