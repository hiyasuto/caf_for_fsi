# 対外接続系システム ランディングゾーン

> 全銀ネット・日銀ネット・SWIFT等との接続を担うシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行の対外接続基盤として全銀ネット・日銀ネット（BOJ-NET）・SWIFT・CAFIS 等の金融インフラへの接続を担うシステムを対象としています。
- 対外接続系は金融システム全体のハブとして機能するため、勘定系・為替決済系・市場系等の個別ランディングゾーンからの電文中継を一元的に管理します。
- 本アーキテクチャは [Azure Well-Architected Framework のミッションクリティカルワークロード](https://learn.microsoft.com/azure/well-architected/mission-critical/) ガイダンスに準拠した設計としています。
- オンプレミス環境・金融インフラとの接続は ExpressRoute による閉域網接続を前提とし、最大耐障害性（Maximum Resiliency）構成を推奨しています。
- SWIFT 接続については、Azure 上に展開する **Alliance Connect Virtual (vSRX HA)** 構成を前提としています。

> **参考**: [SWIFT Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-on-azure-vsrx-content) — Microsoft による SWIFT 接続の Azure リファレンスアーキテクチャ

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 対外接続系システム（外部ネットワーク接続基盤） |
| 主な機能 | 全銀ネット中継、日銀ネット接続、SWIFT接続、CAFIS接続、でんさいネット接続、証券取引所接続 |
| FISC外部性 | **重大な外部性を有する** — 金融インフラへの直接接続 |
| 重要度 | **Tier 1（最高）** |
| 処理特性 | 電文中継（リアルタイム）、ファイル転送（バッチ）、プロトコル変換 |
| 可用性要件 | 99.99%以上（年間ダウンタイム52分以内） |

## ユースケース

- 銀行の全銀ネット（内国為替）・日銀ネット（当座預金・国債）・SWIFT（海外送金）を統合した対外電文中継基盤を想定しています。
- 各金融インフラとの接続点を集約し、電文フォーマット変換（全銀フォーマット ↔ ISO 20022 ↔ SWIFT MT/MX）・ルーティング制御・監査ログ管理を一元的に行います。
- CAFIS（クレジットカード決済ネットワーク）やでんさいネット（電子記録債権）等のインフラ接続も本ランディングゾーンで管理します。
- **ISO 20022 移行**（全銀 2025 年、SWIFT 2025 年完了予定）に対応したフォーマット変換・マッピング機能を含みます。

## FISC基準上の位置づけ

対外接続系は「外部接続」に関する FISC 実務基準が直接適用され、金融インフラへの接続点として**最高レベル**のセキュリティと可用性が要求されます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準すべて適用）
- 統20〜統24: **外部委託統制**（接続先との契約・監査・インシデント対応）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実34: **外部ネットワークとの接続** — 接続点のセキュリティ対策（最重要）
- 実39〜実45: バックアップ（最高レベル — 電文損失不可）
- 実71, 実73: DR・コンティンジェンシープラン（接続先との連携切替手順を含む）
- 設1〜設70: データセンター設備基準（全項目適用）

**対外接続系固有の追加要件**:
- 実4, 実13: **電文の暗号化・鍵管理** — 回線暗号化 + アプリケーション層暗号化の二重保護
- 実5: **電文の改ざん防止** — MAC（メッセージ認証コード）生成・検証、Ledger テーブルによる監査証跡
- 実10: **全電文の監査ログ** — 不変ストレージへの長期保存（10年以上）
- 統1（経済安全保障推進法）: **特定重要設備の届出対応** — 対外接続系は基幹インフラ役務に該当する可能性

## アーキテクチャの特徴

### 接続先別ネットワーク分離（専用サブスクリプション / 専用 VNet）

対外接続系は接続先ごとにネットワークセグメントを厳密に分離し、相互のトラフィックが混在しない設計としています。特に **SWIFT 接続は専用サブスクリプション**で分離し、SWIFT CSP-CSCF（Customer Security Programme - Customer Security Controls Framework）の要件に準拠します。

| 接続先 | 分離レベル | 理由 |
|-------|-----------|------|
| SWIFT | **専用サブスクリプション** + 専用 VNet | SWIFT CSP-CSCF 要件（セキュアゾーン分離） |
| 全銀ネット | 専用サブネット + 専用 NSG | 国内為替インフラの保護 |
| 日銀ネット (BOJ-NET) | 専用サブネット + 専用 NSG | 中央銀行接続の最高レベル保護 |
| CAFIS | 専用サブネット + 専用 NSG | カード決済ネットワークの PCI DSS 対応 |
| でんさいネット | 専用サブネット + 専用 NSG | 電子記録債権インフラ |

> **参考**: [SWIFT Alliance Access with Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-alliance-access-vsrx-on-azure-content) — SWIFT 専用サブスクリプション構成の詳細

### SWIFT 接続アーキテクチャ（Alliance Connect Virtual）

Azure 上で SWIFT 接続を実現するため、**Alliance Connect Virtual (vSRX HA)** を展開します。SWIFT CSP-CSCF 準拠のため、以下の構成を採用します。

| コンポーネント | 構成 | 備考 |
|-------------|------|------|
| Alliance Connect Virtual | Juniper vSRX × 2 (HA)、異なる AZ に配置 | MVSIPN 接続 |
| Alliance Access / Gateway | Azure VM × 2 (HA) | SWIFT メッセージング |
| SWIFTNet Link (SNL) | Alliance Access VM 上に同居 | SWIFTNet 接続 |
| SWIFT HSM | オンプレミス設置（CSP-CSCF 要件） | 暗号鍵の物理保護 |
| ExpressRoute | 専用回線 (Gold/Silver パッケージ) | MVSIPN 接続 |

```
┌─────────────────────────────────────────────────────────┐
│ SWIFT 専用サブスクリプション                                │
│                                                         │
│ ┌──────────────────────────────────────────────────────┐│
│ │ Alliance Connect Virtual VNet                        ││
│ │ ┌────────────────┐  ┌────────────────┐              ││
│ │ │ vSRX-1 (AZ 1)  │  │ vSRX-2 (AZ 2)  │  ← HA構成   ││
│ │ └───────┬────────┘  └───────┬────────┘              ││
│ │         │ Trust Zone        │                        ││
│ │ ┌───────▼───────────────────▼────────┐              ││
│ │ │ Alliance Access / Gateway (HA)     │              ││
│ │ │ + SWIFTNet Link                    │              ││
│ │ └───────────────────┬────────────────┘              ││
│ └─────────────────────│────────────────────────────────┘│
│                       │ VNet Peering                    │
│ ┌─────────────────────▼────────────────────────────────┐│
│ │ 対外接続系 Spoke VNet (電文変換・ルーティング)          ││
│ └──────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
       │                              │
       │ ExpressRoute (MVSIPN)        │ ExpressRoute (オンプレミス)
       ▼                              ▼
  SWIFTNet                     オンプレミス DC (SWIFT HSM)
```

> **設計ポイント**: SWIFT HSM は CSP-CSCF 要件によりオンプレミスまたはコロケーション施設に物理設置が必要です。Azure Payment HSM は決済用途の HSM であり、SWIFT HSM とは異なります。SWIFT HSM とAzure 上の Alliance Access 間の接続は ExpressRoute 経由で行います。

### ExpressRoute 最大耐障害性構成（Maximum Resiliency）

対外接続系は金融インフラとの接続を担うため、ExpressRoute の**最大耐障害性（Maximum Resiliency）**構成を採用します。これは異なるピアリングロケーションに 2 回線を配置し、各回線が 2 つの接続を持つ構成です。

```
オンプレミス DC
├── ER Circuit 1 ─── ピアリングロケーション A ───┐
│   (接続1 + 接続2)                              │
│                                                ├──▶ ExpressRoute GW (Zone-Redundant)
├── ER Circuit 2 ─── ピアリングロケーション B ───┘       │
│   (接続1 + 接続2)                                     │
│                                                       ▼
└── S2S VPN (バックアップ) ──────────────────────▶ VPN GW (Zone-Redundant)
```

| 設計要素 | 構成 | 効果 |
|---------|------|------|
| **回線冗長** | 2 回線 × 2 ピアリングロケーション | サイト障害耐性 |
| **ゲートウェイ冗長** | Zone-Redundant ExpressRoute Gateway | AZ 障害耐性 |
| **BFD 有効化** | Bidirectional Forwarding Detection | 高速障害検知 (< 1秒) |
| **VPN バックアップ** | S2S VPN (Zone-Redundant) | ExpressRoute 全断時のバックアップ |
| **帯域確保** | ExpressRoute Direct (必要に応じて) | 専用ポートによる帯域保証 |

> **参考**: [Design and architect Azure ExpressRoute for resiliency](https://learn.microsoft.com/azure/expressroute/design-architecture-for-resiliency) — Maximum Resiliency 構成の詳細

### 電文変換・ルーティングエンジン

各金融インフラとの間で異なる電文フォーマット（全銀フォーマット、ISO 20022、SWIFT MT/MX 等）の変換と、宛先に基づくルーティングを一元管理します。

| コンポーネント | Azure サービス | 機能 |
|-------------|--------------|------|
| 電文変換エンジン | AKS Private Cluster | 全銀 ↔ ISO 20022 ↔ SWIFT MT/MX のフォーマット変換 |
| メッセージルーティング | Service Bus Premium (トピック/サブスクリプション) | 宛先・電文種別に基づくルーティング |
| ISO 20022 マッピング | Logic Apps (SWIFT コネクタ) | SWIFT MX (ISO 20022) の XML 変換・バリデーション |
| 電文バリデーション | AKS マイクロサービス | フォーマット検証、必須項目チェック、重複チェック |
| 冪等性管理 | Cosmos DB | 電文 ID による重複排除（Exactly-Once 保証） |

> **参考**: SWIFT コネクタ付きの Logic Apps により、SWIFT フラット ファイル メッセージを XML に変換し、ドキュメントスキーマに基づくバリデーションを実行できます。

### 暗号化・鍵管理

対外接続系では**回線暗号化**と**アプリケーション層暗号化**の二重保護を実施します。

| 暗号化レイヤー | 実装 | 用途 |
|-------------|------|------|
| 回線暗号化 | ExpressRoute MACsec | レイヤー2レベルの回線暗号化 |
| TLS 通信 | TLS 1.3 (Azure Firewall TLS インスペクション) | アプリケーション間通信 |
| 電文暗号化 | Key Vault Managed HSM (FIPS 140-2 Level 3) | 電文ペイロードの暗号化 |
| MAC 生成・検証 | Key Vault Managed HSM | 電文改ざん検知用の MAC 計算 |
| SWIFT 鍵管理 | SWIFT HSM (オンプレミス) | SWIFT 固有の暗号鍵保護 |
| 決済用鍵管理 | Azure Payment HSM (Thales payShield 10K) | PIN 変換・決済暗号処理 |

> **参考**: [What is Azure Payment HSM?](https://learn.microsoft.com/azure/payment-hsm/overview) — Thales payShield 10K ベースの決済用 HSM

### 電文監査ログ・改ざん防止

金融規制・FISC 基準で求められる全電文の監査証跡を、改ざん不可能な形で長期保存します。

| 項目 | 設計 |
|------|------|
| 電文ログDB | Azure SQL MI Business Critical + **Ledger テーブル** (Append-Only) |
| 改ざん検知 | Ledger テーブルの暗号学的ハッシュチェーンによる改ざん検知 |
| ダイジェスト外部保管 | Azure Confidential Ledger にダイジェストを外部保管 |
| 長期保存 | Blob Storage (RA-GRS) + **不変 (WORM) ポリシー** (10年以上保存) |
| 検証 | `sp_verify_database_ledger` による定期的な改ざん有無検証 |

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────────┐
│  オンプレミス DC           │
│  ┌────────────────────┐  │
│  │ 既存系・対外接続      │  │
│  │ 全銀ネット中継装置    │  │
│  │ 日銀ネット端末        │  │
│  │ SWIFT HSM           │  │
│  └─────────┬──────────┘  │
└────────────┼─────────────┘
             │ ExpressRoute (Maximum Resiliency: 2回線×2ピアリング)
             │ + S2S VPN (バックアップ)
┌────────────┼────────────────────────────────────────────────────┐
│ Azure      │                                                    │
│  ┌─────────▼──────────┐                                         │
│  │  Hub VNet           │                                         │
│  │  Azure Firewall     │                                         │
│  │  ExpressRoute GW    │                                         │
│  │  (Zone-Redundant)   │                                         │
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
│  │ │ ┌───────────────────┐ │ │    │ │ ┌────────────────────┐ │ │ │
│  │ │ │電文変換・ルーティング│ │ │    │ │ │電文変換・ルーティング │ │ │ │
│  │ │ │ISO 20022 マッピング │ │ │    │ │ │ISO 20022 マッピング  │ │ │ │
│  │ │ │電文バリデーション   │ │ │    │ │ │電文バリデーション    │ │ │ │
│  │ │ └───────────────────┘ │ │    │ │ └────────────────────┘ │ │ │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │ │
│  │            │               │    │            │                │ │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │ │
│  │ │ Service Bus Premium   │ │    │ │ Service Bus Premium    │ │ │
│  │ │ (Geo-DR)              │ │    │ │ (Geo-DR Pair)          │ │ │
│  │ │ セッション・順序保証    │ │    │ │                        │ │ │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │ │
│  │            │               │    │            │                │ │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │ │
│  │ │ Azure SQL MI          │ │非同期│ │ Azure SQL MI           │ │ │
│  │ │ Business Critical     │ │─────▶│ │ (Failover Group)       │ │ │
│  │ │ + Ledger テーブル      │ │    │ │ + Ledger テーブル       │ │ │
│  │ │ (電文ログ・監査)       │ │    │ │                        │ │ │
│  │ └──────────────────────┘  │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Cosmos DB             │ │グロ │ │ Cosmos DB              │ │ │
│  │ │ (冪等性管理/           │ │ーバル│ │ (グローバル              │ │ │
│  │ │  セッション管理)       │ │テー │ │  テーブル)              │ │ │
│  │ └───────────────────────┘ │ブル │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Key Vault Managed HSM│ │    │ │ Key Vault Managed HSM  │ │ │
│  │ │ (電文暗号化・MAC)      │ │    │ │                        │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Azure Payment HSM    │ │    │ │ Azure Payment HSM      │ │ │
│  │ │ (PIN変換・決済暗号)    │ │    │ │ (HA Pair)              │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  └───────────────────────────┘    └────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ SWIFT 専用サブスクリプション (東日本)                          │  │
│  │ ┌──────────────────┐ ┌──────────────────────────────────┐ │  │
│  │ │ Alliance Connect │ │ Alliance Access / Gateway (HA)   │ │  │
│  │ │ Virtual (vSRX HA)│ │ + SWIFTNet Link                 │ │  │
│  │ └──────────────────┘ └──────────────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ 共通サービス                                                 │  │
│  │ ┌──────────────┐ ┌──────────────┐ ┌─────────────────────┐ │  │
│  │ │ Log Analytics │ │ Sentinel     │ │ Defender for Cloud  │ │  │
│  │ │ Workspace    │ │ (不正電文検知)│ │                     │ │  │
│  │ └──────────────┘ └──────────────┘ └─────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 電文変換・ルーティング | AKS Private Cluster | 可用性ゾーン x3 | フォーマット変換・バリデーションの柔軟なスケーリング |
| ISO 20022 マッピング | Logic Apps (Standard) | VNet 統合、SWIFT コネクタ | SWIFT MX の XML 変換・スキーマバリデーション |
| SWIFT Alliance Access | Azure VM (HA) | 可用性ゾーン × 2、メモリ最適化 | SWIFT メッセージング処理 |
| Alliance Connect Virtual | Juniper vSRX VM (HA) | 可用性ゾーン × 2 | MVSIPN 接続 |
| API ゲートウェイ | APIM (Premium, Internal VNet) | 東西日本 × 2 | 内部 API 統合・レート制御 |

### データベース

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 電文ログ・監査DB | Azure SQL MI Business Critical | Failover Group (東西)、Ledger テーブル | ACID 保証 + 改ざん防止 |
| 冪等性管理 | Cosmos DB (Strong Consistency) | グローバルテーブル (東西)、電文IDベース | 電文の重複排除 (Exactly-Once) |
| 電文ルーティングルール | Cosmos DB | パーティション: 接続先コード | ルーティング定義の低レイテンシ参照 |

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| メッセージルーティング | Service Bus Premium | Geo-DR、セッション機能、トピック/サブスクリプション | 電文の順序保証・トランザクション保証 |
| 電文アーカイブ | Blob Storage (RA-GRS) | WORM ポリシー (10年保存) | 規制対応の長期保存 |
| ダイジェスト保管 | Azure Confidential Ledger | 改ざん不可能なダイジェスト保管 | Ledger テーブル検証の独立性確保 |
| ファイル転送 | Blob Storage (ZRS) + AzCopy | SFTP 対応 | バッチファイル転送 (日次・月次) |

### セキュリティ

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 電文暗号化・MAC | Key Vault Managed HSM | FIPS 140-2 Level 3 | 電文ペイロード暗号化・改ざん検知 |
| 決済用暗号処理 | Azure Payment HSM | Thales payShield 10K、HA Pair | PIN変換・カード暗号処理 |
| ネットワーク保護 | Azure Firewall Premium | IDS/IPS + TLS インスペクション | FISC 実14 準拠 |
| SWIFT CSP-CSCF | Azure Policy (SWIFT CSP-CSCF v2022) | 組み込みイニシアティブ | SWIFT セキュリティ統制の自動適用 |
| 特権アクセス管理 | Entra PIM + Break-Glass | JIT + 二人制オペレーション | FISC 実25, 実36 準拠 |

> **参考**: [SWIFT CSP-CSCF v2022 Azure Policy](https://learn.microsoft.com/azure/governance/policy/samples/swift-csp-cscf-2022) — SWIFT CSP-CSCF 統制を Azure Policy で自動適用

## 接続先別の詳細構成

| 接続先 | 接続方式 | 暗号化 | 冗長化 | 電文フォーマット |
|-------|---------|-------|-------|---------------|
| 全銀ネット | ExpressRoute Private Peering | MACsec + アプリ層暗号 | 2回線 (異なるピアリング) | 全銀フォーマット → ISO 20022 (移行中) |
| 日銀ネット (BOJ-NET) | ExpressRoute Private Peering | 専用暗号装置 | 2回線 (異なるピアリング) | ISO 20022 |
| SWIFT | Alliance Connect Virtual (vSRX HA) | SWIFT CSP 準拠 | Gold/Silver パッケージ (Active-Active) | SWIFT MT → MX (ISO 20022 移行) |
| CAFIS | ExpressRoute Private Peering | MACsec + TLS 1.3 | 2回線 | ISO 8583 |
| でんさいネット | ExpressRoute Private Peering | MACsec + TLS 1.3 | 2回線 | 全銀フォーマット |
| 証券取引所 | ExpressRoute Private Peering | MACsec | 2回線 | FIX / arrowhead 独自 |

## 可用性・DR設計

### 目標値

| 指標 | 目標 |
|------|------|
| **可用性** | 99.99%（年間ダウンタイム52分以内） |
| **RTO** | < 5分 |
| **RPO** | 0（電文損失不可） |

### 障害レベル別対応

| 障害レベル | 事象 | 対応 | RTO |
|-----------|------|------|-----|
| Level 1 | 単一コンポーネント障害 | AKS Pod 自動再起動、SQL MI AZ 内 FO | < 30秒 |
| Level 2 | 可用性ゾーン障害 | AKS の別 AZ へのトラフィック移行、SQL MI 同期レプリカ FO | < 2分 |
| Level 3 | リージョン障害 | 西日本への Runbook 自動切替（下記フロー参照） | < 5分 |
| Level 4 | ExpressRoute 全断 | S2S VPN バックアップ回線への自動切替 | < 3分 |
| Level 5 | 大規模災害 | 接続先（全銀・日銀・SWIFT）のコンティンジェンシー連動 | 接続先指示に従う |

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
│  Step 3: 電文受付停止 (アプリケーション閉塞)  │
│    APIM ポリシーで新規電文を 503 応答         │
│    ※インフライト電文の処理完了を待機 (最大60秒) │
│    ※Service Bus DLQ への未処理電文退避        │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 4: データ層フェイルオーバー            │
│    SQL MI Failover Group → 西日本昇格       │
│    Cosmos DB → 書込リージョン切替             │
│    Service Bus → Geo-DR フェイルオーバー      │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 5: 対外接続経路切替                   │
│    ExpressRoute 経路を西日本側に切替          │
│    全銀・日銀・CAFIS セッション再確立          │
│    SWIFT Alliance Connect → DR サイト切替    │
│    ※各接続先のコンティンジェンシー手順に準拠    │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 6: 電文整合性検証                     │
│    DLQ 電文の再処理                          │
│    送受信電文の突合チェック (自動リコンサイル)   │
│    → 不整合検出時は該当接続先への送信を一時停止  │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 7: 電文受付再開                      │
│    西日本 APIM の閉塞解除                    │
│    → 西日本環境の外形監視・ヘルスチェック       │
│    → 切替完了通知 (接続先・社内・監督当局)     │
└──────────────────────────────────────────┘
```

> **設計ポイント**: 対外接続系のフェイルオーバーでは、Step 5 の対外接続経路切替が最も重要です。全銀ネット・日銀ネット・SWIFT それぞれで DR 切替手順が異なるため、事前に各接続先との切替手順を合意し、定期的に切替訓練を実施する必要があります。SWIFT については Alliance Connect Virtual の DR サイト構成（別リージョンの vSRX HA ペア）により切替を自動化できます。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| 電文アーカイブ | Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（10年以上保存） |
| Ledger ダイジェスト | Azure Confidential Ledger に外部保管（改ざん検知の独立検証用） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

> **注意**: ランサムウェアによりデータを暗号化・使用不能とされた場合の復旧手段として、不変バックアップからの復元を行います。コンプライアンスモードでボールトロックを作成することで、イミュータブルとなり、データ保持期間が終了するまでデータを削除または変更できなくなります。

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| 対外接続切替訓練 | 全銀・日銀・SWIFT の各接続先とのコンティンジェンシーテスト（年次） |
| ExpressRoute 障害訓練 | 回線障害シミュレーション + VPN バックアップ切替検証（半期） |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |
| 負荷テスト併用 | ピーク時（月末・賞与日等）相当の電文量での障害シナリオを検証 |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway (Zone-Redundant) + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 対外接続系 東日本 (10.10.0.0/16)
│               ├── snet-apim       (10.10.0.0/24)  — API Management
│               ├── snet-app        (10.10.1.0/24)  — AKS 電文変換・ルーティング
│               ├── snet-db         (10.10.2.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-cosmos     (10.10.3.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-msg        (10.10.4.0/24)  — Service Bus PE
│               ├── snet-phsm       (10.10.5.0/24)  — Payment HSM サブネット（専用委任）
│               ├── snet-phsm-mgmt  (10.10.6.0/24)  — Payment HSM 管理サブネット
│               ├── snet-zengin     (10.10.7.0/24)  — 全銀ネット接続用 NVA
│               ├── snet-bojnet     (10.10.8.0/24)  — 日銀ネット接続用 NVA
│               ├── snet-cafis      (10.10.9.0/24)  — CAFIS 接続用 NVA
│               ├── snet-pe         (10.10.10.0/24) — その他 Private Endpoint
│               └── snet-logic      (10.10.11.0/24) — Logic Apps (VNet 統合)
│
├── Peering ──▶ Spoke VNet: 対外接続系 西日本 (10.11.0.0/16)
│               ├── (同一サブネット構成)
│               └── ...
│
└── Peering ──▶ SWIFT 専用 VNet: 東日本 (10.12.0.0/16)
                ├── snet-swift-trust   (10.12.0.0/24)  — Alliance Access / Gateway
                ├── snet-swift-untrust (10.12.1.0/24)  — vSRX Untrust Zone
                ├── snet-swift-mgmt    (10.12.2.0/24)  — 管理サブネット
                └── snet-swift-ha      (10.12.3.0/24)  — vSRX HA Interconnect

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- 接続先別サブネット: 接続先固有の IP レンジのみ許可（最小権限）
- SWIFT VNet: CSP-CSCF 準拠の厳格な NSG（セキュアゾーン分離）
- Payment HSM サブネット: 専用委任 + 専用 NSG
- SQL MI サブネット: SQL MI 専用の NSG ルール適用
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | 各接続先への疑似電文送受信（エコーバック / テスト電文） |
| テスト頻度 | 1分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

> **設計ポイント**: プライマリリージョンと監視リージョン（第三リージョン）から外形監視を行うことで、リージョン障害の独立した検知を実現します。各接続先（全銀・日銀・SWIFT 等）ごとに個別の可用性テストを設定し、接続先単位での障害検知を可能にします。

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | 電文の E2E トレース（受信 → 変換 → ルーティング → 送信） |
| サービスマップ | Application Insights Application Map | 接続先ごとの依存関係・ボトルネック可視化 |
| メトリクス収集 | Azure Monitor + Prometheus (AKS) | CPU、メモリ、電文処理数、レイテンシのリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 不正電文検知・セキュリティイベント相関分析 |
| 回線監視 | ExpressRoute Monitor (Network Watcher) | 回線帯域・レイテンシ・パケットロスの監視 |

> AKS 上の各 Pod にサイドカーコンテナとして OpenTelemetry Collector を配置し、アプリケーションコードの変更なしに分散トレーシングを実現します。特に電文の E2E 追跡（受信 → フォーマット変換 → ルーティング → 接続先送信 → 応答受信）の可視化が対外接続系の運用上重要です。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| 電文処理レイテンシ | Application Insights | P99 > 500ms |
| 電文処理エラー率 | Application Insights | エラー率 > 0.1% |
| 接続先応答タイムアウト | カスタムメトリクス | 各接続先ごとの応答タイムアウト検知 |
| Service Bus DLQ | Azure Monitor | Dead Letter メッセージ > 0 |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor (replication_lag_sec) | > 1秒 |
| ExpressRoute 回線状態 | Network Watcher | 回線ダウン / BGP セッション断 |
| フェイルオーバーイベント | Azure SQL MI 診断ログ | FO発生時即時通知 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| 不正電文パターン | Microsoft Sentinel | 異常電文フォーマット・送信元偽装・大量送信の検知 |
| SWIFT CSP 違反 | Azure Policy コンプライアンス | CSP-CSCF 統制の非準拠検知 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |
| SWIFT デプロイ | SWIFT CSP-CSCF 準拠の変更管理手順に従った手動デプロイ |
| Azure Policy | SWIFT CSP-CSCF v2022 組み込みイニシアティブの自動適用 |

## 関連リソース

- [Azure Well-Architected Framework: Mission-Critical Workloads](https://learn.microsoft.com/azure/well-architected/mission-critical/)
- [SWIFT Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-on-azure-vsrx-content)
- [SWIFT Alliance Access with Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-alliance-access-vsrx-on-azure-content)
- [SWIFT Alliance Remote Gateway with Alliance Connect Virtual on Azure](https://learn.microsoft.com/industry/financial-services/architecture/swift-alliance-remote-gateway-with-alliance-connect-virtual-gateway-content)
- [SWIFT CSP-CSCF v2022 Azure Policy](https://learn.microsoft.com/azure/governance/policy/samples/swift-csp-cscf-2022)
- [Design and architect Azure ExpressRoute for resiliency](https://learn.microsoft.com/azure/expressroute/design-architecture-for-resiliency)
- [Azure Payment HSM overview](https://learn.microsoft.com/azure/payment-hsm/overview)
- [Azure SQL MI: Failover groups](https://learn.microsoft.com/azure/azure-sql/managed-instance/failover-group-sql-mi)
- [Ledger overview (SQL Server / Azure SQL)](https://learn.microsoft.com/sql/relational-databases/security/ledger/ledger-overview)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
- [FISC compliance on Microsoft Cloud](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
