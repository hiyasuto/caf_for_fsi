# 勘定系システム ランディングゾーン

> 預金・口座管理を担う基幹系コアバンキングシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行の預金・為替・融資等の各種業務を取り扱う勘定系システムを対象としています。チャネル系（インターネットバンキング等）や情報系（DWH/BI等）は各システム別ランディングゾーンを参照してください。
- 本アーキテクチャは [Azure Well-Architected Framework のミッションクリティカルワークロード](https://learn.microsoft.com/azure/well-architected/mission-critical/) ガイダンスに準拠した設計としています。
- オンプレミス環境との接続は ExpressRoute による閉域網接続を前提としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 勘定系システム（コアバンキング） |
| 主な機能 | 預金口座管理、入出金処理、利息計算、残高管理 |
| FISC外部性 | **重大な外部性を有する** — 障害時に他金融機関・顧客に広範な影響 |
| 重要度 | **Tier 1（最高）** |
| 処理特性 | OLTP（高頻度・低レイテンシ）、バッチ処理（日次・月次） |
| 可用性要件 | 99.99%以上（年間ダウンタイム52分以内） |

## ユースケース

- 銀行システムのうち、預金・為替・融資などの各種業務を取り扱う勘定系システムを想定しています。
- 本リファレンスアーキテクチャで示す構成は銀行勘定系に限らず、高い可用性が求められるミッションクリティカルなシステムに応用可能な汎用的なものです。
- トランザクション処理はマイクロサービスアーキテクチャを採用し、各サービス（残高照会、取引処理、口座管理等）を独立してスケーリングできる設計としています。

## FISC基準上の位置づけ

勘定系システムは「重大な外部性を有するシステム」として、FISC基準上最も高い安全対策レベルが要求されます。為替・預金等を取り扱うシステムとして、社会的インフラとしての安定稼働が必須です。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準すべて適用）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実3: **蓄積データの保護** — 預金・口座データの暗号化（TDE + CMK + Always Encrypted）
- 実25〜実27: **アクセス権限管理** — 最小権限・PIM・定期レビュー
- 実34: **外部接続管理** — 対外接続系との連携経路の保護
- 実39〜実45: バックアップ（最高レベル）
- 実71, 実73: DR・コンティンジェンシープラン（最高レベル）
- 設1〜設70: データセンター設備基準（全項目適用）

## アーキテクチャの特徴

### マルチリージョン・ウォームスタンバイ構成

勘定系システムにおけるレイテンシ要件とデータの強整合性を考慮し、**ウォームスタンバイ構成**を採用しています。プライマリリージョン（東日本）で全処理を行い、セカンダリリージョン（西日本）は常時起動状態で待機します。

### マルチロケーション接続

オンプレミスのデータセンターからAzure環境への接続は、ExpressRoute を用いた閉域網接続としています。ExpressRoute 回線は冗長構成（2回線以上）とし、異なるピアリングロケーションを使用することで単一障害点を排除します。

### アプリケーションのコンピューティング環境

フルマネージドコンテナオーケストレーションサービスである **Azure Kubernetes Service (AKS)** をプライベートクラスタとして採用しています。要件に合わせて、AKS の代わりに App Service Environment v3 (ASE v3) や Azure Container Apps を選択することも可能です。

### トランザクション処理パターン

勘定系の取引処理は、**Saga パターン**（オーケストレーション方式）により分散トランザクションを管理します。Microsoft CSE チームの金融トランザクションリファレンスに倣い、**Azure Durable Functions** を Saga オーケストレーターとして採用し、有限ステートマシン（FSM）による状態管理・タイムアウト・リスタートを組込みで実現します。Azure Event Hubs / Service Bus をイベントストリーム基盤として、各マイクロサービス間の非同期連携と補償トランザクションを実現します。

> **設計判断 — Durable Functions の採用理由**: 従来のオーケストレーター実装では、状態管理・タイムアウト・障害時リスタートのカスタム実装が課題となります。Durable Functions はこれらをランタイムレベルで提供し、開発オーバーヘッドを大幅に削減します。AKS 上の各マイクロサービス（残高照会、取引処理、口座管理等）は Saga の参加者として Event Hubs 経由で連携し、Durable Functions がワークフロー全体をオーケストレーションします。

### イベントソーシング・CQRS パターン

勘定系の取引履歴管理には **Event Sourcing** パターンを採用し、全ての状態変更をイベントとして記録します。現在の口座残高は、イベントストリームの再生（リプレイ）により導出可能です。これにより、任意時点の口座状態の再構築、完全な監査証跡、および取引の追跡可能性（トレーサビリティ）を実現します。

**CQRS（Command Query Responsibility Segregation）** パターンを併用し、書き込みモデル（イベントストア）と読み取りモデル（マテリアライズドビュー）を分離します。

```
書き込みパス（Command）:
  取引リクエスト → Durable Functions (Saga) → Event Hubs → イベントストア (Cosmos DB)
                                                              │
読み取りパス（Query）:                                          ▼
  残高照会 ← Redis (キャッシュ) ← マテリアライズドビュー ← イベント投影
```

| パターン | 実装 | 用途 |
|---------|------|------|
| Event Sourcing | Cosmos DB（イベントストア） | 全取引イベントの不変記録。任意時点の状態再構築 |
| CQRS — Write | Durable Functions + Event Hubs | 取引コマンドの処理。Sagaオーケストレーション |
| CQRS — Read | Redis + SQL MI（マテリアライズドビュー） | 残高照会・明細照会の高速応答 |
| Channel Holder | Azure Cache for Redis（Pub/Sub） | 同期API応答と非同期バックエンド処理の橋渡し |

> **Channel Holder パターン**: MS CSE リファレンスでは、API Gateway からの同期リクエストに対して Redis の Pub/Sub を使用して非同期バックエンド処理の結果を待ち受け、呼び出し元に同期応答を返すパターンを採用しています。これにより、バックエンドは完全に非同期でありながら、フロントエンドには同期的なAPI体験を提供します。

> **参考**: [Banking system cloud transformation on Azure](https://learn.microsoft.com/industry/financial-services/architecture/banking-system-cloud-transformation-content) — Microsoft CSE チームによる金融トランザクションシステムのクラウド変革事例
> **参考**: [Patterns and implementations for a banking cloud transformation](https://learn.microsoft.com/industry/financial-services/architecture/patterns-and-implementations-content) — Saga / KEDA / イベントソーシングの実装パターン

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────┐
│  オンプレミス DC        │
│  ┌────────────────┐   │
│  │ 既存系・対外接続  │   │
│  └───────┬────────┘   │
└──────────┼────────────┘
           │ ExpressRoute (冗長2回線)
           │ ※異なるピアリングロケーション
┌──────────┼──────────────────────────────────────────────────┐
│ Azure    │                                                  │
│  ┌───────▼────────┐                                         │
│  │  Hub VNet       │                                         │
│  │  Azure Firewall │                                         │
│  │  ExpressRoute GW│                                         │
│  └──┬──────────┬──┘                                         │
│     │ Peering  │ Peering                                     │
│     ▼          ▼                                             │
│  ┌─────────────────────────┐    ┌──────────────────────────┐ │
│  │ 東日本リージョン (Primary) │    │ 西日本リージョン (DR)      │ │
│  │                         │    │                          │ │
│  │ ┌─────────────────────┐ │    │ ┌──────────────────────┐ │ │
│  │ │ APIM (Premium)      │ │    │ │ APIM (Premium)       │ │ │
│  │ │ 内部VNet統合         │ │    │ │ (Standby)            │ │ │
│  │ └──────────┬──────────┘ │    │ └──────────┬───────────┘ │ │
│  │            │             │    │            │              │ │
│  │ ┌──────────▼──────────┐ │    │ ┌──────────▼───────────┐ │ │
│  │ │ AKS Private Cluster │ │    │ │ AKS Private Cluster  │ │ │
│  │ │ (可用性ゾーン x3)    │ │    │ │ (Warm Standby)       │ │ │
│  │ │ ┌───┐ ┌───┐ ┌───┐  │ │    │ │ ┌───┐ ┌───┐ ┌───┐   │ │ │
│  │ │ │Svc│ │Svc│ │Svc│  │ │    │ │ │Svc│ │Svc│ │Svc│   │ │ │
│  │ │ │ A │ │ B │ │ C │  │ │    │ │ │ A │ │ B │ │ C │   │ │ │
│  │ │ └───┘ └───┘ └───┘  │ │    │ │ └───┘ └───┘ └───┘   │ │ │
│  │ └──────────┬──────────┘ │    │ └──────────┬───────────┘ │ │
│  │            │             │    │            │              │ │
│  │ ┌──────────▼──────────┐ │    │ ┌──────────▼───────────┐ │ │
│  │ │ Azure SQL MI        │ │非同期│ │ Azure SQL MI         │ │ │
│  │ │ Business Critical   │ │─────▶│ │ (Failover Group)     │ │ │
│  │ │ (可用性ゾーン内同期)  │ │    │ │                      │ │ │
│  │ └────────────────────┘  │    │ └──────────────────────┘ │ │
│  │                         │    │                          │ │
│  │ ┌─────────────────────┐ │    │ ┌──────────────────────┐ │ │
│  │ │ Cosmos DB           │ │グロ │ │ Cosmos DB            │ │ │
│  │ │ (ステート管理/       │ │ーバル│ │ (グローバル           │ │ │
│  │ │  セッション管理)     │ │テー │ │  テーブル)            │ │ │
│  │ └─────────────────────┘ │ブル │ └──────────────────────┘ │ │
│  │                         │    │                          │ │
│  │ ┌─────────────────────┐ │    │ ┌──────────────────────┐ │ │
│  │ │ Event Hubs / SB     │ │    │ │ Event Hubs / SB      │ │ │
│  │ │ (Geo-DR)            │ │    │ │ (Geo-DR Pair)        │ │ │
│  │ └─────────────────────┘ │    │ └──────────────────────┘ │ │
│  │                         │    │                          │ │
│  │ ┌─────────────────────┐ │    │ ┌──────────────────────┐ │ │
│  │ │ Key Vault Managed   │ │    │ │ Key Vault Managed    │ │ │
│  │ │ HSM                 │ │    │ │ HSM                  │ │ │
│  │ └─────────────────────┘ │    │ └──────────────────────┘ │ │
│  │                         │    │                          │ │
│  │ ┌─────────────────────┐ │    │ ┌──────────────────────┐ │ │
│  │ │ Redis Enterprise    │ │    │ │ Redis Enterprise     │ │ │
│  │ │ (Active Geo-Rep)    │ │    │ │ (Active Geo-Rep)     │ │ │
│  │ └─────────────────────┘ │    │ └──────────────────────┘ │ │
│  └─────────────────────────┘    └──────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                 監視・自動化 (グローバル)                  │  │
│  │  Log Analytics Workspace | Application Insights         │  │
│  │  Azure Monitor (外形監視) | Microsoft Sentinel          │  │
│  │  Azure Automation (FO 自動化) | Azure Chaos Studio      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| アプリケーション基盤 | AKS (Private Cluster) | 可用性ゾーン3ゾーン、専用ノードプール | 高可用性・マイクロサービス対応・KEDA によるイベント駆動スケーリング |
| 代替コンピューティング | ASE v3 / Azure Container Apps | 可用性ゾーン | コンテナオーケストレーション管理負荷を軽減したい場合 |
| バッチ処理 | Azure Batch / AKS Job | 専用ノードプール | 日次・月次バッチの大量処理 |
| Sagaオーケストレーター | Azure Durable Functions | Premium プラン（VNet統合） | Saga FSM の状態管理・タイムアウト・リスタート |
| API Gateway | Azure API Management (Premium) | 内部VNet統合、可用性ゾーン | API管理・レート制限・バックエンド保護 |

### データベース

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| メインDB | Azure SQL MI Business Critical | 可用性ゾーン + Failover Group | 99.99% SLA・AZ内同期レプリケーション・リージョン間非同期レプリケーション |
| イベントストア | Azure Cosmos DB (NoSQL) | グローバルテーブル（マルチリージョン） | Event Sourcing の不変イベントログ。リージョン切替時にDB切替不要 |
| キャッシュ / Channel Holder | Azure Cache for Redis Enterprise | Active Geo-Replication、可用性ゾーン | 残高キャッシュ・セッション管理・同期応答ブリッジ（Pub/Sub） |
| 監査ログ | Azure SQL Database（Ledger テーブル） | ゾーン冗長 + 長期保持 | 取引ログの改ざん防止。Azure Confidential Ledger との連携で暗号学的証明を付与 |

> **DB構成の設計意図**: メインDB (SQL MI BC) は勘定系のトランザクション処理（ACID特性）に最適化し、イベントストア (Cosmos DB) はイベントソーシングの不変ログとリージョン切替時の切替作業不要化のためにグローバルテーブルを活用します。Ledger テーブルにより、全取引の改ざん不可能な監査証跡を自動生成します。

> **SQL MI Business Critical を選定した理由**:
> - **ローカルSSD**: Business Critical は4ノードクラスタ全てでローカルSSDを使用し、OLTPに最適な低レイテンシI/Oを実現します。Hyperscale はページサーバーによる分散ストレージのため、書き込みレイテンシでBCが優位です。
> - **Failover Group の成熟度**: BCのFailover Groupはクロスリージョンの自動フェイルオーバーに完全対応しており、ミッションクリティカルワークロードでの実績が豊富です。
> - **読み取りスケールアウト**: BCは無料の読み取り専用レプリカを提供し、`ApplicationIntent=ReadOnly` 接続で勘定照会の負荷を分離できます。
> - **In-Memory OLTP**: BCは [In-Memory OLTP](https://learn.microsoft.com/azure/azure-sql/managed-instance/in-memory-oltp-overview) をサポートしており、高頻度取引処理（入出金処理、残高更新等）をメモリ最適化テーブルで高速化できます。ピーク時の処理スループットを10〜30倍に向上させる可能性があります。
> - **Hyperscale が適するケース**: データ量が数TB〜100TB超に達する場合や、OLAP/分析比率が高い場合は Hyperscale が適しますが、勘定系のOLTPワークロードにはBCが最適です。

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| ファイルストレージ | Azure Blob Storage (ZRS) | ゾーン冗長 | バッチファイル・帳票 |
| メッセージキュー | Azure Service Bus Premium | 可用性ゾーン + Geo-DR | トランザクション連携・補償トランザクション |
| イベントストリーム | Azure Event Hubs | 可用性ゾーン + Geo-DR | 取引イベントのストリーム処理・KEDA連携 |

### セキュリティ

| コンポーネント | Azureサービス | FISC基準 |
|-------------|-------------|---------|
| 暗号鍵管理 | Azure Key Vault Managed HSM | 実13（FIPS 140-2 Level 3） |
| DB暗号化 | TDE + 顧客管理キー（CMK） | 実3（蓄積データ保護） |
| ネットワーク分離 | Private Endpoint + NSG | 実15（接続機器最小化） |
| WAF | Azure Front Door WAF | 実14（不正侵入防止） |
| DDoS | Azure DDoS Protection Standard | 実14（不正侵入防止） |
| コンテナセキュリティ | Microsoft Defender for Containers | 実14（コンテナイメージ脆弱性スキャン） |
| Confidential Computing | DCsv3 VM / Always Encrypted with Secure Enclaves | 実3（最高機密データの処理中暗号化） |

> **Confidential Computing（オプション）**: 勘定系の最高機密データ（口座残高、取引明細等）に対して、処理中（In-Use）の暗号化が必要な場合は [Azure Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/overview) の採用を検討してください。Always Encrypted with Secure Enclaves により、SQL MI 上でデータを復号せずにクエリ実行が可能です。AKS ノードに Confidential VM（DCsv3）を使用することで、アプリケーションメモリの暗号化も実現できます。

### デプロイメントスタンプ（Scale Unit）

Microsoft の [ミッションクリティカルワークロードガイダンス](https://learn.microsoft.com/azure/well-architected/mission-critical/mission-critical-application-design#scale-unit-architecture) では、**Deployment Stamp（デプロイメントスタンプ）/ Scale Unit** パターンを推奨しています。各スタンプは独立してデプロイ・スケール可能な論理単位であり、以下のメリットがあります。

- **ゼロダウンタイムデプロイ**: 新スタンプを並行デプロイし、検証後にトラフィックを切替
- **障害分離**: スタンプ間の障害影響を局所化
- **段階的スケーリング**: スタンプ単位でのキャパシティ追加

```
           Azure Front Door
          ┌─────┼─────┐
          ▼     ▼     ▼
       Stamp A  Stamp B  Stamp C
       (v2.1)  (v2.1)   (v2.2 カナリア)
         │       │        │
     ┌───┴───┐ ┌─┴──┐  ┌──┴──┐
     │AKS+DB │ │AKS │  │AKS  │
     │+Redis │ │+DB │  │+DB  │
     └───────┘ └────┘  └─────┘
```

> **適用の判断**: 勘定系の規模・成熟度に応じて段階的に導入します。初期構成では単一スタンプのマルチリージョン構成（本ドキュメントの基本構成）から開始し、スケール要件や無停止デプロイ要件の高まりに応じてマルチスタンプ構成へ移行することを推奨します。

## 可用性・DR設計

### 目標値

| 要件 | 設計 |
|------|------|
| **RTO** | < 5分（AZ内自動FO）/ < 5分（リージョン間自動切替 ※後述の自動化フロー適用時） |
| **RPO** | ≈ 0（AZ内同期レプリケーション）/ < 5秒（リージョン間非同期レプリケーション） |

> **RPOに関する注意**: Failover Group はリージョン間で非同期レプリケーションを使用するため、通常は1秒以内でレプリケーションされますが、障害復旧時のレプリケーションラグについては業務要件やアプリケーションの特性を踏まえて別途考慮が必要です。データ損失を完全に排除する必要がある場合は、`sp_wait_for_database_copy_sync` を使用してコミットスレッドをブロックし、セカンダリへの反映を確認する方式も検討してください。

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一ノード障害 | AKS セルフヒーリング / SQL MI AZ内自動FO | < 1分 | 0 |
| 可用性ゾーン障害 | SQL MI Business Critical AZ間自動FO + AKS マルチAZ | < 5分 | 0 |
| リージョン障害 | 自動切替フロー（後述）による西日本への切替 | < 5分 | < 5秒 |
| ランサムウェア・データ破壊 | 不変バックアップからの復元 | 業務判断 | PITR設定に依存 |

### リージョン切替の自動化フロー

リージョン切替は、データの整合性を確保するための**アプリケーション閉塞**を含む一連の手順を **Azure Automation Runbook** で自動化します。切替を確実に実行するため、フェイルオーバーの自動化ロジックは**障害の影響を受けていないセカンダリリージョン（西日本）で実行**します。

```
┌─ 外形監視（東日本 + 西日本 + 第三リージョンから実施）─┐
│  Application Insights 可用性テスト                    │
│  (複数ロケーションからの合成トランザクション)            │
└──────────────────┬───────────────────────────────────┘
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
│  Step 1: アプリケーション閉塞              │
│    → APIM でインバウンドリクエストを遮断    │
│    → 処理中トランザクションの完了を待機      │
│                                          │
│  Step 2: データ同期確認                    │
│    → SQL MI replication_lag_sec 確認       │
│    → 未同期データがある場合は強制FO判断      │
│                                          │
│  Step 3: SQL MI Failover Group 切替       │
│    → 計画的フェイルオーバー or 強制FO        │
│                                          │
│  Step 4: アプリケーション切替               │
│    → 西日本 AKS クラスタの本番昇格          │
│    → APIM の閉塞解除（西日本側）            │
│                                          │
│  Step 5: DNS / トラフィック切替             │
│    → Azure Front Door のバックエンド変更    │
│    → ExpressRoute のルーティング変更        │
│                                          │
│  Step 6: 正常性確認                        │
│    → 西日本環境の外形監視・ヘルスチェック     │
│    → 切替完了通知                          │
└──────────────────────────────────────────┘
```

> **設計ポイント**: 外形監視の判定を複数リージョンから行うことで、ネットワーク経路の局所障害による誤検知を防止します。自動フェイルオーバーを有効化する場合は、無効化状態で保持し、明示的に有効化する運用も選択できます（オプトイン方式）。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| 長期保存 | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

> **注意**: ランサムウェアによりデータを暗号化・使用不能とされた場合の復旧手段として、不変バックアップからの復元を行います。コンプライアンスモードでボールトロックを作成することで、イミュータブルとなり、データ保持期間が終了するまでデータを削除または変更できなくなります。

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |
| 負荷テスト併用 | 障害注入と負荷テストを同時実行し、障害時のシステム挙動を検証 |
| 訓練内容 | DNS障害注入、AZ障害シミュレーション、DB フェイルオーバー、ネットワーク分断 |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 勘定系 東日本 (10.1.0.0/16)
│               ├── snet-apim      (10.1.0.0/24)  — API Management
│               ├── snet-app       (10.1.1.0/24)  — AKS ノード
│               ├── snet-db        (10.1.2.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-cosmos    (10.1.3.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-cache     (10.1.4.0/24)  — Redis Enterprise
│               ├── snet-msg       (10.1.5.0/24)  — Service Bus / Event Hubs PE
│               ├── snet-pe        (10.1.6.0/24)  — その他 Private Endpoint
│               └── snet-batch     (10.1.7.0/24)  — バッチ処理ノード
│
└── Peering ──▶ Spoke VNet: 勘定系 西日本 (10.2.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- サブネット間: 必要最小限のポートのみ許可
- SQL MI サブネット: SQL MI 専用の NSG ルール適用
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | 勘定系APIへの疑似トランザクション（残高照会等） |
| テスト頻度 | 1〜5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

> **設計ポイント**: プライマリリージョンと監視リージョン（第三リージョン）から外形監視を行うことで、リージョン障害の独立した検知を実現します。

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | マイクロサービス間のリクエストトレース・レイテンシ分析 |
| サービスマップ | Application Insights Application Map | サービス間依存関係・ボトルネック・障害ホットスポットの可視化 |
| メトリクス収集 | Azure Monitor + Prometheus (AKS) | CPU、メモリ、リクエスト数、エラー率のリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 異常取引パターン検出・セキュリティイベント相関分析 |

> AKS 上の各 Pod にサイドカーコンテナとして OpenTelemetry Collector を配置し、アプリケーションコードの変更なしに分散トレーシングを実現します。Application Map により、勘定系の各マイクロサービス（残高照会、取引処理、口座管理等）の相互関係と健全性を一目で把握できます。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| トランザクション応答時間 | Application Insights | P99 > 500ms |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor (replication_lag_sec) | > 1秒 |
| バッチ処理遅延 | Azure Monitor カスタムメトリクス | スケジュール超過 |
| フェイルオーバーイベント | Azure SQL MI 診断ログ | FO発生時即時通知 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| 異常取引パターン | Microsoft Sentinel | カスタム検出ルール |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |

## 関連リソース

- [Azure Well-Architected Framework: Mission-Critical Workloads](https://learn.microsoft.com/azure/well-architected/mission-critical/)
- [Mission-Critical Workload: Scale-Unit Architecture](https://learn.microsoft.com/azure/well-architected/mission-critical/mission-critical-application-design#scale-unit-architecture)
- [Banking system cloud transformation on Azure](https://learn.microsoft.com/industry/financial-services/architecture/banking-system-cloud-transformation-content)
- [Patterns and implementations for a banking cloud transformation](https://learn.microsoft.com/industry/financial-services/architecture/patterns-and-implementations-content)
- [Saga distributed transactions pattern](https://learn.microsoft.com/azure/architecture/patterns/saga)
- [CQRS pattern](https://learn.microsoft.com/azure/architecture/patterns/cqrs)
- [Event Sourcing pattern](https://learn.microsoft.com/azure/architecture/patterns/event-sourcing)
- [Azure SQL MI: High availability and disaster recovery checklist](https://learn.microsoft.com/azure/reliability/reliability-sql-managed-instance)
- [Azure SQL MI: Failover groups](https://learn.microsoft.com/azure/azure-sql/managed-instance/failover-group-sql-mi)
- [Azure SQL MI: In-Memory OLTP](https://learn.microsoft.com/azure/azure-sql/managed-instance/in-memory-oltp-overview)
- [Azure SQL Database Ledger](https://learn.microsoft.com/azure/azure-sql/database/ledger-overview)
- [Azure Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/overview)
- [Azure Durable Functions: Overview](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
- [Architecture strategies for availability zones and regions](https://learn.microsoft.com/azure/well-architected/design-guides/regions-availability-zones)
