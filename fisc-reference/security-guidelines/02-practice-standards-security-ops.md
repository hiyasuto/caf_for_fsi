---
title: FISC安全対策基準 第13版 — 実務基準 索引（セキュリティ・信頼性・運用）
type: fisc-reference
status: draft
tags: [fisc, practice-standards, security, operations, reliability]
updated: 2026-04-30
---

# FISC安全対策基準 第13版 — 実務基準 索引（実1〜実74）

> **出典・著作権**: 「金融機関等コンピュータシステムの安全対策基準・解説書（第13版）」は公益財団法人 FISC が著作権を保有する有償刊行物です。本ページは章番号・基準番号と本リポジトリ内のAzure対応分析を索引化したもので、FISC原文の転載ではありません。各基準の概要は本リポジトリのAzureマッピング観点で要約したものであり、正式な基準内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## このページの位置づけ

- 実務基準（実1〜実74）のうち、**セキュリティ・信頼性・運用**領域を扱う基準を、FISC文書順（番号順）に索引化
- 各エントリは本リポジトリ `docs/` 配下の詳細分析へのナビゲーションを提供
- 実75以降（システム開発・AI領域）は [`03-practice-standards-development-ai.md`](./03-practice-standards-development-ai.md) を参照

## グループ別 索引

| グループ | 基準範囲 | 主題 | 主な参照先 |
|---|---|---|---|
| セキュリティ | 実1〜実22, 実25〜実30 | 認証・暗号化・ネットワーク・不正プログラム対策 | [docs/03-security.md](../../docs/03-security.md) |
| 運用管理 | 実23〜実24, 実34〜実36, 実46〜実62 | 運用マニュアル・変更管理・設備管理・監視記録 | [docs/05-operations.md](../../docs/05-operations.md) |
| 信頼性 | 実39〜実45, 実71〜実74 | バックアップ・DR・コンティンジェンシー | [docs/04-reliability.md](../../docs/04-reliability.md) |

## 基準別 索引（FISC文書順）

