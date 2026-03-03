# 05 — 運用管理

> FISC実務基準（実23〜実24, 実34〜実62）→ Azure Operational Excellence

## 概要

FISC実務基準における運用管理要件を、Azure WAFの**オペレーショナルエクセレンスの柱**に基づいて実現します。マニュアルの整備、システム運用、アクセス管理、設備管理、外部接続管理をカバーします。

## 1. マニュアルの整備（実23〜実24）

FISC第13版「システム運用共通 (1) マニュアルの整備」に対応し、通常時および障害時・災害時のマニュアルをAzure環境で整備・管理します。

### 実23: 通常時マニュアルの整備

**FISC要件**: コンピュータシステムを正確かつ安全に運用するため、通常時における各種手順（含む操作手順）を定めたマニュアルを整備すること。

| マニュアル区分 | Azureサービス | 説明 |
|-------------|-------------|------|
| マニュアル管理基盤 | Azure DevOps Wiki / SharePoint | バージョン管理付きマニュアルの一元管理・改訂履歴の追跡 |
| インフラ構成手順 | IaCテンプレート（Bicep / Terraform） | インフラ操作手順のコード化による正確性担保 |
| 運用手順の自動化 | Azure Automation Runbook | 定型オペレーションの自動化・手順のスクリプト化 |
| 監視手順 | Azure Monitor Workbooks | 運用監視ダッシュボード・アラート対応手順の可視化 |
| 変更管理通知 | Azure DevOps パイプライン | マニュアル更新時の関連部門への自動通知・承認ワークフロー |

> **クラウド固有の留意事項**: クラウド事業者の管理インタフェースにはGUI（Azure Portal）とCLI（Azure CLI / PowerShell）の2方式があります。GUIは画面変更が頻繁なため定期的にマニュアルを更新し、CLIはコマンドベースで変更頻度は少ないもののスクリプト化による操作簡略化を検討します。業務アプリケーション変更だけでなく、クラウド管理機能の変更も把握し適宜マニュアルを改訂することが必要です。

### 実24: 障害時・災害時マニュアルの整備

**FISC要件**: 障害・災害によるシステムへの影響の極小化と早期復旧のため、障害時・災害時における代替措置、復旧手順及び対応方法等について定めたマニュアルを整備すること。

| マニュアル区分 | Azureサービス | 説明 |
|-------------|-------------|------|
| 障害対応手順書 | Azure DevOps Wiki | 障害パターン別の対応フロー・エスカレーション手順 |
| 復旧手順の自動化 | Azure Automation / Site Recovery | 復旧手順のRunbook化・フェールオーバー手順の自動化 |
| 障害訓練記録 | SharePoint / Azure DevOps | 訓練実施記録・改善点の追跡管理 |
| CP連携 | Azure DevOps Boards | コンティンジェンシープランとの整合性管理・定期見直しタスク |

> **コンティンジェンシープランとの整合**: 障害時・災害時マニュアルはコンティンジェンシープラン（[12. コンティンジェンシープラン](12-contingency-plan.md)）と整合性を保つことが必要です。また、経験の浅い要員でも理解できるよう作業手順を明確にし、Azure Automation Runbookによる自動化で人的ミスを最小化します。

## 2. 外部接続管理（実34）

### 実34: 外部接続の運用管理

**FISC要件**: 外部接続における運用管理方法を明確にすること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 接続制御 | Azure ExpressRoute | 専用線接続による安全な外部接続 |
| VPN管理 | Azure VPN Gateway | サイト間VPN・ポイント対サイトVPNの管理 |
| APIゲートウェイ | Azure API Management | 外部API接続の一元管理・認証・レート制限 |
| ネットワーク監視 | Azure Network Watcher | 接続状態・トラフィックの監視 |

## 3. オペレーション管理（実36）

### 実36: オペレーションの依頼・承認手続き

**FISC要件**: オペレーションの依頼・承認手続きを明確にすること。

**Azure対応**:
- **Microsoft Entra PIM** — 特権操作のJust-In-Time承認ワークフロー
- **Azure DevOps（承認ゲート）** — デプロイ前の承認プロセス
- **Azure Activity Log** — すべての管理操作の監査証跡
- **Azure Policy（Deny効果）** — 未承認リソース作成の防止

## 4. 回線管理・データ授受（実35, 実46〜実47）

### 実35: ネットワーク構成の管理
**FISC要件**: ネットワーク構成の変更管理を行うこと。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 構成管理 | Azure Network Watcher | ネットワークトポロジの可視化・変更検知 |
| 変更管理 | Azure Activity Log | ネットワーク構成変更の監査ログ |
| 構成のコード化 | Bicep / Terraform | ネットワーク構成の IaC 管理 |
| ポリシー適用 | Azure Policy | ネットワーク設定のガードレール（パブリック IP 制限等） |

