# 為替・決済系システム ランディングゾーン

> 内国為替・外国為替・資金決済を担うシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行の内国為替（振込・送金）、外国為替、資金決済等を取り扱う為替・決済系システムを対象としています。勘定系（預金口座管理等）は [core-banking.md](core-banking.md) を参照してください。
- 本アーキテクチャは [Azure Well-Architected Framework のミッションクリティカルワークロード](https://learn.microsoft.com/azure/well-architected/mission-critical/) ガイダンスに準拠した設計としています。
- 対外接続先（全銀ネット、日銀ネット、SWIFT等）との接続は ExpressRoute または専用線による閉域網接続を前提としています。
- SWIFT 接続環境は [SWIFT Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-on-azure-vsrx-content) のリファレンスアーキテクチャに準拠します。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 為替・決済系システム |
| 主な機能 | 内国為替（振込・送金）、外国為替、資金決済、口座振替 |
| FISC外部性 | **重大な外部性を有する** — 金融システム全体への波及リスク |
| 重要度 | **Tier 1（最高）** |
| 処理特性 | リアルタイム処理（仕向・被仕向）+ バッチ処理（全銀ファイル等） |
| 可用性要件 | 99.99%以上（年間ダウンタイム52分以内） |
| 対外接続 | 全銀ネット、日銀ネット（BOJ-NET）、SWIFT、CAFIS |

## ユースケース

- 銀行間の振込・送金処理を担う内国為替システム（仕向・被仕向）を想定しています。
- SWIFT を利用した外国為替送金・国際決済処理を含みます。
- 日銀ネット（BOJ-NET）を通じた資金決済・国債決済を含みます。
- 本リファレンスアーキテクチャの構成は、高い可用性・データ整合性・冪等性が求められるリアルタイムメッセージング処理基盤として、他の金融メッセージング処理にも応用可能です。

## FISC基準上の位置づけ

為替システムは「重大な外部性を有するシステム」の代表例としてFISC基準に明示されています。障害発生時に他の金融機関やその顧客に広く影響を及ぼし、社会全体に経済的損失を与える可能性があります。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準すべて適用）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実4, 実13: 電文の暗号化・署名（Payment HSM による対応）
- 実39〜実45: バックアップ（最高レベル）
- 実71, 実73: DR・コンティンジェンシープラン（最高レベル）
- 設1〜設70: データセンター設備基準（全項目適用）

## アーキテクチャの特徴

### マルチリージョン・ウォームスタンバイ構成

為替・決済系システムにおけるレイテンシ要件と電文の整合性・順序保証を考慮し、**ウォームスタンバイ構成**を採用しています。プライマリリージョン（東日本）で全処理を行い、セカンダリリージョン（西日本）は常時起動状態で待機します。

### マルチロケーション接続（対外接続ゲートウェイ）

為替・決済系システムは複数の外部ネットワークとの接続が必要です。オンプレミスのデータセンターに設置された対外接続ゲートウェイを経由して全銀ネット・日銀ネット等と接続し、Azure 環境への接続は ExpressRoute（冗長2回線以上、異なるピアリングロケーション）を使用します。

### SWIFT 接続環境

SWIFT 接続は Azure 上に **SWIFT Alliance Connect Virtual (vSRX)** を高可用性構成（2ノード、異なる可用性ゾーン）で展開し、SWIFTNet への安全な接続を実現します。SWIFT CSP-CSCF（Customer Security Programme - Customer Security Controls Framework）準拠の専用サブスクリプションに分離配置します。

### 電文処理パターン

為替電文の処理は**Saga パターン**（オーケストレーション方式）により分散トランザクションを管理します。全電文に**ユニーク ID** を付与し、**冪等性**を担保することで、障害時のリトライ・再送による重複処理を防止します。

- **仕向処理**: 振込依頼の受付 → 与信チェック → 電文生成・署名 → 対外送信 → 結果記帳
- **被仕向処理**: 電文受信 → フォーマット検証 → 入金処理 → 結果通知

### 電文フォーマット変換

全銀フォーマット、SWIFT MT/MX (ISO 20022)、日銀ネット電文等の異なる電文フォーマット間の変換を、**Azure Logic Apps** の SWIFT コネクタまたは **Azure Functions** で実現します。

> **参考**: [SWIFT Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-on-azure-vsrx-content) — Azure 上での SWIFT 接続リファレンスアーキテクチャ

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────────────────┐
│  オンプレミス DC                    │
│  ┌────────────────────────────┐   │
│  │  対外接続ゲートウェイ          │   │
│  │  ├── 全銀ネット接続           │   │
│  │  ├── 日銀ネット (BOJ-NET)    │   │
│  │  └── CAFIS 接続             │   │
│  └──────────┬─────────────────┘   │
└─────────────┼─────────────────────┘
              │ ExpressRoute (冗長2回線)
              │ ※異なるピアリングロケーション
┌─────────────┼───────────────────────────────────────────────────┐
│ Azure       │                                                   │
│  ┌──────────▼─────────┐                                         │
│  │  Hub VNet            │                                         │
│  │  Azure Firewall      │                                         │
│  │  ExpressRoute GW     │                                         │
│  └──┬───────────┬──────┘                                         │
│     │ Peering   │ Peering                                         │
│     ▼           ▼                                                 │
│  ┌───────────────────────────┐    ┌────────────────────────────┐  │
│  │ 東日本リージョン (Primary)   │    │ 西日本リージョン (DR)        │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ APIM (Premium)        │ │    │ │ APIM (Premium)         │ │  │
│  │ │ 内部VNet統合           │ │    │ │ (Standby)              │ │  │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │  │
│  │            │               │    │            │                │  │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │  │
│  │ │ AKS Private Cluster   │ │    │ │ AKS Private Cluster    │ │  │
│  │ │ (可用性ゾーン x3)      │ │    │ │ (Warm Standby)         │ │  │
│  │ │ ┌──────┐ ┌──────┐    │ │    │ │ ┌──────┐ ┌──────┐     │ │  │
│  │ │ │仕向   │ │被仕向 │    │ │    │ │ │仕向   │ │被仕向 │     │ │  │
│  │ │ │処理   │ │処理   │    │ │    │ │ │処理   │ │処理   │     │ │  │
│  │ │ └──────┘ └──────┘    │ │    │ │ └──────┘ └──────┘     │ │  │
│  │ │ ┌──────┐ ┌──────┐    │ │    │ │ ┌──────┐ ┌──────┐     │ │  │
│  │ │ │電文   │ │記帳   │    │ │    │ │ │電文   │ │記帳   │     │ │  │
│  │ │ │変換   │ │処理   │    │ │    │ │ │変換   │ │処理   │     │ │  │
│  │ │ └──────┘ └──────┘    │ │    │ │ └──────┘ └──────┘     │ │  │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │  │
│  │            │               │    │            │                │  │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │  │
│  │ │ Azure SQL MI          │ │非同期│ │ Azure SQL MI           │ │  │
│  │ │ Business Critical     │ │─────▶│ │ (Failover Group)       │ │  │
│  │ │ (為替台帳DB)           │ │    │ │                        │ │  │
│  │ └──────────────────────┘  │    │ └────────────────────────┘ │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ Cosmos DB             │ │グロ │ │ Cosmos DB              │ │  │
│  │ │ (電文ステート管理/     │ │ーバル│ │ (グローバル             │ │  │
│  │ │  冪等性キー管理)       │ │テー │ │  テーブル)              │ │  │
│  │ └───────────────────────┘ │ブル │ └────────────────────────┘ │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ Service Bus Premium   │ │    │ │ Service Bus Premium    │ │  │
│  │ │ (Geo-DR / セッション)  │ │    │ │ (Geo-DR Pair)          │ │  │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ Event Hubs            │ │    │ │ Event Hubs             │ │  │
│  │ │ (取引イベントストリーム) │ │    │ │ (Geo-DR Pair)          │ │  │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ Azure Payment HSM     │ │    │ │ Azure Payment HSM      │ │  │
│  │ │ (Thales payShield 10K)│ │    │ │ (HA ペア)              │ │  │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ Key Vault Managed HSM │ │    │ │ Key Vault Managed HSM  │ │  │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │  │
│  │                           │    │                            │  │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │  │
│  │ │ Redis Enterprise      │ │    │ │ Redis Enterprise       │ │  │
│  │ │ (Active Geo-Rep)      │ │    │ │ (Active Geo-Rep)       │ │  │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │  │
│  └───────────────────────────┘    └────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────┐             │
│  │  SWIFT 専用サブスクリプション (CSP-CSCF 準拠)       │             │
│  │  ┌─────────────────────┐  ┌────────────────────┐ │             │
│  │  │ Alliance Connect    │  │ Alliance Access /  │ │             │
│  │  │ Virtual (vSRX HA)   │  │ Alliance Lite2     │ │             │
│  │  │ (2ノード・異AZ)      │  │                    │ │             │
│  │  └─────────────────────┘  └────────────────────┘ │             │
│  └──────────────────────────────────────────────────┘             │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │                 監視・自動化 (グローバル)                      │     │
│  │  Log Analytics Workspace | Application Insights           │     │
│  │  Azure Monitor (外形監視) | Microsoft Sentinel            │     │
│  │  Azure Automation (FO 自動化) | Azure Chaos Studio        │     │
│  └──────────────────────────────────────────────────────────┘     │
└───────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 為替処理エンジン | AKS (Private Cluster) | 可用性ゾーン3ゾーン、専用ノードプール | リアルタイム処理・マイクロサービス対応・KEDA によるイベント駆動スケーリング |
| バッチ集中処理 | Azure Batch / AKS Job | 専用プール | 全銀ファイル処理・日次バッチ集中 |
| 電文フォーマット変換 | Azure Functions (Premium) / Logic Apps | VNet統合 | 全銀⇔SWIFT MT/MX (ISO 20022) 等の電文変換。Logic Apps の SWIFT コネクタ活用 |
| API Gateway | Azure API Management (Premium) | 内部VNet統合、可用性ゾーン | API管理・レート制限・バックエンド保護 |

### データベース

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 為替台帳DB | Azure SQL MI Business Critical | 可用性ゾーン + Failover Group | ACID保証・99.99% SLA・AZ内同期レプリケーション |
| 電文ステート管理DB | Azure Cosmos DB (NoSQL) | グローバルテーブル（マルチリージョン） | 電文処理ステート・冪等性キー管理。リージョン切替時にDB切替不要 |
| キャッシュ | Azure Cache for Redis Enterprise | Active Geo-Replication、可用性ゾーン | 電文キャッシュ・セッション管理 |

> **DB構成の設計意図**: 為替台帳DB (SQL MI) は取引記帳のトランザクション処理（ACID特性）に最適化し、電文ステート管理DB (Cosmos DB) は電文の処理ステートと冪等性キー（ユニークID）の管理に使用します。Cosmos DB のグローバルテーブルにより、リージョン切替時の冪等性チェック基盤は切替作業なく継続利用でき、重複処理を確実に防止します。

### メッセージング・ストレージ

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 電文キュー | Azure Service Bus Premium | 可用性ゾーン + Geo-DR + セッション | 電文の**順序保証**・**重複排除**・トランザクションセッション |
| イベントストリーム | Azure Event Hubs | 可用性ゾーン + Geo-DR | 取引イベントのストリーム処理・監査ログ・KEDA連携 |
| ファイルストレージ | Azure Blob Storage (ZRS) | ゾーン冗長 | 全銀バッチファイル・帳票 |
| 監査ログ保存 | Azure Blob Storage (RA-GRS) | 不変 (WORM) ポリシー | 全取引電文の法定保存期間対応（不変ストレージ） |

### セキュリティ

| コンポーネント | Azureサービス | FISC基準 |
|-------------|-------------|---------|
| 決済用HSM | Azure Payment HSM (Thales payShield 10K) | 実4, 実13（PCI PTS HSM v3 / FIPS 140-2 Level 3 準拠） |
| 暗号鍵管理 | Azure Key Vault Managed HSM | 実13（FIPS 140-2 Level 3） |
| DB暗号化 | TDE + 顧客管理キー（CMK） | 実3（蓄積データ保護） |
| 電文暗号化・署名 | Azure Payment HSM による電文署名・暗号化 | 実4（通信データ保護） |
| ネットワーク分離 | Private Endpoint + NSG | 実15（接続機器最小化） |
| WAF | Azure Front Door WAF | 実14（不正侵入防止） |
| DDoS | Azure DDoS Protection Standard | 実14（不正侵入防止） |
| コンテナセキュリティ | Microsoft Defender for Containers | 実14（コンテナイメージ脆弱性スキャン） |
| SWIFT CSP-CSCF | Azure Policy (SWIFT CSP-CSCF ポリシーセット) | SWIFT セキュリティ要件準拠 |

> **Azure Payment HSM**: 決済トランザクション用の専用 HSM として [Azure Payment HSM](https://learn.microsoft.com/azure/payment-hsm/overview) を採用しています。Thales payShield 10K ベースの BareMetal サービスであり、顧客の VNet に直接接続され、顧客が単独で管理制御を行います。PIN 検証、カード認証、電文署名等の暗号化処理に使用します。

### 対外接続

| 接続先 | 接続方式 | Azureサービス | 備考 |
|-------|---------|-------------|------|
| 全銀ネット | 専用線 → ExpressRoute | ExpressRoute + NVA | オンプレミス対外接続GW経由 |
| 日銀ネット (BOJ-NET) | 専用線 → ExpressRoute | ExpressRoute Private Peering | オンプレミス対外接続GW経由 |
| SWIFT | SWIFTNet (MVSIPN) | Alliance Connect Virtual (vSRX) on Azure | Azure上に直接展開。CSP-CSCF準拠の専用サブスクリプション |
| CAFIS | 専用線 → ExpressRoute | ExpressRoute | オンプレミス対外接続GW経由 |

> **SWIFT on Azure の設計ポイント**: SWIFT コンポーネントは CSP-CSCF 準拠のため**専用サブスクリプション**に分離配置します。Alliance Connect Virtual は異なる可用性ゾーンに2ノード展開し、HA VM による監視とルートテーブル制御で高可用性を実現します。

## 可用性・DR設計

### 目標値

| 要件 | 設計 |
|------|------|
| **RTO** | < 5分（AZ内自動FO）/ < 5分（リージョン間自動切替 ※後述の自動化フロー適用時） |
| **RPO** | ≈ 0（AZ内同期レプリケーション）/ < 5秒（リージョン間非同期レプリケーション） |

> **RPOに関する注意**: Failover Group はリージョン間で非同期レプリケーションを使用するため、通常は1秒以内でレプリケーションされますが、障害復旧時のレプリケーションラグについては業務要件を踏まえた考慮が必要です。為替電文の特性上、未同期データがある場合の**インフライト電文の扱い**（補償トランザクション、手動照合等）を事前に設計しておく必要があります。

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一ノード障害 | AKS セルフヒーリング / SQL MI AZ内自動FO | < 1分 | 0 |
| 可用性ゾーン障害 | SQL MI Business Critical AZ間自動FO + AKS マルチAZ | < 5分 | 0 |
| リージョン障害 | 自動切替フロー（後述）による西日本への切替 | < 5分 | < 5秒 |
| ランサムウェア・データ破壊 | 不変バックアップからの復元 | 業務判断 | PITR設定に依存 |

### リージョン切替の自動化フロー

リージョン切替は、**電文の整合性を確保するためのアプリケーション閉塞**を含む一連の手順を **Azure Automation Runbook** で自動化します。切替を確実に実行するため、自動化ロジックは**障害の影響を受けていないセカンダリリージョン（西日本）で実行**します。

```
┌─ 外形監視（東日本 + 西日本 + 第三リージョンから実施）──┐
│  Application Insights 可用性テスト                      │
│  (複数ロケーションからの為替API疑似トランザクション)       │
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
│    → APIM でインバウンド電文受付を遮断          │
│    → 処理中電文（インフライト）の完了を待機      │
│    → Service Bus のキュー残量ドレイン確認       │
│                                              │
│  Step 2: データ同期確認                        │
│    → SQL MI replication_lag_sec 確認           │
│    → Cosmos DB レプリケーション状態確認          │
│    → 未同期電文がある場合は強制FO判断            │
│    → インフライト電文リストの記録（照合用）       │
│                                              │
│  Step 3: SQL MI Failover Group 切替           │
│    → 計画的フェイルオーバー or 強制FO            │
│    ※Cosmos DB グローバルテーブルは切替不要       │
│                                              │
│  Step 4: メッセージング基盤切替                 │
│    → Service Bus Geo-DR フェイルオーバー        │
│    → Event Hubs Geo-DR フェイルオーバー         │
│                                              │
│  Step 5: アプリケーション切替                   │
│    → 西日本 AKS クラスタの本番昇格              │
│    → APIM の閉塞解除（西日本側）                │
│    → 対外接続ルーティングの切替                  │
│                                              │
│  Step 6: DNS / トラフィック切替                 │
│    → ExpressRoute のルーティング変更            │
│    → オンプレミス側 DNS 名前解決の切替           │
│                                              │
│  Step 7: 正常性確認                            │
│    → 西日本環境の外形監視・ヘルスチェック         │
│    → インフライト電文の照合・再送判定            │
│    → 切替完了通知                              │
└──────────────────────────────────────────────┘
```

> **為替系固有の設計ポイント**:
> - **インフライト電文の管理**: フェイルオーバー時に処理途中の電文を記録し、切替後に照合・再送判定を行う仕組みが必要です。冪等性キー（Cosmos DB）により重複処理は防止されます。
> - **対外接続の切替**: 全銀ネット・日銀ネット等への接続はオンプレミス経由のため、ExpressRoute のルーティング変更に加え、対外接続ゲートウェイ側の経路切替も必要です。
> - **SWIFT 接続**: SWIFT Alliance Connect Virtual の HA 構成により、Azure リージョン内の切替は自動で行われますが、リージョン間切替時は SWIFT 側の設定変更が必要な場合があります。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| 電文アーカイブ | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（法定保存期間対応） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

> **注意**: ランサムウェアによりデータを暗号化・使用不能とされた場合の復旧手段として、不変バックアップからの復元を行います。為替電文アーカイブは法定保存期間（最低10年）を考慮し、不変 (WORM) ポリシーを適用した Blob Storage に保存します。

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |
| 負荷テスト併用 | 障害注入と負荷テストを同時実行し、障害時のシステム挙動を検証 |
| 訓練内容 | DNS障害注入、AZ障害シミュレーション、DB フェイルオーバー、ネットワーク分断、電文滞留シミュレーション |
| 対外接続テスト | 全銀ネット・SWIFT との切替テスト（接続先との事前調整要） |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 為替・決済系 東日本 (10.3.0.0/16)
│               ├── snet-apim        (10.3.0.0/24)  — API Management
│               ├── snet-app         (10.3.1.0/24)  — AKS ノード（仕向・被仕向・電文変換・記帳）
│               ├── snet-db          (10.3.2.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-cosmos      (10.3.3.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-cache       (10.3.4.0/24)  — Redis Enterprise
│               ├── snet-msg         (10.3.5.0/24)  — Service Bus / Event Hubs PE
│               ├── snet-pe          (10.3.6.0/24)  — その他 Private Endpoint
│               ├── snet-batch       (10.3.7.0/24)  — バッチ処理ノード
│               ├── snet-phsm-host   (10.3.8.0/24)  — Payment HSM ホストインターフェース
│               └── snet-phsm-mgmt   (10.3.9.0/24)  — Payment HSM 管理インターフェース
│
├── Peering ──▶ Spoke VNet: 為替・決済系 西日本 (10.4.0.0/16)
│               ├── (同一サブネット構成)
│               └── ...
│
└── Peering ──▶ Spoke VNet: SWIFT 専用 (10.5.0.0/16)
                ├── snet-swift-trust    (10.5.0.0/24)  — vSRX Trust ゾーン
                ├── snet-swift-untr     (10.5.1.0/24)  — vSRX Untrust ゾーン
                ├── snet-swift-interc   (10.5.2.0/24)  — vSRX Interconnect
                └── snet-swift-app      (10.5.3.0/24)  — Alliance Access / Lite2

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- サブネット間: 必要最小限のポートのみ許可
- SQL MI サブネット: SQL MI 専用の NSG ルール適用
- Payment HSM サブネット: HSM 専用の厳格な NSG ルール適用
- SWIFT サブネット: SWIFT CSP-CSCF 要件に基づく厳格な分離
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | 為替APIへの疑似トランザクション（振込照会・ステータス確認等） |
| テスト頻度 | 1〜5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

> **設計ポイント**: プライマリリージョンと監視リージョン（第三リージョン）から外形監視を行うことで、リージョン障害の独立した検知を実現します。

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | 仕向・被仕向・電文変換の各マイクロサービス間のリクエストトレース・レイテンシ分析 |
| サービスマップ | Application Insights Application Map | サービス間依存関係（為替処理フロー）のボトルネック・障害ホットスポット可視化 |
| メトリクス収集 | Azure Monitor + Prometheus (AKS) | CPU、メモリ、リクエスト数、エラー率、電文処理件数のリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 異常送金パターン検出・不正為替取引検知・セキュリティイベント相関分析 |

> AKS 上の各 Pod にサイドカーコンテナとして OpenTelemetry Collector を配置し、アプリケーションコードの変更なしに分散トレーシングを実現します。Application Map により、為替系の各マイクロサービス（仕向処理、被仕向処理、電文変換、記帳処理等）の相互関係と健全性を一目で把握できます。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| 電文処理応答時間 | Application Insights | P99 > 500ms |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor (replication_lag_sec) | > 1秒 |
| 電文キュー滞留 | Azure Monitor (Service Bus メトリクス) | アクティブメッセージ数 > 閾値 or デッドレターキュー > 0 |
| バッチ処理遅延 | Azure Monitor カスタムメトリクス | 全銀ファイル処理スケジュール超過 |
| フェイルオーバーイベント | Azure SQL MI 診断ログ | FO発生時即時通知 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| Payment HSM 異常 | Azure Monitor | HSM 応答遅延・接続障害 |
| 異常送金パターン | Microsoft Sentinel | 高額送金・頻度異常・時間外取引等のカスタム検出ルール |
| SWIFT 接続異常 | Azure Monitor カスタムメトリクス | Alliance Connect Virtual 接続ステータス異常 |

## セキュリティ特記事項

| 対策 | 実装 | FISC基準 |
|------|------|---------|
| 電文暗号化・署名 | Azure Payment HSM による PIN 検証・電文署名・暗号化 | 実4, 実13 |
| 冪等性保証 | 全電文にユニーク ID を付与、Cosmos DB で冪等性キー管理 | 実10（取引の正確性保証） |
| 異常取引監視 | Microsoft Sentinel + カスタム分析ルール（高額送金・頻度異常等） | 実17, 実18 |
| アクセス制御 | Entra PIM + JIT + 二人制オペレーション（為替オペレーション） | 実25, 実36 |
| 監査ログ | 全取引電文の不変ログ保存（Azure Storage Immutable WORM） | 実10 |
| SWIFT CSP-CSCF | SWIFT セキュリティ要件準拠のポリシーセット適用・専用サブスクリプション分離 | SWIFT 独自基準 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |
| SWIFT 環境 | SWIFT CSP-CSCF ポリシーセットの自動適用・コンプライアンス監視 |

## 関連リソース

- [Azure Well-Architected Framework: Mission-Critical Workloads](https://learn.microsoft.com/azure/well-architected/mission-critical/)
- [SWIFT Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-on-azure-vsrx-content)
- [SWIFT Alliance Remote Gateway with Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-alliance-remote-gateway-with-alliance-connect-virtual-gateway-content)
- [Azure Payment HSM Overview](https://learn.microsoft.com/azure/payment-hsm/overview)
- [Banking system cloud transformation on Azure](https://learn.microsoft.com/industry/financial-services/architecture/banking-system-cloud-transformation-content)
- [Azure SQL MI: High availability and disaster recovery checklist](https://learn.microsoft.com/azure/reliability/reliability-sql-managed-instance)
- [Azure SQL MI: Failover groups](https://learn.microsoft.com/azure/azure-sql/managed-instance/failover-group-sql-mi)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
- [Architecture strategies for availability zones and regions](https://learn.microsoft.com/azure/well-architected/design-guides/regions-availability-zones)
