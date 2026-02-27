# 情報系・DWH/BI システム ランディングゾーン

> データウェアハウス・ビジネスインテリジェンス・データ分析・AI/ML基盤のAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行の経営情報分析、リスク分析、収益管理、規制報告、マーケティング分析等を担うデータ分析基盤を対象としています。
- **Microsoft Fabric** を中心としたレイクハウスアーキテクチャを採用し、構造データ・半構造データ・非構造データを統合的に管理します。
- データの AI/ML 活用を前提とし、Fabric Data Science ワークロードおよび Azure OpenAI Service との統合を設計に含めています。
- 勘定系・為替決済系・市場系等の基幹系システムからのデータ取込みは、Private Link 経由の閉域網接続を前提としています。
- データガバナンスは **Microsoft Purview** により統合管理し、FISC 基準に準拠したデータ分類・アクセス制御・監査を実現します。

> **参考**: [Analytics end-to-end with Microsoft Fabric](https://learn.microsoft.com/azure/architecture/example-scenario/dataplate2e/data-platform-end-to-end) — Microsoft Fabric を活用したエンドツーエンドのデータ分析アーキテクチャ

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 情報系・DWH/BI システム（統合データ分析基盤） |
| 主な機能 | 経営情報分析、リスク分析、収益管理、規制報告、マーケティング分析、AI/ML |
| FISC外部性 | 通常は外部性なし（内部利用）。ただし規制報告データは監督当局への提出義務あり |
| 重要度 | **Tier 3（中）** |
| 処理特性 | バッチ ETL/ELT、ストリーム処理、OLAP、ダッシュボード、アドホッククエリ、ML 推論 |
| 可用性要件 | 99.9%以上（規制報告期限前はクリティカル） |

## ユースケース

- **経営ダッシュボード**: 勘定系・市場系・融資系からのデータを統合し、経営層向けのリアルタイムダッシュボードを提供します。
- **規制報告**: 金融庁・日銀向けの各種規制報告（バーゼル III 自己資本比率、流動性比率等）のデータ集計・レポート生成を行います。
- **リスク分析**: 信用リスク・市場リスク・オペレーショナルリスクの計量・モニタリングを行います。
- **マーケティング分析**: 顧客行動分析・セグメンテーション・レコメンデーションを AI/ML で実現します。
- **不正検知 (AI)**: 取引データのリアルタイム分析により、不正取引・マネーロンダリングの兆候を検知します。
- **非構造データ分析**: 契約書・申込書等のドキュメント、コールセンター音声、SNS データ等の分析を行います。

## FISC基準上の位置づけ

情報系システムは直接的な外部性は低いものの、複数の基幹系システムからデータを集約するため、**データガバナンス**と**個人情報保護**が特に重要です。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画
- 統7: **データ管理** — データの分類・管理・ライフサイクル管理
- 実1〜実19: 技術的安全対策（データ保護・アクセス制御関連を重点適用）
- 実3: **蓄積データの保護** — 暗号化・マスキング・匿名化
- 実10: **アクセス履歴管理** — 全データアクセスの監査ログ
- 実14: **不正侵入防止** — BI ダッシュボード・データ連携 API の保護
- 実25: **アクセス権限管理** — 行レベル / 列レベルセキュリティ
- 実34: **外部接続管理** — 基幹系システムからのデータ取込み経路の保護
- 実39〜実45: バックアップ（規制報告データは法定保存期間保持）

**情報系固有の追加要件**:
- 実150〜実153: **AI の安全管理** — AI/ML モデルの公平性・説明可能性・データ品質（AI 活用時）
- 個人情報保護法: **匿名加工情報・仮名加工情報** — マーケティング分析時の個人情報の適切な加工

## アーキテクチャの特徴

### Microsoft Fabric によるレイクハウスアーキテクチャ

データ分析基盤の中核として **Microsoft Fabric** を採用します。Fabric の OneLake を統合ストレージとし、構造データ・半構造データ・非構造データを一元管理するレイクハウスアーキテクチャを構築します。

| Fabric ワークロード | 用途 | 金融機関での活用例 |
|-------------------|------|----------------|
| **Data Factory** | データ取込み・ETL/ELT パイプライン | 基幹系からの日次/リアルタイムデータ取込み |
| **Data Engineering** | Spark ベースのデータ変換・加工 | メダリオンアーキテクチャの Bronze → Silver → Gold 変換 |
| **Data Warehouse** | T-SQL ベースの構造化分析 | 規制報告用の集計・レポートクエリ |
| **Data Science** | ML モデル開発・推論 | 不正検知モデル、顧客セグメンテーション |
| **Real-Time Intelligence** | ストリーム処理・リアルタイム分析 | 取引データのリアルタイムモニタリング |
| **Power BI** | 可視化・ダッシュボード・レポート | 経営ダッシュボード、規制報告レポート |

> **参考**: [Microsoft Fabric overview](https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview) — Fabric の統合データプラットフォーム

### メダリオンアーキテクチャ（Bronze / Silver / Gold）

データの品質と信頼性を段階的に向上させる**メダリオンアーキテクチャ**を採用します。各層は Fabric Lakehouse として独立した Workspace に配置し、ガバナンスを分離します。

```
データソース                    Bronze 層              Silver 層              Gold 層
┌──────────────┐            ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ 勘定系DB      │──CDC──────▶│ 生データ       │─変換─▶│ クレンジング   │─集計─▶│ ビジネス      │
│ 為替決済系DB  │            │ そのまま格納   │      │ 正規化        │      │ メトリクス    │
│ 市場系DB      │──ETL──────▶│ Delta Lake    │      │ 重複排除      │      │ KPI          │
│ 融資系DB      │            │ フォーマット   │      │ 型統一        │      │ ディメンション│
├──────────────┤            └──────────────┘      │ 仮名加工      │      │ モデル        │
│ ドキュメント   │──取込み───▶  (Raw/Parquet)         │ マスキング     │      └──────┬───────┘
│ 音声データ    │                                   └──────────────┘             │
│ ログデータ    │                                    (Delta Tables)              │
└──────────────┘                                                                ▼
                                                                        ┌──────────────┐
                                                                        │ Power BI     │
                                                                        │ AI/ML        │
                                                                        │ 規制報告      │
                                                                        └──────────────┘
```

| 層 | 格納形式 | 保持期間 | ガバナンス |
|----|---------|---------|-----------|
| **Bronze** | 生データ (Parquet / Delta / JSON / 画像 / 音声) | 7年以上（法定保存） | 書込み: パイプライン、読取り: データエンジニア |
| **Silver** | Delta Tables (クレンジング・仮名加工済み) | 3年 | 書込み: 変換パイプライン、読取り: データサイエンティスト |
| **Gold** | Delta Tables / Fabric Warehouse (ビジネスモデル) | 用途に応じて | 書込み: ビジネスロジック、読取り: ビジネスユーザー・BI |

> **参考**: [Medallion lakehouse architecture in Microsoft Fabric](https://learn.microsoft.com/fabric/onelake/onelake-medallion-lakehouse-architecture) — メダリオンアーキテクチャの Fabric 実装パターン

### 構造データと非構造データの統合管理

金融機関のデータ分析基盤では、従来の構造データ（DB テーブル）に加え、非構造データの活用が重要です。OneLake により両者を統合管理します。

| データ種別 | 例 | 格納先 | 処理方式 |
|-----------|-----|-------|---------|
| **構造データ** | 取引データ、口座データ、ポジションデータ | Lakehouse (Delta Tables) / Warehouse | Spark / T-SQL |
| **半構造データ** | API レスポンス (JSON)、ログファイル、XML 電文 | Lakehouse (Delta / Parquet) | Spark |
| **非構造データ（ドキュメント）** | 契約書、融資申込書、本人確認書類 | Lakehouse (Files) | Azure AI Document Intelligence |
| **非構造データ（音声）** | コールセンター通話録音 | Lakehouse (Files) | Azure AI Speech / OpenAI Whisper |
| **非構造データ（テキスト）** | 顧客問合せメール、SNS データ | Lakehouse (Delta) | Azure OpenAI (テキスト分析) |
| **時系列データ** | マーケットデータ、センサーデータ | Eventhouse (KQL Database) | KQL / Real-Time Intelligence |

### データの AI/ML 活用

データ分析基盤に蓄積されたデータを AI/ML で活用するため、以下の統合設計を行います。

#### Fabric Data Science による ML ワークロード

| 活用シナリオ | ML モデル | 入力データ | 出力 |
|------------|----------|-----------|------|
| 不正取引検知 | 異常検知 (Isolation Forest / AutoML) | 取引データ (Silver層) | リアルタイムスコア → Sentinel アラート |
| 顧客セグメンテーション | クラスタリング (K-Means) | 顧客属性・行動データ (Gold層) | セグメントラベル → マーケティング施策 |
| 融資審査スコアリング | 分類モデル (LightGBM / XGBoost) | 信用情報・取引履歴 (Silver層) | 審査スコア → 融資系連携 |
| 顧客離反予測 | 生存分析 / 分類 | 取引頻度・残高推移 (Gold層) | リテンション施策の優先順位 |
| ドキュメント自動分類 | Azure AI Document Intelligence | 融資申込書・契約書 (Bronze層) | 抽出フィールド → Silver層 |

#### Azure OpenAI Service との統合

| 活用シナリオ | モデル | 用途 |
|------------|-------|------|
| 規制報告ドラフト生成 | GPT-4o | 規制報告の文章ドラフト自動生成 |
| 社内ナレッジ検索 (RAG) | GPT-4o + AI Search | 社内規定・過去事例の自然言語検索 |
| コールセンター要約 | GPT-4o + Whisper | 通話内容の自動要約・感情分析 |
| コード生成支援 | Copilot in Fabric | Spark / SQL / DAX のコード生成支援 |

> **設計ポイント**: Azure OpenAI Service は**東日本リージョン**にデプロイし、データの越境を防止します。Fabric の Copilot 機能を有効化する場合は、テナント設定で Azure OpenAI の利用を許可し、データ処理リージョンの設定を確認してください。

#### MLOps パイプライン

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ データ    │──▶│ 特徴量    │──▶│ モデル    │──▶│ モデル    │──▶│ モデル    │
│ 準備     │   │ エンジニア │   │ 学習     │   │ 評価     │   │ デプロイ  │
│ (Silver) │   │ リング    │   │ (Fabric  │   │ (公平性  │   │ (Serving │
│          │   │ (Fabric) │   │  ML)     │   │  検証)   │   │  Endpoint)│
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
                                                   │
                                    ┌──────────────▼──────────────┐
                                    │ FISC 実150-153 適合性確認     │
                                    │ ・公平性 (Fairness)          │
                                    │ ・説明可能性 (Explainability)  │
                                    │ ・データ品質                  │
                                    │ ・人間による監督              │
                                    └─────────────────────────────┘
```

### データガバナンス（Microsoft Purview 統合）

データ分析基盤のガバナンスとして **Microsoft Purview** を Fabric と統合し、以下の機能を提供します。

| 機能 | Purview コンポーネント | 金融機関での用途 |
|------|---------------------|---------------|
| **データカタログ** | Unified Catalog / Data Map | データ資産の検索・発見、メタデータ管理 |
| **データ分類** | 感度ラベル (Sensitivity Labels) | 顧客情報・取引情報の機密度分類 |
| **データリネージ** | 自動リネージ追跡 | 規制報告データの変換過程の追跡可能性 |
| **DLP** | Data Loss Prevention ポリシー | クレジットカード番号・マイナンバー等の検知・保護 |
| **アクセス監査** | Audit ログ | 全データアクセスの監査証跡 |
| **データ品質** | データ品質ルール | 規制報告データの品質チェック |

> **参考**: [Use Microsoft Purview to govern Microsoft Fabric](https://learn.microsoft.com/fabric/governance/microsoft-purview-fabric) — Purview と Fabric の統合ガバナンス

## アーキテクチャ図

### 全体アーキテクチャ

```
┌──────────────────────────────────────────────────────────────────┐
│                     Azure テナント                                 │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │ Microsoft Fabric (統合データ分析基盤)                           ││
│  │                                                              ││
│  │  ┌────────────────────────────────────────────────────────┐  ││
│  │  │ OneLake (統合ストレージ)                                 │  ││
│  │  │                                                        │  ││
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────────┐   │  ││
│  │  │  │ Bronze LH  │  │ Silver LH  │  │ Gold LH /      │   │  ││
│  │  │  │ (Raw Data) │─▶│ (Cleansed) │─▶│ Warehouse      │   │  ││
│  │  │  │ 構造+非構造 │  │ 仮名加工済  │  │ (Business Ready)│   │  ││
│  │  │  └────────────┘  └────────────┘  └───────┬────────┘   │  ││
│  │  └──────────────────────────────────────────│─────────────┘  ││
│  │                                             │                ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───▼───────────┐   ││
│  │  │ Data Factory  │  │ Data Science  │  │ Power BI      │   ││
│  │  │ (ETL/ELT      │  │ (ML/AI        │  │ (ダッシュボード │   ││
│  │  │  パイプライン)  │  │  ノートブック) │  │  レポート)     │   ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘   ││
│  │                                                              ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   ││
│  │  │ Real-Time     │  │ Data          │  │ Copilot       │   ││
│  │  │ Intelligence  │  │ Warehouse     │  │ in Fabric     │   ││
│  │  │ (Eventhouse)  │  │ (T-SQL)       │  │ (AI支援)       │   ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘   ││
│  └──────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │ Azure サービス (Fabric 外)                                     ││
│  │                                                              ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   ││
│  │  │ Azure OpenAI  │  │ AI Document   │  │ AI Speech     │   ││
│  │  │ Service       │  │ Intelligence  │  │ Service       │   ││
│  │  │ (東日本)       │  │ (ドキュメント  │  │ (音声認識)     │   ││
│  │  │               │  │  抽出・分析)   │  │               │   ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘   ││
│  │                                                              ││
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   ││
│  │  │ Azure AI      │  │ Azure         │  │ Azure         │   ││
│  │  │ Search        │  │ Databricks    │  │ Data Explorer │   ││
│  │  │ (RAG用        │  │ (高度ML/      │  │ (リアルタイム   │   ││
│  │  │  ベクトル検索)  │  │  大規模処理)  │  │  時系列分析)   │   ││
│  │  └───────────────┘  └───────────────┘  └───────────────┘   ││
│  └──────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │ ガバナンス・セキュリティ                                         ││
│  │ ┌──────────────┐ ┌──────────────┐ ┌─────────────────────┐   ││
│  │ │ Purview      │ │ Sentinel     │ │ Defender for Cloud  │   ││
│  │ │ (カタログ/DLP/│ │ (不正検知)    │ │                     │   ││
│  │ │  リネージ)    │ │              │ │                     │   ││
│  │ └──────────────┘ └──────────────┘ └─────────────────────┘   ││
│  └──────────────────────────────────────────────────────────────┘│
│                                                                  │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │ データソース (Private Link 経由)                                 ││
│  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐     ││
│  │ │勘定系│ │為替系│ │市場系│ │融資系│ │IB系  │ │外部  │     ││
│  │ │SQL MI│ │SQL MI│ │SQL MI│ │SQL MI│ │SQL DB│ │データ│     ││
│  │ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘     ││
│  └──────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### データ取込み・処理

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| ETL/ELT パイプライン | Fabric Data Factory | マネージド VNet、CDC 対応 | 基幹系からの増分データ取込み |
| ストリーム取込み | Fabric Eventstream / Event Hubs | リアルタイムイベント取込み | 取引データのリアルタイム分析 |
| 大規模データ変換 | Fabric Data Engineering (Spark) | ノートブック / Spark ジョブ | メダリオン層間の変換処理 |
| 高度 ML / 大規模処理 | Azure Databricks (Premium) | VNet Injection、Unity Catalog | 大規模 ML ワークロード（Fabric 単体では不十分な場合） |

### ストレージ

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 統合データレイク | OneLake (Fabric) | Delta Lake フォーマット | 構造+非構造データの統合管理 |
| 外部データレイク | Azure Data Lake Storage Gen2 | ZRS + Private Endpoint、OneLake ショートカット | 既存 ADLS との連携 |
| 規制報告データ保存 | Blob Storage (RA-GRS) | WORM ポリシー（法定保存期間） | 不変ストレージによる長期保存 |

### 分析・AI/ML

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| SQL 分析 | Fabric Data Warehouse | T-SQL、ストアドプロシージャ | 規制報告の集計クエリ |
| リアルタイム分析 | Fabric Real-Time Intelligence (Eventhouse) | KQL Database | 取引モニタリング・異常検知 |
| ML モデル開発 | Fabric Data Science | ノートブック、MLflow | 不正検知・スコアリングモデル |
| 生成 AI | Azure OpenAI Service (東日本) | GPT-4o、プライベートエンドポイント | RAG・ドラフト生成・要約 |
| ドキュメント AI | Azure AI Document Intelligence | カスタムモデル | 融資申込書・契約書の自動抽出 |
| ベクトル検索 | Azure AI Search | ベクトルインデックス | RAG パターンの社内ナレッジ検索 |

### 可視化

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| ダッシュボード・レポート | Power BI (Fabric 統合) | Premium 容量、DirectLake モード | 経営ダッシュボード・セルフサービス BI |
| 規制報告 | Power BI Paginated Reports | 定型帳票出力 | 金融庁・日銀向け定型報告 |

### セキュリティ・ガバナンス

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| データカタログ・リネージ | Microsoft Purview | Unified Catalog、Fabric 統合 | データ資産管理・変換追跡 |
| データ分類・DLP | Purview Information Protection | 感度ラベル、DLP ポリシー | 機密データの自動分類・保護 |
| 行 / 列レベルセキュリティ | Fabric Warehouse RLS / Power BI RLS | ロールベースのデータアクセス制御 | 部門別・職位別のデータアクセス制御 |
| データマスキング | Dynamic Data Masking | 列単位のマスキング | 個人情報の参照制限 |
| 暗号鍵管理 | Key Vault (Premium) | CMK 管理 | 保存時暗号化の鍵管理 |

## セキュリティ設計

情報系は複数の基幹系システムからデータを集約するため、**データガバナンス**が最も重要な設計要素です。

| 対策 | 実装 | FISC基準 |
|------|------|---------|
| データ分類 | Purview 感度ラベル（極秘/秘/社外秘/一般） | 統7 |
| 行レベルセキュリティ | Fabric Warehouse RLS / Power BI RLS | 実25 |
| 列レベルセキュリティ | Fabric Warehouse CLS | 実25 |
| データマスキング | Dynamic Data Masking（マイナンバー・口座番号等） | 実3 |
| 匿名化・仮名加工 | Silver 層での仮名加工処理（Data Factory 変換） | 実3, 個人情報保護法 |
| データリネージ | Purview 自動リネージ追跡 | 統7 |
| DLP | Purview DLP ポリシー（クレジットカード番号・マイナンバー検知） | 実3 |
| アクセス監査 | Purview Audit + Fabric 監査ログ | 実10 |
| 個人情報保護 | Bronze→Silver 変換時に仮名加工情報を生成 | 個人情報保護法 |
| AI 安全管理 | Responsible AI ダッシュボード（公平性・説明可能性検証） | 実150〜153 |

## 可用性・DR設計

### 目標値

| 指標 | 通常時 | 規制報告期限前 |
|------|-------|-------------|
| **可用性** | 99.9% | 99.95% |
| **RTO** | < 4時間 | < 1時間 |
| **RPO** | < 1時間 | < 15分 |

### 障害レベル別対応

| 障害レベル | 事象 | 対応 | RTO |
|-----------|------|------|-----|
| Level 1 | 単一コンポーネント障害 | Fabric 自動復旧、Spark ジョブリトライ | < 5分 |
| Level 2 | 可用性ゾーン障害 | Fabric 内蔵の AZ 冗長性による自動復旧 | < 15分 |
| Level 3 | リージョン障害 | BCDR 構成による西日本への切替 | < 4時間 |

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| OneLake データ | Fabric の組み込み冗長性 + ADLS Gen2 GRS への定期エクスポート |
| 規制報告データ | Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（法定保存期間） |
| Databricks ノートブック | Git 連携 (Azure DevOps / GitHub) による版管理 |
| Power BI レポート | Fabric Git 統合による版管理 |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| 復元テスト | 四半期で別環境へのリストアテストを実施 |

### DR訓練

| 項目 | 内容 |
|------|------|
| パイプライン障害テスト | Data Factory パイプラインの障害注入・リトライ検証（月次） |
| データ復旧訓練 | OneLake データの ADLS Gen2 バックアップからの復元検証（四半期） |
| 規制報告 DR | 規制報告期限直前のリージョン障害シナリオ検証（年次） |
| 訓練環境 | 本番相当のデータを匿名化した検証環境で実施 |

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 情報系 東日本 (10.16.0.0/16)
│               ├── snet-fabric     (10.16.0.0/24)  — Fabric マネージド VNet PE
│               ├── snet-databricks (10.16.1.0/23)  — Databricks VNet Injection (/23)
│               ├── snet-openai     (10.16.3.0/24)  — Azure OpenAI Private Endpoint
│               ├── snet-ai-search  (10.16.4.0/24)  — AI Search Private Endpoint
│               ├── snet-doc-intel  (10.16.5.0/24)  — Document Intelligence PE
│               ├── snet-pe         (10.16.6.0/24)  — その他 Private Endpoint (Key Vault 等)
│               ├── snet-source-pe  (10.16.7.0/24)  — 基幹系データソース PE
│               └── snet-adls       (10.16.8.0/24)  — ADLS Gen2 Private Endpoint
│
└── Peering ──▶ Spoke VNet: 情報系 西日本 (10.17.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- snet-databricks: Databricks コントロールプレーンへの通信許可
- snet-source-pe: 基幹系 SQL MI / SQL DB への Private Endpoint 通信のみ許可
- Azure OpenAI: Private Endpoint 経由のアクセスのみ許可
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| パイプライン監視 | Fabric Data Factory パイプライン実行状況のダッシュボード |
| データ品質監視 | Silver/Gold 層のデータ品質メトリクス（欠損率、型不整合率） |
| レポート利用状況 | Power BI 利用状況メトリクス（アクティブユーザー数、レポート閲覧数） |

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| ETL パイプライン失敗 | Fabric Monitor / Azure Monitor | パイプライン失敗・タイムアウト |
| データ品質異常 | カスタムメトリクス | Bronze→Silver 変換時の品質チェック違反 |
| Spark ジョブ遅延 | Fabric Monitor | 日次バッチの SLA 超過 |
| ML モデルドリフト | Fabric Data Science | モデル精度の閾値低下 |
| DLP ポリシー違反 | Purview DLP | 機密データの検知アラート |
| データアクセス異常 | Microsoft Sentinel | 大量データエクスポート・異常アクセスパターン |
| OpenAI 利用量 | Azure Monitor | トークン使用量の急増 |
| 規制報告期限 | カスタムアラート | 報告期限 T-3 日時点でのデータ準備状況 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| Fabric デプロイ | Fabric Git 統合 + デプロイメントパイプライン（Dev → Test → Prod） |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| ノートブック版管理 | Git 連携による Spark ノートブック・SQL スクリプトの版管理 |
| ML モデル版管理 | MLflow によるモデルレジストリ・実験追跡 |
| Power BI デプロイ | Fabric デプロイメントパイプラインによるレポートプロモーション |
| Azure Policy | データ保護・暗号化・ネットワーク制限のポリシー自動適用 |

## 関連リソース

- [Analytics end-to-end with Microsoft Fabric](https://learn.microsoft.com/azure/architecture/example-scenario/dataplate2e/data-platform-end-to-end)
- [Greenfield lakehouse on Microsoft Fabric](https://learn.microsoft.com/azure/architecture/example-scenario/data/greenfield-lakehouse-fabric)
- [Microsoft Fabric overview](https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview)
- [Medallion lakehouse architecture in Microsoft Fabric](https://learn.microsoft.com/fabric/onelake/onelake-medallion-lakehouse-architecture)
- [What is a lakehouse in Microsoft Fabric?](https://learn.microsoft.com/fabric/data-engineering/lakehouse-overview)
- [Fabric Data Science overview](https://learn.microsoft.com/fabric/data-science/data-science-overview)
- [Copilot in Microsoft Fabric](https://learn.microsoft.com/fabric/fundamentals/copilot-fabric-overview)
- [Use Microsoft Purview to govern Microsoft Fabric](https://learn.microsoft.com/fabric/governance/microsoft-purview-fabric)
- [Disaster recovery architecture for an Azure data platform](https://learn.microsoft.com/azure/architecture/data-guide/disaster-recovery/dr-for-azure-data-platform-architecture)
- [Azure Databricks modern analytics architecture](https://learn.microsoft.com/azure/architecture/solution-ideas/articles/azure-databricks-modern-analytics-architecture)
- [Azure OpenAI Service documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [Azure AI Document Intelligence](https://learn.microsoft.com/azure/ai-services/document-intelligence/)
- [FISC compliance on Microsoft Cloud](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