### 実46: 通信回線の管理
**FISC要件**: 通信回線の管理を行うこと。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 回線監視 | Azure ExpressRoute モニタリング | 専用回線の稼働状況・パフォーマンス監視 |
| 冗長化 | ExpressRoute 2回線構成 | Active-Active 冗長による可用性確保 |
| VPN 管理 | Azure VPN Gateway | サイト間 VPN の監視・管理 |
| 帯域監視 | Azure Monitor（ネットワークメトリクス） | 帯域使用率の監視・アラート |

### 実47: 通信機器の管理
**FISC要件**: 通信に使用する機器の管理を行うこと。
**Azure対応**:
- **Azure Network Watcher** — 仮想ネットワーク機器（Azure Firewall / VPN GW / Application GW）の監視
- **Azure Arc** — ハイブリッド環境のネットワーク機器の一元管理
- **Azure Resource Health** — ネットワーク機器の正常性監視
- **Azure Update Manager** — NVA（Network Virtual Appliance）のパッチ管理

## 5. バックアップ管理（実39〜実45）

→ [04-reliability.md](04-reliability.md) を参照

## 6. ハードウェア・ソフトウェア管理（実48〜実53）

### 実48: ハードウェア・ソフトウェアの管理

**FISC要件**: ハードウェア及びソフトウェアの管理を行うこと。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 資産管理 | Azure Resource Graph | 全Azure リソースのインベントリ・クエリ |
| 構成管理 | Azure Automation / Azure Arc | ハイブリッド環境の構成管理 |
| パッチ管理 | Azure Update Manager | OS・ソフトウェアのパッチ適用自動化 |
| ソフトウェアインベントリ | Microsoft Defender for Cloud | インストール済みソフトウェアの検出 |

### 実51: 機器の保守

**FISC要件**: 機器の保守方法を明確にすること。

**Azure対応**:
- **Azure Service Health** — Azureインフラの計画メンテナンス通知
- **Azure Resource Health** — 個別リソースの正常性監視
- **Azure Advisor** — パフォーマンス・信頼性に関する推奨事項

### 実53: コンピュータ関連設備の管理

**FISC要件**: コンピュータ関連設備の管理方法を明確にすること。

**Azure対応（PaaS/IaaS）**:
- **Azure Monitor** — メトリクス・ログの統合監視
- **Azure Dashboards** — 運用ダッシュボードの構築
- **Azure Workbooks** — カスタムレポートの作成

## 7. ソフトウェア・媒体管理（実49〜実50, 実52, 実54〜実55）

### 実49: ソフトウェアの導入・変更管理
**FISC要件**: ソフトウェアの導入・変更の管理を行うこと。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 変更管理 | Azure DevOps / GitHub | ソフトウェア変更のバージョン管理・承認ワークフロー |
| パッチ管理 | Azure Update Manager | OS・ミドルウェアのパッチ適用自動化 |
| 構成管理 | Azure Automation DSC | サーバー構成の宣言的管理・ドリフト検知 |
| テスト | Azure Dev/Test 環境 | 変更適用前のテスト環境での検証 |

### 実50: ソフトウェアの棚卸し
**FISC要件**: ソフトウェアの棚卸しを定期的に実施すること。
**Azure対応**:
- **Microsoft Defender for Cloud（ソフトウェアインベントリ）** — インストール済みソフトウェアの自動検出
- **Azure Resource Graph** — Azure リソースの棚卸しクエリ
- **Azure Arc** — ハイブリッド環境のソフトウェアインベントリ

### 実52: 媒体の管理
**FISC要件**: 磁気テープ・ディスク等の媒体の管理を行うこと。
**Azure対応**:
- **Azure Managed Disks** — ディスクのライフサイクル管理・暗号化
- **Azure Blob Storage** — データの保存・分類・アクセス制御
- **Microsoft Purview** — データ資産のカタログ化・分類・ガバナンス
- **Azure ディスクの安全な廃棄** — NIST 800-88 準拠のデータ消去

### 実54: 電源設備の管理
**FISC要件**: 電源設備の管理を行うこと。
**Azure対応**:
- Azure データセンターの電源設備は Microsoft が管理（UPS / 非常用発電機 / 冗長電源）
- **Azure Service Health** — データセンター電源関連のインシデント通知
- ISO 27001 / SOC 2 認証で電源設備管理の適切性を証明

### 実55: 空調設備の管理
**FISC要件**: 空調設備の管理を行うこと。
**Azure対応**:
- Azure データセンターの空調設備は Microsoft が管理（冗長冷却システム / 温湿度管理）
- **Azure Service Health** — データセンター空調関連のインシデント通知
- ISO 27001 / SOC 2 認証で空調設備管理の適切性を証明

