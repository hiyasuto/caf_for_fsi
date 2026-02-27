# 市場系・トレーディングシステム ランディングゾーン

> 有価証券売買・デリバティブ取引・外国為替取引を担うシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、証券会社・銀行の市場部門における有価証券売買・デリバティブ取引・外国為替取引を取り扱う市場系・トレーディングシステムを対象としています。
- フロントオフィス（注文執行・トレーディング）、ミドルオフィス（リスク管理・約定照合）、バックオフィス（決済・照合・経理）の 3 層構造で設計しています。
- 本アーキテクチャは [Azure Well-Architected Framework のミッションクリティカルワークロード](https://learn.microsoft.com/azure/well-architected/mission-critical/) ガイダンスに準拠した設計としています。
- オンプレミス環境・取引所・情報ベンダーとの接続は ExpressRoute による閉域網接続を前提としています。
- リスク計算（VaR・モンテカルロシミュレーション等）には HPC/GPU コンピューティングを活用する設計としています。

> **参考**: [Host a Murex MX.3 workload on Azure](https://learn.microsoft.com/industry/financial-services/architecture/murex-mx3-azure-content) — Microsoft による市場系パッケージ (Murex MX.3) の Azure リファレンスアーキテクチャ

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 市場系・トレーディングシステム |
| 主な機能 | 有価証券売買、デリバティブ取引、外国為替取引、ポジション管理、損益計算、リスク計算 |
| FISC外部性 | **重大な外部性を有する可能性**（証券会社の主要業務、銀行の市場部門） |
| 重要度 | **Tier 1〜2（金融機関種別により異なる：証券=Tier 1、銀行市場部門=Tier 2）** |
| 処理特性 | **超低レイテンシ**（ミリ秒単位の応答要求）、大量同時処理、HPC バッチ計算 |
| 可用性要件 | 99.99%以上（取引時間中：東証 9:00-15:30）、99.95%（取引時間外） |

## ユースケース

- 証券会社のエクイティ（株式）・債券・デリバティブ・外国為替の注文管理・執行システム（OMS/EMS）を想定しています。
- フロントオフィスでは**超低レイテンシの注文執行**、ミドルオフィスでは**大規模並列のリスク計算**、バックオフィスでは**決済照合・ポジション管理**が求められます。
- マーケットデータ（株価ティックデータ等）の**リアルタイムストリーミング処理**と**時系列分析**を含みます。
- リスク計算（VaR、ストレステスト、モンテカルロシミュレーション）は**日中リアルタイム**と**日次バッチ**の両方に対応します。

## FISC基準上の位置づけ

証券会社において市場系システムは主要業務を担うシステムとして「重大な外部性を有する」に分類されます。銀行の市場部門においても、取引量・リスク量に応じて高い安全対策レベルが要求されます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準すべて適用）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実39〜実45: バックアップ（最高レベル — 約定データは損失不可）
- 実71, 実73: DR・コンティンジェンシープラン（取引所接続切替を含む）
- 設1〜設70: データセンター設備基準（全項目適用）

**市場系固有の追加要件**:
- 実5: **注文・約定データの改ざん防止** — SQL MI Ledger テーブルによる暗号学的証明
- 実17, 実18: **異常取引・市場操縦の検知** — リアルタイムストリーム分析による監視
- 実10: **取引ログの完全性保証** — 全注文の監査証跡を不変ストレージに保存

## アーキテクチャの特徴

### フロント / ミドル / バックオフィスの分離

市場系システムは**フロント / ミドル / バック**の 3 層で構成されます。各層は異なる非機能要件を持つため、独立したマイクロサービスとして設計し、個別にスケーリング可能としています。

| オフィス | 主な機能 | 非機能要件 | Azure サービス |
|---------|---------|-----------|--------------|
| **フロント** | 注文管理 (OMS)、注文執行 (EMS)、マーケットメイク | 超低レイテンシ (< 10ms)、高スループット | AKS (Proximity Placement Group) |
| **ミドル** | リスク計算 (VaR)、約定照合、ポジション管理 | 大規模並列計算、バースト対応 | AKS + Azure Batch (HPC) |
| **バック** | 決済指図、受渡処理、経理仕訳、規制報告 | バッチ処理、データ整合性 | AKS / App Service |

### 超低レイテンシ設計

フロントオフィスの注文執行には**ミリ秒単位のレイテンシ**が要求されます。以下の Azure 機能を組み合わせて低レイテンシを実現します。

| 設計要素 | Azure 実装 | 効果 |
|---------|-----------|------|
| **Proximity Placement Group** | AKS ノードプールを PPG に配置 | VM 間の物理的距離を最小化しネットワークレイテンシを削減 |
| **Accelerated Networking** | SR-IOV 対応 NIC による高速ネットワーク | ネットワークスタックのオーバーヘッドを排除 |
| **Premium SSD v2** | IOPS / スループットを個別調整可能 | ストレージI/Oレイテンシを最小化 |
| **Ultra Disk** | リスク計算の中間結果書き込み向け | サブミリ秒の書き込みレイテンシ |
| **KEDA + HPA** | Event Hubs のラグに基づくイベント駆動スケーリング | マーケットデータ量に連動した自動スケール |

> **参考**: [Proximity placement groups](https://learn.microsoft.com/azure/virtual-machines/co-location) — VM のネットワークレイテンシ最小化のための配置制御

### HPC / GPU によるリスク計算

ミドルオフィスのリスク計算（VaR、CVA/DVA、ストレステスト、モンテカルロシミュレーション）は計算量が膨大であり、**Azure Batch** による HPC クラスタを活用します。

| 計算種別 | VM サイズ | 用途 |
|---------|----------|------|
| モンテカルロ VaR | HBv4 (176 vCPU, 高帯域幅メモリ) | CPU ベースの大規模並列シミュレーション |
| ディープラーニングプライシング | NCv5 / ND H100 v5 (GPU) | ニューラルネットワークによるデリバティブ評価 |
| ストレステスト | HBv4 + Premium SSD v2 | 数千シナリオの一括計算 |
| 日次バッチリスク計算 | Azure Batch 低優先度 VM | コスト最適化されたバッチ処理 |

Azure Batch の**自動プール**機能により、リスク計算ジョブの投入時にのみ HPC ノードを起動し、計算完了後に自動削除することでコストを最適化します。日中のリアルタイム VaR 計算には常時起動プールを、日次バッチには低優先度 VM による一時プールを使い分けます。

### マーケットデータ基盤

取引所・情報ベンダー（Bloomberg、Refinitiv 等）からの大量ティックデータを処理するため、**Event Hubs Dedicated** と **Azure Data Explorer** を組み合わせた専用マーケットデータ基盤を構築します。

```
取引所 / 情報ベンダー
        │ ExpressRoute (閉域網)
        ▼
┌─────────────────────────────┐
│ Event Hubs Dedicated         │
│ (Capacity Unit × N)          │
│ 数百万イベント/秒の受信能力    │
└──────────┬──────────────────┘
           │
     ┌─────┼─────────┐
     ▼     ▼         ▼
 ┌──────┐ ┌──────┐ ┌──────────────────┐
 │ AKS  │ │ ADX  │ │ Blob Storage     │
 │ OMS  │ │ 時系列│ │ (Capture/Archive)│
 │ EMS  │ │ 分析  │ │ 長期保存          │
 └──────┘ └──────┘ └──────────────────┘
```

- **Event Hubs Dedicated**: 専用クラスタにより、他テナントの影響を受けない安定したスループットを確保。Capacity Unit 単位でスケーリング
- **Azure Data Explorer (ADX)**: ティックデータの時系列分析（移動平均、ボリュームプロファイル、異常検知）をリアルタイムで実行
- **Event Hubs Capture**: 全ティックデータを Blob Storage (WORM ポリシー) に自動アーカイブし、規制対応の長期保存を実現

> **参考**: [Azure Event Hubs — Dedicated tier](https://learn.microsoft.com/azure/event-hubs/event-hubs-dedicated-overview) — 数百万イベント/秒の処理能力を持つ専用クラスタ

### 注文・約定の改ざん防止

金融規制（金商法・FISC実5）で求められる注文・約定データの改ざん防止には、**Azure SQL MI の Ledger テーブル**機能を活用します。

- **Append-Only Ledger テーブル**: 注文ログ・約定ログを追記専用テーブルに記録し、暗号学的ハッシュチェーンにより改ざんを検知
- **ダイジェスト管理**: Azure Confidential Ledger または不変 Blob Storage にダイジェストを外部保管し、独立した検証を可能に
- **監査検証**: `sp_verify_database_ledger` ストアドプロシージャにより、任意のタイミングでデータ改ざんの有無を暗号学的に検証

> **参考**: [Ledger overview](https://learn.microsoft.com/sql/relational-databases/security/ledger/ledger-overview) — SQL Server / Azure SQL の改ざん防止機能

### ポジション管理 (Cosmos DB)

リアルタイムのポジション管理（保有残高・含み損益・リスクエクスポージャー）には **Cosmos DB** を採用します。SQL MI（ACID トランザクション）とは異なり、ポジションのような頻繁に更新される集約データに最適化されています。

| 設計項目 | 内容 |
|---------|------|
| 整合性レベル | **Strong Consistency**（ポジション管理は強整合性必須） |
| パーティションキー | 銘柄コード + 口座ID |
| グローバルテーブル | 東日本 (書込) + 西日本 (読取) の 2 リージョン構成 |
| フェイルオーバー時 | 西日本への自動フェイルオーバー（書込リージョン切替） |
| 変更フィード | Cosmos DB Change Feed → Event Hubs → リスク計算パイプライン |

Cosmos DB の **Change Feed** をトリガーとして、ポジション変動をリアルタイムにリスク計算パイプラインへ伝播します。これにより、約定 → ポジション更新 → リスク再計算の一連のフローを**イベント駆動**で実現します。

### 取引所・情報ベンダー接続

取引所（東証 arrowhead、大証 J-GATE 等）および情報ベンダー（Bloomberg、Refinitiv 等）との接続は、**ExpressRoute** による閉域網接続としています。

| 接続先 | 接続方式 | 冗長構成 |
|-------|---------|---------|
| 東証 arrowhead | ExpressRoute (専用線) 経由 Proximity プロバイダ | 2 回線 (異なるピアリングロケーション) |
| 大証 J-GATE | ExpressRoute 経由 | 2 回線 |
| Bloomberg Terminal | ExpressRoute 経由 BPIPE | 2 回線 |
| Refinitiv Eikon | ExpressRoute 経由 | 2 回線 |
| JSCC (清算) | ExpressRoute 経由 | 2 回線 |

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────────┐
│  オンプレミス DC           │
│  ┌────────────────────┐  │
│  │ 既存系・取引所接続    │  │
│  │ arrowhead / J-GATE  │  │
│  │ Bloomberg / Refinitiv│  │
│  └─────────┬──────────┘  │
└────────────┼─────────────┘
             │ ExpressRoute (冗長2回線)
             │ ※異なるピアリングロケーション
┌────────────┼────────────────────────────────────────────────────┐
│ Azure      │                                                    │
│  ┌─────────▼──────────┐                                         │
│  │  Hub VNet           │                                         │
│  │  Azure Firewall     │                                         │
│  │  ExpressRoute GW    │                                         │
│  └──┬──────────────┬──┘                                         │
│     │ Peering      │ Peering                                     │
│     ▼              ▼                                             │
│  ┌───────────────────────────┐    ┌────────────────────────────┐ │
│  │ 東日本リージョン (Primary)   │    │ 西日本リージョン (DR)        │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ APIM (Premium)        │ │    │ │ APIM (Premium)         │ │ │
│  │ │ 内部VNet統合            │ │    │ │ (Standby)              │ │ │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │ │
│  │            │               │    │            │                │ │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │ │
│  │ │ AKS Private Cluster   │ │    │ │ AKS Private Cluster    │ │ │
│  │ │ (可用性ゾーン x3)      │ │    │ │ (Warm Standby)         │ │ │
│  │ │ ┌──────┐ ┌──────┐    │ │    │ │ ┌──────┐ ┌──────┐     │ │ │
│  │ │ │Front │ │Middle│    │ │    │ │ │Front │ │Middle│     │ │ │
│  │ │ │Office│ │Office│    │ │    │ │ │Office│ │Office│     │ │ │
│  │ │ │(PPG) │ │      │    │ │    │ │ │(PPG) │ │      │     │ │ │
│  │ │ └──────┘ └──────┘    │ │    │ │ └──────┘ └──────┘     │ │ │
│  │ │ ┌──────┐              │ │    │ │ ┌──────┐              │ │ │
│  │ │ │Back  │              │ │    │ │ │Back  │              │ │ │
│  │ │ │Office│              │ │    │ │ │Office│              │ │ │
│  │ │ └──────┘              │ │    │ │ └──────┘              │ │ │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │ │
│  │            │               │    │            │                │ │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │ │
│  │ │ Azure SQL MI          │ │非同期│ │ Azure SQL MI           │ │ │
│  │ │ Business Critical     │ │─────▶│ │ (Failover Group)       │ │ │
│  │ │ + Ledger テーブル      │ │    │ │ + Ledger テーブル       │ │ │
│  │ │ (可用性ゾーン内同期)    │ │    │ │                        │ │ │
│  │ └──────────────────────┘  │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Cosmos DB             │ │グロ │ │ Cosmos DB              │ │ │
│  │ │ (ポジション管理/       │ │ーバル│ │ (グローバル              │ │ │
│  │ │  セッション管理)       │ │テー │ │  テーブル)              │ │ │
│  │ │ Strong Consistency    │ │ブル │ │                        │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Event Hubs Dedicated  │ │    │ │ Event Hubs Dedicated   │ │ │
│  │ │ (マーケットデータ)      │ │    │ │ (Geo-DR Pair)          │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Azure Data Explorer   │ │    │ │ Azure Data Explorer    │ │ │
│  │ │ (時系列分析)           │ │    │ │ (レプリカ)              │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Azure Batch (HPC)    │ │    │ │ Azure Batch (HPC)      │ │ │
│  │ │ HBv4 / NCv5          │ │    │ │ (Standby Pool)         │ │ │
│  │ │ (リスク計算)           │ │    │ │                        │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Key Vault Managed HSM│ │    │ │ Key Vault Managed HSM  │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  └───────────────────────────┘    └────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ 共通サービス                                                 │  │
│  │ ┌──────────────┐ ┌──────────────┐ ┌─────────────────────┐ │  │
│  │ │ Log Analytics │ │ Sentinel     │ │ Defender for Cloud  │ │  │
│  │ │ Workspace    │ │ (異常取引検知)│ │                     │ │  │
│  │ └──────────────┘ └──────────────┘ └─────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| フロントオフィス (OMS/EMS) | AKS Private Cluster (PPG) | 可用性ゾーン x3、Accelerated Networking | 超低レイテンシの注文執行 |
| ミドルオフィス (リスク計算) | AKS + Azure Batch | HBv4 / NCv5 VM、自動プール | VaR・モンテカルロの大規模並列計算 |
| バックオフィス (決済・照合) | AKS Private Cluster | 可用性ゾーン x3 | バッチ処理・決済指図 |
| API ゲートウェイ | APIM (Premium, Internal VNet) | 東西日本 x2 | 内部API統合・レート制御 |

### データベース

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 約定DB (トランザクション) | Azure SQL MI Business Critical | Failover Group (東西)、Ledger テーブル | ACID 保証 + 改ざん防止 |
| ポジションDB (リアルタイム) | Cosmos DB (Strong Consistency) | グローバルテーブル (東西)、Change Feed | リアルタイムポジション管理 |
| 時系列DB (マーケットデータ) | Azure Data Explorer | ホットキャッシュ 30日、コールド 7年 | ティックデータの高速クエリ・分析 |

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| マーケットデータストリーム | Event Hubs Dedicated | Capacity Unit × N、Capture 有効 | 数百万イベント/秒の安定処理 |
| サービス間非同期連携 | Service Bus Premium | Geo-DR、セッション機能 | 注文→約定→決済の順序保証 |
| ティックデータアーカイブ | Blob Storage (RA-GRS) | WORM ポリシー、不変ストレージ | 規制対応の長期保存 |
| リスク計算中間データ | Blob Storage (ZRS) + Ultra Disk | Batch タスク入出力 | HPC ジョブの高速 I/O |

### セキュリティ

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 暗号鍵管理 | Key Vault Managed HSM | FIPS 140-2 Level 3 | TDE CMK・アプリ暗号鍵の保護 |
| 約定改ざん防止 | SQL MI Ledger テーブル | Append-Only + ダイジェスト外部保管 | 暗号学的改ざん検知 |
| 異常取引検知 | Microsoft Sentinel | カスタム分析ルール + Stream Analytics | 市場操縦・インサイダー取引検知 |
| 特権アクセス管理 | Entra PIM + Break-Glass | JIT (Just-In-Time) アクセス | FISC 実25 準拠 |
| ネットワーク保護 | Azure Firewall Premium | IDS/IPS + TLS インスペクション | FISC 実14 準拠 |

## 可用性・DR設計

### 目標値

| 指標 | 取引時間中 (9:00-15:30) | 取引時間外 |
|------|----------------------|-----------|
| **可用性** | 99.99% | 99.95% |
| **RTO** | < 5分 | < 30分 |
| **RPO** | 0（約定データ損失不可） | < 5秒 |

### 障害レベル別対応

| 障害レベル | 事象 | 対応 | RTO |
|-----------|------|------|-----|
| Level 1 | 単一コンポーネント障害 | AKS Pod 自動再起動、SQL MI AZ 内 FO | < 30秒 |
| Level 2 | 可用性ゾーン障害 | AKS の別 AZ へのトラフィック移行、SQL MI 同期レプリカ FO | < 2分 |
| Level 3 | リージョン障害 | 西日本への Runbook 自動切替（下記フロー参照） | < 5分 |
| Level 4 | 大規模災害 | 取引所側コンティンジェンシー連動、取引所接続の DR 切替 | 取引所指示に従う |

### リージョン切替自動化フロー

```
┌──────────────────────────────────────────┐
│  Step 1: 障害検知                         │
│    外形監視 (3拠点) が東日本リージョン障害を   │
│    検知 → Azure Monitor アラート発火         │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 2: 自動判定                         │
│    Azure Automation Runbook (西日本で実行)  │
│    ※プライマリ障害の影響を受けない場所で判定    │
│    → 複数監視ソースの障害確認 (合意判定)       │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 3: 新規注文受付停止 (アプリケーション閉塞)│
│    APIM ポリシーで新規注文を 503 応答          │
│    ※インフライト注文の完了を待機 (最大30秒)     │
│    ※取引所向け注文は Cancel-On-Disconnect     │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 4: データ層フェイルオーバー            │
│    SQL MI Failover Group → 西日本昇格       │
│    Cosmos DB → 書込リージョン切替             │
│    Event Hubs → Geo-DR フェイルオーバー       │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 5: 取引所接続切替                     │
│    ExpressRoute 経路を西日本側に切替          │
│    取引所セッション再確立 (arrowhead FIX再接続)│
│    ※取引所側コンティンジェンシー手順に準拠      │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 6: ポジション整合性検証               │
│    Cosmos DB ポジションと SQL MI 約定の       │
│    突合チェック (自動リコンサイル)             │
│    → 不整合検出時は該当銘柄の取引を一時停止     │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 7: 注文受付再開                      │
│    西日本 APIM の閉塞解除                    │
│    → 西日本環境の外形監視・ヘルスチェック       │
│    → 切替完了通知 (取引所・顧客・社内)         │
└──────────────────────────────────────────┘
```

> **設計ポイント**: 市場系特有の考慮点として、Step 5 の取引所接続切替が含まれます。取引所（arrowhead 等）との FIX セッション再確立には取引所側のコンティンジェンシー手順との連携が必要であり、事前に取引所との切替手順を合意しておく必要があります。また Step 3 では、インフライト注文を安全に処理完了またはキャンセルしてから切替を行います。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| ティックデータ保存 | Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（規制要件: 7年保存） |
| Ledger ダイジェスト | Azure Confidential Ledger に外部保管（改ざん検知の独立検証用） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

> **注意**: ランサムウェアによりデータを暗号化・使用不能とされた場合の復旧手段として、不変バックアップからの復元を行います。コンプライアンスモードでボールトロックを作成することで、イミュータブルとなり、データ保持期間が終了するまでデータを削除または変更できなくなります。

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| 取引所接続切替訓練 | 取引所コンティンジェンシーテストと連携した年次切替訓練 |
| ポジション整合性検証 | フェイルオーバー後のリコンサイルプロセスの検証 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |
| 負荷テスト併用 | 市場高負荷時（寄り付き・大引け相当）の障害シナリオを検証 |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 市場系 東日本 (10.8.0.0/16)
│               ├── snet-apim      (10.8.0.0/24)  — API Management
│               ├── snet-front     (10.8.1.0/24)  — AKS フロントオフィス (PPG)
│               ├── snet-middle    (10.8.2.0/24)  — AKS ミドルオフィス
│               ├── snet-back      (10.8.3.0/24)  — AKS バックオフィス
│               ├── snet-db        (10.8.4.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-cosmos    (10.8.5.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-batch     (10.8.6.0/23)  — Azure Batch HPC ノード（/23 で拡張）
│               ├── snet-adx       (10.8.8.0/24)  — Azure Data Explorer
│               ├── snet-msg       (10.8.9.0/24)  — Event Hubs / Service Bus PE
│               ├── snet-pe        (10.8.10.0/24) — その他 Private Endpoint
│               └── snet-exchange  (10.8.11.0/24) — 取引所接続用 NVA
│
└── Peering ──▶ Spoke VNet: 市場系 西日本 (10.9.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- snet-front: PPG 内 VM 間の低レイテンシ通信を許可
- snet-batch: Batch ノード間の MPI 通信を許可（HPC ワークロード用）
- snet-exchange: 取引所接続用の専用 NSG ルール（送信元IP制限）
- SQL MI サブネット: SQL MI 専用の NSG ルール適用
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | 市場系APIへの疑似注文照会（残高照会・注文ステータス確認等） |
| テスト頻度 | 1分間隔（取引時間中）、5分間隔（取引時間外） |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

> **設計ポイント**: プライマリリージョンと監視リージョン（第三リージョン）から外形監視を行うことで、リージョン障害の独立した検知を実現します。取引時間中は監視頻度を上げ、障害の早期検知を優先します。

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | 注文 → 約定 → 決済の E2E トレース・レイテンシ分析 |
| サービスマップ | Application Insights Application Map | フロント/ミドル/バックオフィス間の依存関係・ボトルネック可視化 |
| メトリクス収集 | Azure Monitor + Prometheus (AKS) | CPU、メモリ、注文処理数、レイテンシのリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| HPC ジョブ監視 | Azure Batch 診断ログ + カスタムメトリクス | リスク計算ジョブの進捗・完了時間・失敗率 |
| SIEM | Microsoft Sentinel | 異常取引パターン検出・市場操縦監視・セキュリティイベント相関分析 |

> AKS 上の各 Pod にサイドカーコンテナとして OpenTelemetry Collector を配置し、アプリケーションコードの変更なしに分散トレーシングを実現します。特に注文の E2E レイテンシ（注文受付 → 取引所送信 → 約定受信 → ポジション反映）の可視化が市場系の運用上重要です。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| 注文処理レイテンシ | Application Insights | P99 > 10ms（フロントオフィス） |
| リスク計算完了時間 | Azure Batch メトリクス | 日次 VaR 計算がT+0 15:45 までに未完了 |
| ポジション不整合 | カスタムメトリクス | 約定合計とポジション残高の乖離検知 |
| マーケットデータ遅延 | Event Hubs メトリクス | IncomingMessages 途絶 > 5秒 |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor (replication_lag_sec) | > 1秒 |
| フェイルオーバーイベント | Azure SQL MI 診断ログ | FO発生時即時通知 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| 異常取引パターン | Microsoft Sentinel | 短時間大量注文・見せ玉・仮装売買の検知 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |
| HPC ジョブ定義 | Azure Batch のジョブ定義を IaC で管理（プール構成・VM サイズ・自動スケール設定） |

## 関連リソース

- [Azure Well-Architected Framework: Mission-Critical Workloads](https://learn.microsoft.com/azure/well-architected/mission-critical/)
- [Host a Murex MX.3 workload on Azure using Oracle](https://learn.microsoft.com/industry/financial-services/architecture/murex-mx3-azure-content)
- [Host a Murex MX.3 workload on Azure using SQL](https://learn.microsoft.com/industry/financial-services/architecture/murex-mx3-sql-content)
- [Proximity placement groups](https://learn.microsoft.com/azure/virtual-machines/co-location)
- [Azure Event Hubs — Dedicated tier](https://learn.microsoft.com/azure/event-hubs/event-hubs-dedicated-overview)
- [Azure Data Explorer overview](https://learn.microsoft.com/azure/data-explorer/data-explorer-overview)
- [Ledger overview (SQL Server / Azure SQL)](https://learn.microsoft.com/sql/relational-databases/security/ledger/ledger-overview)
- [Azure SQL MI: Failover groups](https://learn.microsoft.com/azure/azure-sql/managed-instance/failover-group-sql-mi)
- [Azure Batch HPC solutions](https://learn.microsoft.com/azure/batch/batch-technical-overview)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
