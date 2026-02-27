# リスク管理系システム ランディングゾーン

> 市場リスク・信用リスク・オペレーショナルリスク管理のAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行のリスク管理系システム（市場リスク・信用リスク・オペレーショナルリスク・ALM・自己資本比率計算・ストレステスト）を対象としています。
- 本アーキテクチャは [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/) および [High Performance Computing (HPC) on Azure](https://learn.microsoft.com/azure/architecture/topics/high-performance-computing) のガイダンスに準拠した設計としています。
- リスク計算エンジンには **Azure Batch** + HPC最適化VM（HBv4 / NCv5）を採用し、モンテカルロシミュレーション等の大規模並列計算をクラウドネイティブに実行します。
- Basel III / FRTB（Fundamental Review of the Trading Book）等の国際規制要件への対応を前提としています。
- オンプレミス環境との接続は Hub VNet 経由の ExpressRoute 閉域網接続を前提としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | リスク管理系システム |
| 主な機能 | 市場リスク（VaR / ES）、信用リスク（PD/LGD/EAD）、オペリスク、ALM（IRRBB）、自己資本比率計算、ストレステスト、xVA計算 |
| FISC外部性 | 通常は外部性なし（内部管理システム）。ただし規制報告の期限遵守は必須 |
| 重要度 | **Tier 2〜3**（規制報告の期限遵守が不可欠） |
| 処理特性 | **大規模バッチ計算**（モンテカルロシミュレーション等）、日次 / 月次 / 四半期レポート |
| 可用性要件 | 99.9%以上 |

## ユースケース

### 市場リスク管理

- **VaR / Expected Shortfall 計算**: モンテカルロシミュレーション（数千〜数万シナリオ）による日次リスク量計算
- **FRTB対応**: 標準的手法（SA）の感応度方式（SBM）+ デフォルトリスク賦課（DRC）+ 残余リスクアドオン（RRAO）、または内部モデル手法（IMA）による資本賦課計算
- **ストレステスト**: 規制当局指定シナリオおよび自行独自シナリオによる包括的ストレステスト
- **バックテスト / P&L帰属テスト**: 内部モデル手法の妥当性検証

### 信用リスク管理

- **信用格付モデル**: デフォルト確率（PD）・デフォルト時損失率（LGD）・デフォルト時エクスポージャー（EAD）の推計
- **与信ポートフォリオ分析**: セクター別・地域別・格付別のリスク集中度分析
- **ECL（Expected Credit Loss）計算**: IFRS 9 対応の予想信用損失計算（ステージ分類 + 将来予測シナリオ）

### ALM / 流動性リスク管理

- **IRRBB（銀行勘定の金利リスク）**: EVE / NII の金利シナリオ分析
- **流動性カバレッジ比率（LCR）/ 安定調達比率（NSFR）**: 日次・月次の規制指標計算
- **キャッシュフロー分析**: 満期構造分析・ギャップ分析

### 自己資本比率 / 規制報告

- **Basel III 自己資本比率**: CET1比率・Tier 1比率・総自己資本比率の計算
- **レバレッジ比率**: バランスシート全体のレバレッジ管理
- **規制報告**: 金融庁宛ての各種報告（バーゼルIIIモニタリング報告・ストレステスト結果報告等）

### xVA計算

- **CVA / DVA / FVA / KVA / MVA**: デリバティブのカウンターパーティ信用リスク調整計算
- **SA-CVA（標準的手法）**: FRTB連動のCVA資本賦課計算

## FISC基準上の位置づけ

リスク管理系システムは内部管理システムとして Tier 2〜3 に位置づけられますが、規制報告の期限遵守は業務上最優先事項です。計算結果の正確性・再現性・監査証跡の確保が求められます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準適用）
- 実1〜実19: 技術的安全対策（ネットワーク・アクセス制御）
- 実39〜実45: バックアップ（計算結果・市場データの保全）
- 実71, 実73: DR・コンティンジェンシープラン（規制報告期限の遵守）

**リスク管理固有の要件**:
- 計算結果の**再現性**（同一入力から同一結果を再現可能であること）
- 計算ロジックの**監査証跡**（モデルバージョン・パラメータ・入力データの全記録）
- **モデルリスク管理**（モデルの検証・バックテスト・定期的な妥当性検証）
- 規制報告の**期限遵守**（日次VaR: 当日中、ストレステスト: 期限内完了）

## アーキテクチャの特徴

### 大規模並列計算（Azure Batch + HPC VM）

リスク計算は金融機関で最も計算リソースを消費するワークロードの一つです。**Azure Batch** をジョブスケジューラとして採用し、HPC最適化VMを計算ノードとしてオンデマンドにスケールアウトします。

| 計算種別 | VM SKU | 計算規模（例） | 特徴 |
|---------|--------|-------------|------|
| 市場リスク（VaR / ES） | HBv4 (176 vCPU) | 10,000シナリオ × ポートフォリオ × 100ノード | CPU最適化・InfiniBand対応 |
| 信用リスク（PD/LGD/EAD） | Dv5 (96 vCPU) | 全与信先のデフォルト確率計算 × 50ノード | 汎用計算・コスト効率 |
| ストレステスト | HBv4 / Dv5 | 規制シナリオ × 全ポートフォリオ × バーストスケール | 四半期バースト・KEDA連携 |
| xVA計算 | NCv5 (GPU: H100) | ニューラルネットワーク近似によるCVA/FVA計算 | GPU加速・ディープラーニング推論 |
| FRTB SA計算 | Dv5 | 感応度集計 + DRC + RRAO | 日次バッチ |

> **参考**: [Azure Batch — Financial risk modeling using Monte Carlo simulations](https://learn.microsoft.com/azure/batch/batch-technical-overview)

### コスト最適化

| 戦略 | 実装 | 削減効果 |
|------|------|---------|
| Azure Spot VM | 計算ノードの一部（中断可能なジョブ）に適用。チェックポイント機能で中断時も途中から再開 | 最大90%削減 |
| オンデマンドスケール | 計算完了後に自動でノード数を0に縮退 | 非計算時間のコスト = 0 |
| VM SKU最適化 | 計算特性に応じた最適SKU選択（CPU/GPU/汎用） | 計算時間短縮 = コスト削減 |
| リザーブドインスタンス | 日次VaR等の定常的な計算ノードには1年 / 3年予約 | 最大72%削減 |

### データアーキテクチャ（Medallion パターン）

リスク計算のデータパイプラインは **Medallion アーキテクチャ**（Bronze / Silver / Gold）を採用し、市場データ・取引データの品質管理と計算結果のリネージを確保します。

```
┌────────────────┐    ┌────────────────┐    ┌────────────────┐
│ Bronze          │    │ Silver          │    │ Gold            │
│ (Raw Data)      │───▶│ (Curated Data)  │───▶│ (Business Data) │
│                 │    │                 │    │                 │
│ ・市場データ     │    │ ・クレンジング済  │    │ ・VaR/ES結果    │
│  (Bloomberg等)  │    │  市場データ      │    │ ・自己資本比率   │
│ ・取引データ     │    │ ・標準化済取引    │    │ ・規制報告データ  │
│  (勘定系連携)   │    │  データ          │    │ ・経営ダッシュ    │
│ ・格付データ     │    │ ・リスクファクター │    │  ボードデータ    │
│ ・マクロ経済指標 │    │  マスタ          │    │                 │
└────────────────┘    └────────────────┘    └────────────────┘
   Data Lake Gen2        Databricks /          SQL MI /
   (Raw Zone)            Synapse               Power BI
```

### 計算結果の再現性と監査証跡

リスク計算の規制上の要件として、**同一入力から同一結果を再現可能**であることが求められます。

| 要素 | 実装 |
|------|------|
| 入力データのスナップショット | Data Lake Gen2 にタイムスタンプ付きで不変保存（WORM） |
| モデルバージョン管理 | Azure ML / Git によるモデルコード・パラメータのバージョン管理 |
| 計算環境の固定 | Docker コンテナイメージのバージョン固定 + ACR の不変タグ |
| 計算ジョブのメタデータ | Batch ジョブの入力パラメータ・VM SKU・開始/終了時間をログ記録 |
| 結果のリネージ | Microsoft Purview によるデータリネージ（入力 → 計算 → 結果の追跡） |

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────┐
│  オンプレミス DC        │
│  ┌────────────────┐   │
│  │ 既存系          │   │
│  │ ・勘定系        │   │
│  │ ・市場系        │   │
│  │ ・市場データ     │   │
│  │  (Bloomberg等)  │   │
│  └───────┬────────┘   │
└──────────┼────────────┘
           │ ExpressRoute (冗長2回線)
┌──────────┼──────────────────────────────────────────────────────────┐
│ Azure    │                                                          │
│  ┌───────▼────────┐                                                 │
│  │  Hub VNet       │                                                 │
│  │  Azure Firewall │                                                 │
│  │  ExpressRoute GW│                                                 │
│  └──┬──────────┬──┘                                                 │
│     │ Peering  │ Peering                                             │
│     ▼          ▼                                                     │
│  ┌───────────────────────────────┐  ┌──────────────────────────────┐ │
│  │ 東日本リージョン (Primary)       │  │ 西日本リージョン (DR)          │ │
│  │                               │  │                              │ │
│  │ ┌───────────────────────────┐ │  │ ┌──────────────────────────┐ │ │
│  │ │ リスク計算エンジン          │ │  │ │ (DR環境:                  │ │ │
│  │ │                           │ │  │ │  計算リソースは            │ │ │
│  │ │ ┌───────────────────────┐ │ │  │ │  オンデマンド起動)         │ │ │
│  │ │ │ Azure Batch            │ │ │  │ │                          │ │ │
│  │ │ │ ┌─────────┐ ┌───────┐│ │ │  │ │ ┌──────────────────────┐ │ │ │
│  │ │ │ │ HBv4     │ │ NCv5  ││ │ │  │ │ │ Azure Batch          │ │ │ │
│  │ │ │ │ Pool     │ │ Pool  ││ │ │  │ │ │ (Standby: 0 nodes)   │ │ │ │
│  │ │ │ │ (VaR/ES) │ │(xVA)  ││ │ │  │ │ └──────────────────────┘ │ │ │
│  │ │ │ └─────────┘ └───────┘│ │ │  │ │                          │ │ │
│  │ │ │ ┌─────────┐ ┌───────┐│ │ │  │ │ ┌──────────────────────┐ │ │ │
│  │ │ │ │ Dv5     │ │ Spot  ││ │ │  │ │ │ SQL MI               │ │ │ │
│  │ │ │ │ Pool    │ │ Pool  ││ │ │  │ │ │ General Purpose      │ │ │ │
│  │ │ │ │(信用/ST)│ │(補助) ││ │ │  │ │ │ (Failover Group)     │ │ │ │
│  │ │ │ └─────────┘ └───────┘│ │ │  │ │ └──────────────────────┘ │ │ │
│  │ │ └───────────────────────┘ │ │  │ │                          │ │ │
│  │ └───────────────────────────┘ │  │ │ ┌──────────────────────┐ │ │ │
│  │                               │  │ │ │ Data Lake Gen2       │ │ │ │
│  │ ┌───────────────────────────┐ │  │ │ │ (GRS複製)            │ │ │ │
│  │ │ データ基盤                  │ │  │ │ └──────────────────────┘ │ │ │
│  │ │ ┌──────────────────────┐  │ │  │ └──────────────────────────┘ │ │
│  │ │ │ Data Lake Storage     │  │ │  └──────────────────────────────┘ │
│  │ │ │ Gen2 (ZRS)            │  │ │                                  │
│  │ │ │ ├─ Bronze (Raw)       │  │ │                                  │
│  │ │ │ ├─ Silver (Curated)   │  │ │                                  │
│  │ │ │ └─ Gold (Business)    │  │ │                                  │
│  │ │ └──────────────────────┘  │ │                                  │
│  │ │ ┌──────────────────────┐  │ │                                  │
│  │ │ │ Azure Databricks      │  │ │                                  │
│  │ │ │ (データ加工・分析)      │  │ │                                  │
│  │ │ └──────────────────────┘  │ │                                  │
│  │ │ ┌──────────────────────┐  │ │                                  │
│  │ │ │ Azure SQL MI          │  │ │                                  │
│  │ │ │ General Purpose       │  │ │                                  │
│  │ │ │ (計算結果・規制報告)    │  │ │非同期                           │
│  │ │ └──────────────────────┘  │ │─────▶ Failover Group            │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ レポーティング              │ │                                  │
│  │ │ ┌──────────────────────┐  │ │                                  │
│  │ │ │ Power BI Premium      │  │ │                                  │
│  │ │ │ ・規制報告ダッシュボード │  │ │                                  │
│  │ │ │ ・経営ダッシュボード    │  │ │                                  │
│  │ │ │ ・リスクドリルダウン    │  │ │                                  │
│  │ │ └──────────────────────┘  │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  └───────────────────────────────┘                                  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                 監視・自動化 (グローバル)                         │  │
│  │  Log Analytics Workspace | Application Insights                 │  │
│  │  Azure Monitor (外形監視・Batchジョブ監視)                        │  │
│  │  Azure Automation (FO 自動化・ジョブスケジュール)                   │  │
│  │  Microsoft Purview (データリネージ・分類)                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| VaR / ES 計算 | Azure Batch — HBv4 Pool | 100〜500ノード、オンデマンドスケール | CPU最適化・InfiniBand対応・モンテカルロシミュレーション |
| xVA 計算 | Azure Batch — NCv5 Pool (GPU: H100) | 10〜50ノード | ニューラルネットワーク近似によるCVA/FVA/KVA高速計算 |
| 信用リスク / ストレステスト | Azure Batch — Dv5 Pool | 50〜200ノード | 汎用計算・コスト効率 |
| 補助計算 | Azure Batch — Spot VM Pool | チェックポイント機能付き | コスト最大90%削減・中断可能ジョブ |
| データ加工 | Azure Databricks | VNet Injection、Unity Catalog | 市場データ/取引データのETL・特徴量エンジニアリング |
| ジョブオーケストレーション | Azure Data Factory / Databricks Workflows | スケジュール + イベント駆動 | 日次/月次バッチの自動実行・依存関係管理 |

### データベース

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 計算結果DB | Azure SQL MI General Purpose | 可用性ゾーン + Failover Group | リスク指標・規制報告データの格納。ACID特性 |
| 時系列データ | Azure Data Explorer (ADX) | クラスター構成 | 市場データ・リスクファクターの時系列分析・高速クエリ |
| ステート管理 | Azure Cosmos DB (NoSQL) | グローバルテーブル | Batchジョブの状態管理・リージョン切替時の継続性 |

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| データレイク | Azure Data Lake Storage Gen2 (ZRS) | Medallion（Bronze/Silver/Gold） | 市場データ・取引データ・計算結果の階層的管理 |
| メッセージング | Azure Service Bus Premium | 可用性ゾーン + Geo-DR | 計算ジョブのキューイング・完了通知 |
| ファイル共有 | Azure NetApp Files / Managed Lustre | HPC計算ノードからの高速並列アクセス | 大規模シミュレーションの入出力データ |

### レポーティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 規制報告 | Power BI Premium | 専用容量、スケジュール更新 | 規制報告テンプレート・経営ダッシュボード・ドリルダウン分析 |
| アドホック分析 | Azure Databricks SQL | サーバーレスSQL | リスクアナリストによるアドホッククエリ・探索的分析 |
| データカタログ | Microsoft Purview | Data Map + Data Catalog | データリネージ・分類・データ品質管理 |

### セキュリティ

| コンポーネント | Azureサービス | FISC基準 |
|-------------|-------------|---------|
| 暗号鍵管理 | Azure Key Vault (Premium) | 実13（FIPS 140-2 Level 2） |
| DB暗号化 | TDE + 顧客管理キー（CMK） | 実3（蓄積データ保護） |
| ネットワーク分離 | Private Endpoint + NSG | 実15（接続機器最小化） |
| データガバナンス | Microsoft Purview | 実3（データ分類・リネージ・アクセス制御） |
| コンテナセキュリティ | Microsoft Defender for Containers | 実14（計算コンテナイメージの脆弱性スキャン） |
| データレイクアクセス | Azure RBAC + ACL + Private Endpoint | 実15（最小権限アクセス） |

## 可用性・DR設計

### 目標値

| 要件 | 設計 |
|------|------|
| **RTO** | < 4時間（計算リソースのオンデマンド起動を含む） |
| **RPO** | < 1時間（計算結果DB） / ≈ 0（市場データ：GRS複製） |

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一計算ノード障害 | Azure Batch の自動リトライ（タスクレベル） | < 1分 | 0（チェックポイントから再開） |
| 可用性ゾーン障害 | SQL MI AZ間自動FO + Batch プール再作成 | < 30分 | 0 |
| リージョン障害 | 西日本への切替（計算リソースのオンデマンド起動） | < 4時間 | < 1時間 |
| ランサムウェア・データ破壊 | 不変バックアップからの復元 | 業務判断 | PITR設定に依存 |

> **設計ポイント**: リスク管理系システムでは、計算リソースがオンデマンドのため、DRリージョンに常時計算ノードを待機させる必要はありません。西日本リージョンにはデータ（SQL MI Failover Group + Data Lake GRS）のみを複製し、リージョン障害時にBatchプールを起動する方式でコストを最適化します。

### リージョン切替の自動化フロー

```
┌─ 外形監視（東日本 + 西日本 + 東南アジアから実施）─┐
│  Application Insights 可用性テスト                │
│  (Batch API / SQL MI の可用性確認)                 │
└──────────────────┬───────────────────────────────┘
                   │ 異常検知（複数ロケーション失敗）
                   ▼
┌──────────────────────────────────────────┐
│  Azure Monitor アラート → Action Group    │
│  ※2拠点以上の外形監視失敗で発火            │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│  Azure Automation Runbook (西日本で実行)   │
│                                          │
│  Step 1: 実行中ジョブの確認               │
│    → 実行中のBatchジョブの状態を記録       │
│    → 未完了ジョブのチェックポイント保存     │
│                                          │
│  Step 2: データ同期確認                    │
│    → SQL MI replication_lag_sec 確認       │
│    → Data Lake GRS 同期状態確認            │
│                                          │
│  Step 3: SQL MI Failover Group 切替       │
│    → 計画的フェイルオーバー or 強制FO        │
│                                          │
│  Step 4: 計算環境の起動                    │
│    → 西日本の Batch アカウントでプール作成  │
│    → 必要なVMノードの起動                  │
│    → Data Lake / NetApp Files の接続確認   │
│                                          │
│  Step 5: ジョブの再実行                    │
│    → 未完了ジョブのチェックポイントから再開  │
│    → 規制報告期限に間に合うよう優先度付け    │
│    → 正常性確認・切替完了通知              │
└──────────────────────────────────────────┘
```

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| 市場データ | Data Lake Storage Gen2 (RA-GRS) + 不変 (WORM) ポリシー |
| 計算結果 | SQL MI + Data Lake に二重保存（長期保存は Blob Archive） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | SQL MI Failover Group の計画的FO + 西日本での Batch プール起動テストを四半期毎に実施 |
| 規制報告期限テスト | DRリージョンからの規制報告データ生成・提出シミュレーションを半期毎に実施 |
| 計算再現性テスト | 過去の入力データからの結果再現テストを四半期毎に実施 |

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: リスク管理 東日本 (10.24.0.0/16)
│               ├── snet-batch       (10.24.0.0/22)  — Azure Batch 計算ノード（/22: 最大1024ノード）
│               ├── snet-databricks  (10.24.4.0/23)  — Databricks VNet Injection
│               ├── snet-db          (10.24.6.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-adx         (10.24.7.0/24)  — Azure Data Explorer
│               ├── snet-storage-pe  (10.24.8.0/24)  — Data Lake / NetApp Files PE
│               ├── snet-cosmos-pe   (10.24.9.0/24)  — Cosmos DB Private Endpoint
│               └── snet-pe          (10.24.10.0/24) — その他 Private Endpoint
│
└── Peering ──▶ Spoke VNet: リスク管理 西日本 (10.25.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- Batch サブネット: Azure Batch サービスからの管理通信を許可
- サブネット間: 必要最小限のポートのみ許可
- 市場データ連携: Hub VNet 経由でオンプレミス市場データフィードへの接続許可
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | Batch API の可用性確認・SQL MI の接続確認 |
| テスト頻度 | 5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### バッチジョブの監視

| 監視項目 | ツール | 内容 |
|---------|-------|------|
| ジョブ進捗 | Azure Batch Metrics + Azure Monitor | タスク完了率・残りタスク数・推定完了時間 |
| 計算ノード状態 | Azure Batch Pool Metrics | アクティブノード数・アイドルノード数・プリエンプション発生数（Spot VM） |
| 計算時間 | Azure Monitor カスタムメトリクス | VaR計算: 日次完了時刻、ストレステスト: バッチ所要時間 |
| データパイプライン | Data Factory / Databricks Workflows | ETLジョブの成功/失敗・処理件数・遅延 |
| 規制報告期限 | Azure Monitor カスタムアラート | 期限までの残り時間が閾値以下の場合にアラート |

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| VaR計算完了遅延 | Azure Monitor | 日次VaR計算が営業時間開始までに未完了 |
| Batch タスク失敗率 | Azure Batch Metrics | 失敗率 > 5% |
| Spot VM プリエンプション | Azure Batch Events | プリエンプション発生時即時通知 |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor | > 30秒 |
| Data Lake ストレージ容量 | Azure Monitor | 使用率 > 80% |
| 外形監視失敗 | Application Insights | 2拠点以上で失敗 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → UAT → 本番（プロモーション方式） |
| 計算エンジン | Docker コンテナイメージとして ACR (Premium, Geo-Replication) に格納 |
| モデル管理 | Azure ML / Git によるリスクモデルのバージョン管理 |
| バッチジョブ定義 | IaC によるBatchプール定義・ジョブテンプレートの管理 |
| データパイプライン | Data Factory / Databricks のパイプライン定義をGit管理 |
| テスト統合 | CI/CD パイプラインに計算結果の回帰テスト（過去結果との比較検証）を統合 |

## 関連リソース

- [High Performance Computing (HPC) on Azure](https://learn.microsoft.com/azure/architecture/topics/high-performance-computing)
- [Azure Batch overview](https://learn.microsoft.com/azure/batch/batch-technical-overview)
- [Azure Batch — Best practices](https://learn.microsoft.com/azure/batch/best-practices)
- [Azure CycleCloud overview](https://learn.microsoft.com/azure/cyclecloud/overview)
- [Azure Data Lake Storage Gen2](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)
- [Azure Databricks — Unity Catalog](https://learn.microsoft.com/azure/databricks/data-governance/unity-catalog/)
- [Microsoft Purview data governance](https://learn.microsoft.com/purview/governance-solutions-overview)
- [Azure SQL MI: Failover groups](https://learn.microsoft.com/azure/azure-sql/managed-instance/failover-group-sql-mi)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
