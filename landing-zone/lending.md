# 融資系システム ランディングゾーン

> 融資審査・実行・管理を担うシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行の融資審査（スコアリング）、融資実行、期中管理、担保管理、返済管理等を取り扱う融資系システムを対象としています。
- 融資審査に AI/ML を活用する場合、FISC 第13版の AI 安全対策基準（実150〜153）への準拠が必要です。
- 個人信用情報（要配慮個人情報を含む）を取り扱うため、「機微性を有するシステム」としての高い安全対策が求められます。
- オンプレミス環境との接続は ExpressRoute による閉域網接続を前提としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 融資系システム |
| 主な機能 | 融資審査（スコアリング）、融資実行、期中管理、担保管理、返済管理 |
| FISC外部性 | 機微性を有する（個人信用情報を取扱う） |
| 重要度 | **Tier 2（高）** |
| 処理特性 | 審査処理（AI/ML活用含む）+ OLTP + バッチ処理（日次・月次） |
| 可用性要件 | 99.95%以上（年間ダウンタイム約4.4時間以内） |
| 外部連携 | CIC（割賦販売法）、JICC（貸金業法）、KSC（全銀協）等の信用情報機関 |

## ユースケース

- 個人向け・法人向けの融資審査（住宅ローン、事業性融資、消費者ローン等）を想定しています。
- AI/ML を活用した与信スコアリングモデルにより、審査の迅速化・精度向上を図ります。
- 契約書・担保関連書類の OCR 処理（Azure AI Document Intelligence）による業務効率化を含みます。
- 本アーキテクチャは、機微性の高い個人情報を大量に取り扱い、かつ AI/ML モデルの公平性・説明可能性が求められるシステム全般に応用可能です。

## FISC基準上の位置づけ

融資系は個人信用情報（要配慮個人情報を含む）を取り扱うため、FISC基準上「機微性を有するシステム」として高い安全対策が求められます。特にデータの暗号化、アクセス制御、監査ログの保全が重要です。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準適用）
- 統7: 情報資産の分類・管理（個人信用情報の分類）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実3: 蓄積データの保護（個人信用情報の暗号化）
- 実25: アクセス制御（列・行レベルセキュリティ）
- 実39〜実45: バックアップ
- 実71, 実73: DR・コンティンジェンシープラン
- 実150〜実153: AI安全対策（AI/ML活用時）

## アーキテクチャの特徴

### マルチリージョン・ウォームスタンバイ構成

融資系システムは Tier 2 として、プライマリリージョン（東日本）で全処理を行い、セカンダリリージョン（西日本）はウォームスタンバイで待機します。勘定系（Tier 1）ほどの即時切替は要求されませんが、業務継続性の観点から1時間以内の復旧を目標とします。

### マルチロケーション接続

オンプレミスのデータセンターからAzure環境への接続は、ExpressRoute を用いた閉域網接続としています。外部信用情報機関（CIC/JICC/KSC）との接続はオンプレミス経由の専用線接続を利用します。

### AI/ML スコアリングエンジン

融資審査のスコアリングに **Azure Machine Learning** のマネージドオンラインエンドポイントを活用します。モデルの公平性・説明可能性・ドリフト監視を **Responsible AI ダッシュボード** で継続的にモニタリングし、FISC AI安全対策基準（実150〜153）に準拠します。

### ドキュメント処理の自動化

融資申込書、契約書、担保関連書類等の紙帳票を **Azure AI Document Intelligence** で OCR 処理・データ抽出し、審査業務を効率化します。Document Intelligence は住宅ローン申込書（Form 1003等）の事前構築モデルも提供しています。