### 実1: 暗証番号・パスワード等の保護
- **概要**: 暗証番号・パスワード等の認証情報を他人に知られないようにする保護対策。
- **Azure対応**: パスワードレス認証、MFA、条件付きアクセス、Key Vault → [docs/03-security.md#実1](../../docs/03-security.md)
- **関連**: → [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md)

### 実2: 暗証番号の盗聴防止
- **概要**: 通信経路における暗証番号の盗聴を防止するための対策。
- **Azure対応**: TLS 1.2/1.3、トークン化、HSM保護、Payment HSM → [docs/03-security.md#実2](../../docs/03-security.md)

### 実3: 蓄積データの漏えい防止
- **概要**: 蓄積（保存）データの漏えいを防止するための暗号化・分類等の対策。
- **Azure対応**: Storage/SQL TDE、CMK、Confidential Computing、Purview DLP → [docs/03-security.md#実3](../../docs/03-security.md)

### 実4: 伝送データの漏えい防止
- **概要**: 通信経路上の伝送データの漏えい防止対策。
- **Azure対応**: TLS、VPN Gateway、ExpressRoute、Private Link → [docs/03-security.md#実4](../../docs/03-security.md)

### 実5: データの破壊・改ざん防止
- **概要**: 蓄積データの破壊・改ざんを防止・検知するための対策。
- **Azure対応**: SQL MI Ledger、Blob WORM、Confidential Ledger、Defender FIM → [docs/03-security.md#実5](../../docs/03-security.md)

### 実6: プログラムの不正使用防止
- **概要**: プログラムの不正な使用・実行を防止するための制御。
- **Azure対応**: RBAC、適応型アプリケーション制御、Defender for Containers、Entra PIM → [docs/03-security.md#実6](../../docs/03-security.md)

### 実7: プログラムの改ざん防止
- **概要**: プログラム本体の改ざんを防止・検知する対策。
- **Azure対応**: コード署名、ブランチ保護、Notation（コンテナ署名）、Defender FIM → [docs/03-security.md#実7](../../docs/03-security.md)

### 実8: 本人確認機能
- **概要**: 利用者の本人確認を行うための機能。
- **Azure対応**: Entra ID、MFA、ID Protection、External ID、Windows Hello → [docs/03-security.md#実8](../../docs/03-security.md)

### 実9: IDの不正使用防止
- **概要**: IDの不正使用を防止するための機能。
- **Azure対応**: ID Protection、アカウントロックアウト、条件付きアクセス、PIM → [docs/03-security.md#実9](../../docs/03-security.md)

### 実10: アクセス履歴の管理
- **概要**: アクセス履歴の取得・保存・検証に関する管理。
- **Azure対応**: Entra Sign-in/Audit Logs、Activity Log、Sentinel、Storage WORM → [docs/03-security.md#実10](../../docs/03-security.md)

### 実11: 出力帳票のアクセス管理
- **概要**: 出力帳票（紙・電子）に対するアクセス管理。
- **Azure対応**: Purview Information Protection、IRM、透かし → [docs/03-security.md#実11](../../docs/03-security.md)

### 実12: 残留データの保護
- **概要**: コンピュータ内に残留する秘密データの保護対策。
- **Azure対応**: Disk Encryption、安全な廃棄、Confidential Computing、一時ディスク消去 → [docs/03-security.md#実12](../../docs/03-security.md)

### 実13: 暗号鍵の保護
- **概要**: 暗号鍵を蓄積する機器・媒体・ソフトウェアの保護機能。
- **Azure対応**: Key Vault、Managed HSM、Payment HSM、Confidential Computing → [docs/03-security.md#実13](../../docs/03-security.md)

### 実14: 不正侵入防止
- **概要**: 外部ネットワークからの不正侵入を防止する対策。
- **Azure対応**: Azure Firewall Premium、WAF、DDoS Protection、VNet/NSG → [docs/03-security.md#実14](../../docs/03-security.md)

### 実14-1: サイバー攻撃端緒の検知・監視（第13版新設）
- **概要**: サイバー攻撃の端緒を早期に検知するための監視・分析対策。
- **Azure対応**: Sentinel、Defender XDR、脅威インテリジェンス連携 → [docs/03-security.md#実14-1](../../docs/03-security.md)

### 実14-2: 脆弱性診断・ペネトレーションテスト（第13版新設）
- **概要**: 脆弱性診断・ペネトレーションテストの計画的実施。
- **Azure対応**: Defender 脆弱性管理、App Service スキャン、ペネトレーションテストルール → [docs/03-security.md#実14-2](../../docs/03-security.md)

### 実15: 接続機器の最小化
- **概要**: 外部からアクセス可能な接続機器を必要最小限に絞る方針。
- **Azure対応**: Private Link/Endpoint、Bastion、API Management → [docs/03-security.md#実15](../../docs/03-security.md)

### 実16: 不正アクセス監視
- **概要**: 不正アクセスを監視する機能の整備。
- **Azure対応**: Sentinel、Defender for Cloud、Azure Monitor アラート → [docs/03-security.md#実16](../../docs/03-security.md)

### 実17: 異常な取引状況の把握
- **概要**: 異常な取引状況をリアルタイムに把握する仕組み。
- **Azure対応**: Stream Analytics、Sentinel ML、Monitor Workbooks → [docs/03-security.md#実17](../../docs/03-security.md)

### 実18: 異例取引の監視
- **概要**: 通常と異なる異例取引の監視・調査。
- **Azure対応**: Sentinel 分析ルール、Monitor アラート、Sentinel インシデント → [docs/03-security.md#実18](../../docs/03-security.md)

### 実19: 不正アクセス対応策・復旧策
- **概要**: 不正アクセス発生時の対応・復旧プロセス。
- **Azure対応**: Sentinel SOAR（Logic Apps）、NSG/Firewall 自動隔離、Disk Snapshot、Backup/ASR → [docs/03-security.md#実19](../../docs/03-security.md)

### 実20: 不正プログラムへの防御対策
- **概要**: ウイルス等の不正プログラム侵入・組込みを防御する多層対策。
- **Azure対応**: Defender for Endpoint/Servers/Containers/Storage、Firewall Premium、Update Manager → [docs/03-security.md#実20](../../docs/03-security.md)

### 実21: 不正プログラムの検知対策
- **概要**: 不正プログラムの検知・通知に関する対策。
- **Azure対応**: Defender for Cloud、Firewall IDS/IPS、Sentinel、Monitor、Threat Intelligence → [docs/03-security.md#実21](../../docs/03-security.md)

### 実22: 不正プログラムによる被害時対策
- **概要**: 不正プログラム感染後の隔離・駆除・復旧の手順整備。
- **Azure対応**: NSG/Firewall 隔離、SOAR 通知、Defender 自動修復、Backup 復旧、Defender XDR Advanced Hunting → [docs/03-security.md#実22](../../docs/03-security.md)

### 実23: 通常時マニュアルの整備
- **概要**: 通常運用時のオペレーションマニュアル整備。
- **Azure対応**: Azure Automation Runbook、Logic Apps、Monitor Workbooks 手順化 → [docs/05-operations.md#実23](../../docs/05-operations.md)

### 実24: 障害時・災害時マニュアルの整備
- **概要**: 障害・災害時の対応マニュアル整備。
- **Azure対応**: Site Recovery 復旧プラン、Sentinel プレイブック、SharePoint 文書管理 → [docs/05-operations.md#実24](../../docs/05-operations.md)

### 実25: アクセス権限の明確化
- **概要**: 各種資源・システムへのアクセス権限の明確化。
- **Azure対応**: Azure RBAC、カスタムロール、PIM、Access Reviews → [docs/03-security.md#実25](../../docs/03-security.md)

### 実26: パスワード保護
- **概要**: パスワード自体を保護するための運用上の措置。
- **Azure対応**: Entra ID パスワード保護、Key Vault、Managed Identity → [docs/03-security.md#実26](../../docs/03-security.md)

### 実27: アクセス権限の付与・見直し
- **概要**: アクセス権限の付与・変更・棚卸しの手続き。
- **Azure対応**: Access Reviews、Entitlement Management、ID Governance → [docs/03-security.md#実27](../../docs/03-security.md)

### 実28: データファイルの授受・管理
- **概要**: データファイル授受・管理に関する手続きの明確化。
- **Azure対応**: Storage SFTP/FTPS、Blob + SAS、ハッシュ検証、診断ログ → [docs/03-security.md#実28](../../docs/03-security.md)

### 実29: 磁気テープ等の外部保管
- **概要**: 媒体の外部保管に関する安全管理措置。
- **Azure対応**: Blob GRS/RA-GRS、不変ストレージ、Archive 層、CMK 暗号化 → [docs/03-security.md#実29](../../docs/03-security.md)

### 実30: 暗号鍵の運用管理
- **概要**: 暗号鍵のライフサイクル運用管理方法の明確化。
- **Azure対応**: Key Vault ローテーション、Managed HSM、Payment HSM、診断ログ → [docs/03-security.md#実30](../../docs/03-security.md)

### 実34: 外部接続の運用管理
- **概要**: 外部接続の構成・利用に関する運用管理。
- **Azure対応**: ExpressRoute、VPN Gateway、Private Link、Firewall ルール管理 → [docs/05-operations.md#実34](../../docs/05-operations.md)

### 実35: ネットワーク構成の管理
- **概要**: ネットワーク構成情報の維持管理。
- **Azure対応**: Network Watcher、Resource Graph、Azure Policy、IaC（Bicep/Terraform） → [docs/05-operations.md#実35](../../docs/05-operations.md)

### 実36: オペレーションの依頼・承認手続き
- **概要**: オペレーション実施に係る依頼・承認の手続き。
- **Azure対応**: PIM 承認ワークフロー、Entitlement Management、ServiceNow/ITSM 連携 → [docs/05-operations.md#実36](../../docs/05-operations.md)

### 実39: データファイルのバックアップ
- **概要**: 業務データファイルのバックアップ確保。
- **Azure対応**: Azure Backup（VM/SQL/File/Blob）、GRS、不変ボールト、SQL PITR → [docs/04-reliability.md#実39](../../docs/04-reliability.md)

### 実40: システムファイルのバックアップ
- **概要**: OS・ミドルウェアなどシステムファイルのバックアップ確保。
- **Azure対応**: VM イメージ、Shared Image Gallery、Automation State Configuration、IaC、ACR → [docs/04-reliability.md#実40](../../docs/04-reliability.md)

### 実41: プログラムファイルのバックアップ
- **概要**: アプリケーションプログラムファイルのバックアップ確保。
- **Azure対応**: Azure DevOps/GitHub、ACR Geo-replication、IaC リポジトリ → [docs/04-reliability.md#実41](../../docs/04-reliability.md)

### 実42: 重要なドキュメントの管理
- **概要**: 重要ドキュメントのバージョン・アクセス管理。
- **Azure対応**: SharePoint Online、Purview Information Protection、Microsoft 365 バックアップ → [docs/04-reliability.md#実42](../../docs/04-reliability.md)

### 実43: バックアップデータの保管管理
- **概要**: バックアップデータの保管・改ざん防止・アクセス管理。
- **Azure対応**: Backup GRS、Immutable Vault、RBAC + Resource Guard（MUA）、CMK → [docs/04-reliability.md#実43](../../docs/04-reliability.md)

### 実44: バックアップのリストアテスト
- **概要**: バックアップからの復元テストの定期実施。
- **Azure対応**: Backup 復元テスト、ASR テストフェイルオーバー、Chaos Studio、Automation Runbook → [docs/04-reliability.md#実44](../../docs/04-reliability.md)

### 実45: ドキュメントのバックアップ
- **概要**: 災害時復旧に必要なドキュメントのバックアップ確保。
- **Azure対応**: SharePoint/OneDrive、Blob GRS、IaC リポジトリ → [docs/04-reliability.md#実45](../../docs/04-reliability.md)

### 実46: 通信回線の管理
- **概要**: 通信回線（WAN/専用線等）の管理。
- **Azure対応**: ExpressRoute、VPN Gateway、Virtual WAN、Network Watcher 監視 → [docs/05-operations.md#実46](../../docs/05-operations.md)

### 実47: 通信機器の管理
- **概要**: ルーター・スイッチ等の通信機器の管理。
- **Azure対応**: Azure Firewall、Application Gateway、Load Balancer、構成バックアップ → [docs/05-operations.md#実47](../../docs/05-operations.md)

### 実48: ハードウェア・ソフトウェアの管理
- **概要**: ハードウェア・ソフトウェア資産の構成管理・棚卸し。
- **Azure対応**: Azure Resource Graph、Azure Policy、Update Manager、ARC（オンプレ統合） → [docs/05-operations.md#実48](../../docs/05-operations.md)

### 実49: ソフトウェアの導入・変更管理
- **概要**: ソフトウェア導入・変更時の承認・記録管理。
- **Azure対応**: Azure DevOps Pipelines、Change Analysis、Policy ガードレール → [docs/05-operations.md#実49](../../docs/05-operations.md)

### 実50: ソフトウェアの棚卸し
- **概要**: 導入済みソフトウェアの棚卸し。
- **Azure対応**: Resource Graph、Defender for Cloud インベントリ、Update Manager → [docs/05-operations.md#実50](../../docs/05-operations.md)

### 実51: 機器の保守
- **概要**: 機器の保守作業に関する管理。
- **Azure対応**: Azure 計画メンテナンス通知、Service Health、PIM 経由保守アクセス → [docs/05-operations.md#実51](../../docs/05-operations.md)

### 実52: 媒体の管理
- **概要**: 記憶媒体の受払・廃棄・保管管理。
- **Azure対応**: Microsoft DC 媒体管理（NIST 800-88 準拠廃棄）、Storage アクセス制御 → [docs/05-operations.md#実52](../../docs/05-operations.md)

### 実53: コンピュータ関連設備の管理
- **概要**: 関連設備（電源・空調・耐震等）の管理。
- **Azure対応**: Microsoft データセンター運用責任（責任共有モデル）、Service Health → [docs/05-operations.md#実53](../../docs/05-operations.md)

### 実54: 電源設備の管理
- **概要**: 電源設備（UPS・自家発電等）の管理。
- **Azure対応**: Microsoft DC 責任、Availability Zones（電源独立）、リージョンペア → [docs/05-operations.md#実54](../../docs/05-operations.md)

### 実55: 空調設備の管理
- **概要**: 空調設備の管理。
- **Azure対応**: Microsoft DC 責任、Availability Zones（冷却独立） → [docs/05-operations.md#実55](../../docs/05-operations.md)

### 実56: 入館（室）の資格付与・鍵管理
- **概要**: 入館（室）資格付与・鍵管理。
- **Azure対応**: Microsoft DC 物理セキュリティ、SOC レポート、コンプライアンス認証 → [docs/05-operations.md#実56](../../docs/05-operations.md)

### 実57: データセンターの入退管理
- **概要**: データセンター入退室の記録・監視。
- **Azure対応**: Microsoft DC 入退記録（CSP責任）、SOC 2 Type II 監査レポート → [docs/05-operations.md#実57](../../docs/05-operations.md)

### 実58: 運用状況の記録・報告
- **概要**: 運用状況の記録・経営層への報告。
- **Azure対応**: Azure Monitor、Workbooks、Cost Management、Service Health → [docs/05-operations.md#実58](../../docs/05-operations.md)

### 実59: 障害の記録・報告
- **概要**: 障害発生・対応経緯の記録・報告。
- **Azure対応**: Service Health、Sentinel インシデント、Monitor アラート履歴 → [docs/05-operations.md#実59](../../docs/05-operations.md)

### 実60: 処理結果の検証
- **概要**: 業務処理結果の正確性検証。
- **Azure対応**: Data Factory データ検証、Stream Analytics、Logic Apps チェック → [docs/05-operations.md#実60](../../docs/05-operations.md)

### 実61: 出力結果の管理
- **概要**: 業務出力（帳票・データ）の管理。
- **Azure対応**: Purview Information Protection、Storage アクセス制御、診断ログ → [docs/05-operations.md#実61](../../docs/05-operations.md)

### 実62: 入出力情報の管理
- **概要**: 入出力情報の取扱い管理。
- **Azure対応**: Storage 診断ログ、Purview データカタログ、DLP → [docs/05-operations.md#実62](../../docs/05-operations.md)

### 実71: 障害時・災害時復旧手順
- **概要**: 障害時・災害時の復旧手順の明確化。
- **Azure対応**: Site Recovery、Availability Zones/Sets、リージョンペア、SQL Auto-failover、Front Door → [docs/04-reliability.md#実71](../../docs/04-reliability.md)

### 実72: 障害時の復旧テスト
- **概要**: 復旧手順の実効性を検証する定期テスト。
- **Azure対応**: ASR テストフェイルオーバー、Chaos Studio、SQL MI 強制フェイルオーバー → [docs/04-reliability.md#実72](../../docs/04-reliability.md)

### 実73: コンティンジェンシープランの策定
- **概要**: コンティンジェンシープラン策定。
- **Azure対応**: 詳細は [docs/12-contingency-plan.md](../../docs/12-contingency-plan.md) を参照 → [docs/04-reliability.md#実73](../../docs/04-reliability.md)

### 実73-1: サイバー攻撃想定のインシデント対応計画（第13版新設）
- **概要**: サイバー攻撃を想定したインシデント対応計画・コンティンジェンシープラン策定。
- **Azure対応**: 詳細は [docs/11-incident-response.md](../../docs/11-incident-response.md) を参照 → [docs/04-reliability.md#実73-1](../../docs/04-reliability.md)

### 実74: バックアップサイトの保有
- **概要**: 災害時に備えた業務優先度に応じたバックアップサイトの保有。
- **Azure対応**: Paired Regions、Availability Zones、ASR、Front Door、SQL geo-replication、GRS/GZRS → [docs/04-reliability.md#実74](../../docs/04-reliability.md)

## 関連リンク

- [安対基準 README](./README.md)
- [docs/03-security.md](../../docs/03-security.md) — セキュリティ詳細マッピング
- [docs/04-reliability.md](../../docs/04-reliability.md) — 信頼性・事業継続詳細マッピング
- [docs/05-operations.md](../../docs/05-operations.md) — 運用詳細マッピング
- [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md) — FISC基準⇔Azureサービス全体マッピング
- [03-practice-standards-development-ai.md](./03-practice-standards-development-ai.md) — 実75以降（システム開発・AI領域）