## 8. 入退管理・物理セキュリティ（実56〜実57）

### 実56: 入館（室）の資格付与・鍵管理

**FISC要件**: 入館(室)の資格付与及び鍵の管理を行うこと。

**Azure対応**:
- **Azure データセンターの物理セキュリティ** — Microsoft管理による多層物理セキュリティ
  - 生体認証、多要素認証、マントラップ、24時間365日有人監視
- **Azure Dedicated Host** — 専用物理ホストの利用（ハードウェア分離）

### 実57: データセンターの入退管理

**FISC要件**: データセンターの入退管理を行うこと。

**Azure対応**:
- Azureデータセンターは ISO 27001、SOC 1/2/3 認証を取得済み
- 物理アクセスは Microsoft が管理（顧客の直接アクセスは不可）
- **Microsoft Service Trust Portal** で監査報告書を確認可能

## 9. 運用監視・報告（実58〜実62）

### 実58: 運用状況の記録・報告
**FISC要件**: 運用状況の記録及び報告を行うこと。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 運用ログ | Azure Activity Log | 全管理操作の自動記録 |
| 運用レポート | Azure Monitor Workbooks | 定期運用レポートの自動生成 |
| SLA 報告 | Azure Service Health + Monitor | SLA 達成状況のダッシュボード |

### 実59: 障害の記録・報告
**FISC要件**: 障害の記録及び報告を行うこと。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 障害記録 | Azure Service Health | Azure 側障害の記録・根本原因分析（RCA） |
| インシデント管理 | Microsoft Sentinel インシデント | セキュリティインシデントの記録・追跡 |
| 障害通知 | Azure Monitor アラート | 障害発生時の自動通知（Teams / メール / SMS） |
| 事後分析 | Azure Monitor（変更分析） | 障害原因の変更追跡・分析 |

> **詳細**: インシデントの分類・重大度判定、対応プロセス、エスカレーションフロー、報告フローの詳細は [11. インシデント対応計画](11-incident-response.md) を参照してください。

### 実60: 処理結果の検証
**FISC要件**: 処理結果の検証を行うこと。
**Azure対応**:
- **Azure Monitor / Application Insights** — バッチ処理・トランザクション処理の成功率監視
- **Azure Data Factory（データ品質ルール）** — ETL 処理結果の自動検証
- **Azure Logic Apps** — 処理結果の自動検証ワークフロー

### 実61: 出力結果の管理
**FISC要件**: 出力結果の管理を行うこと。
**Azure対応**:
- **Microsoft Purview Information Protection** — 出力帳票の機密度ラベル付与
- **Azure Blob Storage** — 出力結果の安全な保管（暗号化 + アクセス制御）
- **監査ログ** — 出力結果へのアクセスログの記録

### 実62: 入出力情報の管理
**FISC要件**: 入出力情報の管理を行うこと。
**Azure対応**:
- **Azure API Management** — API 入出力のログ記録・バリデーション
- **Application Insights** — リクエスト/レスポンスのトレーシング
- **Azure Monitor** — 入出力データ量の監視

## 10. 包括的運用監視

### 包括的な運用監視体制

```
┌─────────────────────────────────────────────┐
│              Azure Monitor                   │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ メトリクス  │  │  ログ     │  │ アラート   │  │
│  │           │  │           │  │           │  │
│  │ VM/DB/App │  │ Activity  │  │ アクション  │  │
│  │ パフォーマ │  │ Diagnostic│  │ グループ   │  │
│  │  ンス      │  │ Custom    │  │           │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│        │            │            │          │
│        ▼            ▼            ▼          │
│  ┌──────────────────────────────────┐       │
│  │    Log Analytics Workspace       │       │
│  │    (KQL によるクエリ・分析)        │       │
│  └──────────────────────────────────┘       │
│        │                                    │
│   ┌────┴────┐                               │
│   ▼         ▼                               │
│ Dashboards  Workbooks                       │
│ (リアルタイム) (レポート)                     │
└─────────────────────────────────────────────┘
```

## 参考リンク

- [Azure Well-Architected Framework — Operational Excellence](https://learn.microsoft.com/azure/well-architected/operational-excellence/)
- [Azure Monitor](https://learn.microsoft.com/azure/azure-monitor/)
- [Azure Automation](https://learn.microsoft.com/azure/automation/)
- [Azure Update Manager](https://learn.microsoft.com/azure/update-manager/)
- [Azure Service Health](https://learn.microsoft.com/azure/service-health/)


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [06. セキュア開発](06-development.md) | 開発プロセス・テスト・品質管理の設計 |
| → | [09. 監査](09-audit.md) | システム監査・サイバーセキュリティ監査 |
| → | [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md) | 各ランディングゾーンへの FISC 基準適用要件 |