> **参考**: [Document Intelligence mortgage document models](https://learn.microsoft.com/azure/ai-services/document-intelligence/prebuilt/mortgage-documents) — 住宅ローン関連書類の事前構築モデル

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────────┐
│  オンプレミス DC            │
│  ┌────────────────────┐   │
│  │ 既存系・信用情報接続  │   │
│  │ ├── CIC 接続        │   │
│  │ ├── JICC 接続       │   │
│  │ └── KSC 接続        │   │
│  └──────────┬─────────┘   │
└─────────────┼─────────────┘
              │ ExpressRoute (冗長2回線)
┌─────────────┼──────────────────────────────────────────────────┐
│ Azure       │                                                  │
│  ┌──────────▼────────┐                                         │
│  │  Hub VNet          │                                         │
│  │  Azure Firewall    │                                         │
│  │  ExpressRoute GW   │                                         │
│  └──┬─────────────┬──┘                                         │
│     │ Peering     │ Peering                                     │
│     ▼             ▼                                             │
│  ┌───────────────────────────┐   ┌────────────────────────────┐ │
│  │ 東日本リージョン (Primary)   │   │ 西日本リージョン (DR)        │ │
│  │                           │   │                            │ │
│  │ ┌───────────────────────┐ │   │ ┌────────────────────────┐ │ │
│  │ │ APIM (Standard v2)   │ │   │ │ APIM (Standard v2)     │ │ │
│  │ │ 内部VNet統合          │ │   │ │ (Standby)              │ │ │
│  │ └──────────┬────────────┘ │   │ └──────────┬─────────────┘ │ │
│  │            │               │   │            │                │ │
│  │ ┌──────────▼────────────┐ │   │ ┌──────────▼─────────────┐ │ │
│  │ │ AKS Private Cluster   │ │   │ │ AKS Private Cluster    │ │ │
│  │ │ (可用性ゾーン x3)      │ │   │ │ (Warm Standby)         │ │ │
│  │ │ ┌──────┐ ┌──────┐    │ │   │ │ ┌──────┐ ┌──────┐     │ │ │
│  │ │ │融資   │ │融資   │    │ │   │ │ │融資   │ │融資   │     │ │ │
│  │ │ │申込   │ │実行   │    │ │   │ │ │申込   │ │実行   │     │ │ │
│  │ │ │審査   │ │管理   │    │ │   │ │ │審査   │ │管理   │     │ │ │
│  │ │ └──────┘ └──────┘    │ │   │ │ └──────┘ └──────┘     │ │ │
│  │ │ ┌──────┐ ┌──────┐    │ │   │ │ ┌──────┐ ┌──────┐     │ │ │
│  │ │ │担保   │ │返済   │    │ │   │ │ │担保   │ │返済   │     │ │ │
│  │ │ │管理   │ │管理   │    │ │   │ │ │管理   │ │管理   │     │ │ │
│  │ │ └──────┘ └──────┘    │ │   │ │ └──────┘ └──────┘     │ │ │
│  │ └──────────┬────────────┘ │   │ └──────────┬─────────────┘ │ │
│  │            │               │   │            │                │ │
│  │ ┌──────────▼────────────┐ │   │ ┌──────────▼─────────────┐ │ │
│  │ │ Azure SQL MI          │ │非同期│ │ Azure SQL MI           │ │ │
│  │ │ General Purpose       │ │─────▶│ │ (Failover Group)       │ │ │
│  │ │ (融資台帳・担保台帳)    │ │   │ │                        │ │ │
│  │ └──────────────────────┘  │   │ └────────────────────────┘ │ │
│  │                           │   │                            │ │
│  │ ┌───────────────────────┐ │   │ ┌────────────────────────┐ │ │
│  │ │ Azure ML Workspace    │ │   │ │ Azure ML Workspace     │ │ │
│  │ │ (審査スコアリング      │ │   │ │ (Standby Endpoint)     │ │ │
│  │ │  マネージドEndpoint)   │ │   │ │                        │ │ │
│  │ └───────────────────────┘ │   │ └────────────────────────┘ │ │
│  │                           │   │                            │ │
│  │ ┌───────────────────────┐ │   │ ┌────────────────────────┐ │ │
│  │ │ AI Document           │ │   │ │ AI Document            │ │ │
│  │ │ Intelligence          │ │   │ │ Intelligence           │ │ │
│  │ │ (契約書OCR)           │ │   │ │                        │ │ │
│  │ └───────────────────────┘ │   │ └────────────────────────┘ │ │
│  │                           │   │                            │ │
│  │ ┌───────────────────────┐ │   │ ┌────────────────────────┐ │ │
│  │ │ Cosmos DB             │ │グロ │ │ Cosmos DB              │ │ │
│  │ │ (審査ステート管理)     │ │ーバル│ │ (グローバルテーブル)     │ │ │
│  │ └───────────────────────┘ │テー │ └────────────────────────┘ │ │
│  │                           │ブル │                            │ │
│  │ ┌───────────────────────┐ │   │ ┌────────────────────────┐ │ │
│  │ │ Key Vault             │ │   │ │ Key Vault              │ │ │
│  │ │ (CMK / 個人情報暗号)   │ │   │ │                        │ │ │
│  │ └───────────────────────┘ │   │ └────────────────────────┘ │ │
│  │                           │   │                            │ │
│  │ ┌───────────────────────┐ │   │ ┌────────────────────────┐ │ │
│  │ │ Microsoft Purview     │ │   │ │ Microsoft Purview      │ │ │
│  │ │ (データ分類・DLP)      │ │   │ │                        │ │ │
│  │ └───────────────────────┘ │   │ └────────────────────────┘ │ │
│  └───────────────────────────┘   └────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                 監視・自動化 (グローバル)                      │  │
│  │  Log Analytics Workspace | Application Insights             │  │
│  │  Azure Monitor (外形監視) | Microsoft Sentinel              │  │
│  │  Azure Automation (FO 自動化) | Azure Chaos Studio          │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 融資Webアプリ | AKS (Private Cluster) | 可用性ゾーン3ゾーン | マイクロサービス対応・スケーラビリティ |
| 代替コンピューティング | App Service (Premium v3) / Azure Container Apps | 可用性ゾーン | コンテナ管理負荷を軽減したい場合 |
| 審査スコアリングエンジン | Azure Machine Learning | マネージドオンラインエンドポイント、可用性ゾーン | リアルタイム推論・モデル管理・Responsible AI |
| バッチ処理 | Azure Batch / AKS Job | 専用ノードプール | 月次利息計算・返済スケジュール更新等 |
| API Gateway | Azure API Management (Standard v2) | 内部VNet統合 | API管理・外部信用情報照会の仲介 |

### データベース

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 融資台帳DB | Azure SQL MI General Purpose | 可用性ゾーン + Failover Group | 融資台帳・担保台帳・返済管理のACID保証 |
| 審査ステート管理DB | Azure Cosmos DB (NoSQL) | グローバルテーブル（マルチリージョン） | 審査ワークフローのステート管理。リージョン切替時にDB切替不要 |
| キャッシュ | Azure Cache for Redis Enterprise | 可用性ゾーン | 審査結果キャッシュ・セッション管理 |

> **DB構成の設計意図**: 融資台帳DB (SQL MI General Purpose) は融資取引の ACID 特性に最適化し、審査ステート管理DB (Cosmos DB) は審査ワークフローの進行状態管理に使用します。Cosmos DB のグローバルテーブルにより、リージョン切替時の審査ステートは切替作業なく継続利用できます。融資系は Tier 2 のため、SQL MI は General Purpose ティアを選択しコスト最適化しています。

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| ドキュメントストレージ | Azure Blob Storage (ZRS) | ゾーン冗長 + 不変 (WORM) ポリシー | 契約書・担保書類の保存（法定保存期間対応） |
| メッセージキュー | Azure Service Bus Premium | 可用性ゾーン + Geo-DR | 審査ワークフロー連携 |
| イベントストリーム | Azure Event Hubs | 可用性ゾーン + Geo-DR | 融資イベントのストリーム処理・監査ログ |

### AI/ML

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| スコアリングモデル | Azure Machine Learning | マネージドオンラインエンドポイント | リアルタイム与信スコアリング |
| Responsible AI | Azure ML Responsible AI ダッシュボード | 公平性・説明可能性・エラー分析 | FISC AI安全対策基準準拠 |
| ドキュメント OCR | Azure AI Document Intelligence | マネージドサービス | 契約書・申込書の自動データ抽出 |
| モデルレジストリ | Azure ML モデルレジストリ | バージョン管理 | モデルのライフサイクル管理・監査証跡 |

### セキュリティ（機微情報保護）

| コンポーネント | Azureサービス | FISC基準 |
|-------------|-------------|---------|
| 個人情報暗号化 | Always Encrypted + CMK (Key Vault) | 実3（蓄積データ保護） |
| データマスキング | Azure SQL Dynamic Data Masking | 実3（不要な情報露出の防止） |
| 列・行レベルセキュリティ | Azure SQL RLS/CLS | 実25（アクセス制御） |
| データ分類 | Microsoft Purview 機密度ラベル | 統7（情報資産の分類・管理） |
| DLP | Microsoft Purview DLP | 実3（データ漏洩防止） |
| 監査ログ | Azure SQL Auditing + 不変ストレージ | 実10（監査ログの保全） |
| ネットワーク分離 | Private Endpoint + NSG | 実15（接続機器最小化） |
| コンテナセキュリティ | Microsoft Defender for Containers | 実14（コンテナイメージ脆弱性スキャン） |

### 外部連携

| 連携先 | 接続方式 | Azureサービス | 備考 |
|-------|---------|-------------|------|
| CIC（割賦販売法） | 専用線 → ExpressRoute | APIM + ExpressRoute | オンプレミス対外接続GW経由 |
| JICC（貸金業法） | 専用線 → ExpressRoute | APIM + ExpressRoute | オンプレミス対外接続GW経由 |
| KSC / 全銀協 | 専用線 → ExpressRoute | APIM + ExpressRoute | オンプレミス対外接続GW経由 |
| 不動産登記情報 | API/専用線 | APIM | 担保評価用 |

## AI/ML活用時の考慮事項（実150〜153）

融資審査にAI/MLを活用する場合、FISC第13版のAI安全対策基準に準拠が必要です。

| 観点 | 対策 | Azure実装 |
|------|------|----------|
| 公平性・バイアス | 保護属性（性別・年齢・民族等）に基づく不公平な判定の検出・緩和 | Azure ML [Responsible AI ダッシュボード](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai-dashboard)の公平性指標を監視 |
| 説明可能性 | 審査結果の根拠を顧客・審査担当者に説明可能とする | モデル解釈機能（SHAP/LIME）による[ローカル・グローバル説明](https://learn.microsoft.com/azure/machine-learning/how-to-machine-learning-interpretability)、[Responsible AI スコアカード](https://learn.microsoft.com/azure/machine-learning/how-to-responsible-ai-scorecard)の自動生成 |
| モデルドリフト | 経済環境変化等によるモデル精度劣化の早期検出 | Azure ML [データドリフトモニタリング](https://learn.microsoft.com/azure/machine-learning/how-to-monitor-datasets)による継続監視 |
| 人的関与 | AI判定結果の人間によるレビュー・最終承認プロセス | 審査ワークフローに承認ステップを組込み、AI は判断補助に限定 |
| モデルガバナンス | モデルのバージョン管理・承認フロー・監査証跡 | Azure ML モデルレジストリ + Azure DevOps による MLOps パイプライン |
| 反社会的勢力チェック | 融資先の反社チェック | Microsoft Sentinel + 外部データベース連携 |

> **FISC 実150〜153 の要旨**: AI を業務に活用する場合、AI の利用方針の策定（実150）、AI の品質管理（実151）、AI のリスク管理（実152）、AI の監査（実153）が求められます。特に融資審査のように顧客に直接影響を与える判断へのAI適用には、公平性・説明可能性の担保と人的関与が不可欠です。

## 可用性・DR設計

### 目標値

| 要件 | 設計 |
|------|------|
| **RTO** | < 15分（AZ内自動FO）/ < 1時間（リージョン間DR） |
| **RPO** | ≈ 0（AZ内同期レプリケーション）/ < 15分（リージョン間非同期レプリケーション） |

> **RPOに関する注意**: General Purpose ティアの Failover Group は非同期レプリケーションを使用します。Business Critical ティアと比較してレプリケーションラグが大きくなる可能性があるため、RPO 要件に応じてティアの選定を見直してください。

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一ノード障害 | AKS セルフヒーリング / SQL MI 自動FO | < 1分 | 0 |
| 可用性ゾーン障害 | SQL MI AZ間自動FO + AKS マルチAZ | < 15分 | 0 |
| リージョン障害 | 自動切替フロー（後述）による西日本への切替 | < 1時間 | < 15分 |
| ランサムウェア・データ破壊 | 不変バックアップからの復元 | 業務判断 | PITR設定に依存 |

### リージョン切替の自動化フロー

リージョン切替は、**Azure Automation Runbook** で自動化します。切替を確実に実行するため、自動化ロジックは**セカンダリリージョン（西日本）で実行**します。

```
┌─ 外形監視（東日本 + 西日本 + 第三リージョンから実施）──┐
│  Application Insights 可用性テスト                      │
│  (複数ロケーションからの融資API疑似リクエスト)            │
└──────────────────┬─────────────────────────────────────┘
                   │ 異常検知（複数ロケーション失敗）
                   ▼
┌──────────────────────────────────────────────┐
│  Azure Monitor アラート → Action Group        │
│  ※2拠点以上の外形監視失敗で発火                │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│  Azure Automation Runbook (西日本で実行)       │
│                                              │
│  Step 1: アプリケーション閉塞                  │
│    → APIM でインバウンドリクエストを遮断        │
│    → 処理中審査ワークフローの状態保全           │
│                                              │
│  Step 2: データ同期確認                        │
│    → SQL MI replication_lag_sec 確認           │
│    → 未同期データがある場合は強制FO判断          │
│                                              │
│  Step 3: SQL MI Failover Group 切替           │
│    → 計画的フェイルオーバー or 強制FO            │
│    ※Cosmos DB グローバルテーブルは切替不要       │
│                                              │
│  Step 4: アプリケーション切替                   │
│    → 西日本 AKS クラスタの本番昇格              │
│    → Azure ML エンドポイントの切替              │
│    → APIM の閉塞解除（西日本側）                │
│                                              │
│  Step 5: DNS / トラフィック切替                 │
│    → Azure Front Door のバックエンド変更        │
│    → ExpressRoute のルーティング変更            │
│                                              │
│  Step 6: 正常性確認                            │
│    → 西日本環境の外形監視・ヘルスチェック         │
│    → 審査ワークフローの再開確認                  │
│    → 切替完了通知                              │
└──────────────────────────────────────────────┘
```

> **融資系固有の設計ポイント**: 融資審査は勘定系・為替系と比較して即時性の要求が相対的に低いため、RTO を1時間以内に設定しています。ただし、処理中の審査ワークフローの状態は Cosmos DB に保持されるため、リージョン切替後もワークフローを途中から再開できます。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| 契約書アーカイブ | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（法定保存期間対応） |
| ML モデルバックアップ | Azure ML モデルレジストリ + Azure Container Registry (Geo-Replication) |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |
| 負荷テスト併用 | 障害注入と負荷テストを同時実行し、障害時のシステム挙動を検証 |
| 訓練内容 | DNS障害注入、AZ障害シミュレーション、DB フェイルオーバー、ML エンドポイント障害 |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 融資系 東日本 (10.6.0.0/16)
│               ├── snet-apim      (10.6.0.0/24)  — API Management
│               ├── snet-app       (10.6.1.0/24)  — AKS ノード（融資申込・審査・実行・管理）
│               ├── snet-db        (10.6.2.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-cosmos    (10.6.3.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-ml        (10.6.4.0/24)  — Azure ML マネージドエンドポイント PE
│               ├── snet-cache     (10.6.5.0/24)  — Redis Enterprise
│               ├── snet-msg       (10.6.6.0/24)  — Service Bus / Event Hubs PE
│               ├── snet-pe        (10.6.7.0/24)  — その他 Private Endpoint (AI Document Intelligence等)
│               └── snet-batch     (10.6.8.0/24)  — バッチ処理ノード
│
└── Peering ──▶ Spoke VNet: 融資系 西日本 (10.7.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- サブネット間: 必要最小限のポートのみ許可
- SQL MI サブネット: SQL MI 専用の NSG ルール適用
- ML サブネット: Azure ML エンドポイントへの推論リクエストのみ許可
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | 融資APIへの疑似リクエスト（審査ステータス照会等） |
| テスト頻度 | 5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | 審査ワークフロー全体のリクエストトレース・レイテンシ分析 |
| サービスマップ | Application Insights Application Map | 融資申込→審査→実行→管理の依存関係・ボトルネック可視化 |
| ML モデル監視 | Azure ML モニタリング | モデル精度・データドリフト・推論レイテンシの継続監視 |
| メトリクス収集 | Azure Monitor + Prometheus (AKS) | CPU、メモリ、リクエスト数、エラー率のリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 不正融資申込検知・セキュリティイベント相関分析 |

> AKS 上の各 Pod にサイドカーコンテナとして OpenTelemetry Collector を配置し、分散トレーシングを実現します。審査ワークフロー（申込受付→信用情報照会→スコアリング→審査判定→融資実行）の全体を一つのトレースとして可視化できます。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| 審査処理応答時間 | Application Insights | P99 > 3秒 |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor (replication_lag_sec) | > 5秒 |
| ML エンドポイントレイテンシ | Azure ML メトリクス | P99 > 1秒 |
| ML モデルドリフト | Azure ML データドリフトモニター | ドリフトスコア > 閾値 |
| バッチ処理遅延 | Azure Monitor カスタムメトリクス | スケジュール超過 |
| フェイルオーバーイベント | Azure SQL MI 診断ログ | FO発生時即時通知 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| 個人情報アクセス異常 | Microsoft Sentinel | 通常パターン外のアクセス検知 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| MLOps | Azure ML Pipelines + Azure DevOps による ML モデルの CI/CD |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |
| モデルデプロイ | Azure ML マネージドオンラインエンドポイント（Blue/Green デプロイ） |

## 関連リソース

- [Azure Well-Architected Framework: Mission-Critical Workloads](https://learn.microsoft.com/azure/well-architected/mission-critical/)
- [Azure Machine Learning: Responsible AI](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)
- [Azure ML: Model interpretability](https://learn.microsoft.com/azure/machine-learning/how-to-machine-learning-interpretability)
- [Azure ML: Responsible AI scorecard](https://learn.microsoft.com/azure/machine-learning/how-to-responsible-ai-scorecard)
- [Azure ML: Model performance and fairness](https://learn.microsoft.com/azure/machine-learning/concept-fairness-ml)
- [Azure AI Document Intelligence: Mortgage documents](https://learn.microsoft.com/azure/ai-services/document-intelligence/prebuilt/mortgage-documents)
- [Azure SQL MI: High availability and disaster recovery checklist](https://learn.microsoft.com/azure/reliability/reliability-sql-managed-instance)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
- [Microsoft Fabric for Financial Services](https://learn.microsoft.com/industry/financial-services/fabric/)
