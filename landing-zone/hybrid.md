# ハイブリッド構成 ランディングゾーン

> オンプレミスとAzureクラウドを組み合わせたハイブリッドアーキテクチャのFISC準拠設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、オンプレミス環境とAzureクラウドを組み合わせたハイブリッド構成を対象としています。純粋なクラウドワークロードについては各システム別ランディングゾーンを参照してください。
- ハイブリッド構成の中核となる Azure Local（旧 Azure Stack HCI）および Azure Arc による統合管理を前提としています。
- オンプレミス環境とAzure間の接続は **ExpressRoute による閉域網接続**を前提としています。インターネット経由の接続は本アーキテクチャの対象外です。
- ハイブリッド構成では、クラウドとオンプレミスで**責任共有モデルが異なる**点に留意してください。オンプレミスの物理セキュリティ、電源、空調、ネットワーク機器の管理はお客様の責任となります（純粋なクラウドではMicrosoftの責任）。
- 本ドキュメントで示すアーキテクチャは、金融機関における以下のようなハイブリッド要件を想定しています:
  - 超低レイテンシ要件によりオンプレミス配置が必須なワークロード
  - データレジデンシー（データ主権）の制約によりデータの国内オンプレミス保管が必要なケース
  - メインフレーム等の既存基盤との近接配置が必要なシステム
  - 段階的クラウド移行の過渡期におけるハイブリッド運用

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | ハイブリッド構成基盤 |
| 主な機能 | オンプレミスコンピューティング・ストレージとAzure統合管理、データレジデンシー、低レイテンシ処理 |
| FISC外部性 | **配置するワークロードに依存** — 勘定系配置の場合は Tier 1 相当 |
| 重要度 | ワークロードに依存（Tier 1〜3） |
| 処理特性 | ワークロードに依存（OLTP、バッチ、リアルタイム処理等） |
| 可用性要件 | ワークロードに依存（99.9%〜99.99%） |

## ユースケース

### 1. 証券取引システム（低レイテンシ要件）

証券取引所との接続において**マイクロ秒〜ミリ秒レベルの超低レイテンシ**が要求されるシステムでは、取引所近接データセンターへのオンプレミス配置が不可欠です。

- **Azure Local** の Bare-Metal VM を取引所近接データセンターに配置し、超低レイテンシの取引処理を実現
- **Azure Arc** によりオンプレミスのVMをAzureコントロールプレーンに投影し、統合管理・監視・ポリシー適用を実現
- フロントエンド（注文受付・リスク管理ダッシュボード等）はAzureクラウド側に配置し、スケーラビリティを確保
- 取引データのリアルタイム分析・レポーティングはAzureクラウド側の DWH/BI 基盤で実施

### 2. メインフレーム周辺システム

メインフレームとの密接な連携が必要なシステムでは、メインフレームと同一データセンター内にオンプレミス基盤を配置します。

- **Azure Local** がバックエンド処理（メインフレーム連携処理）をホスト
- フロントエンド（Webポータル、API Gateway等）はAzureクラウド側に配置
- **Azure Arc** によりオンプレミスリソースをAzureと統合管理
- メインフレームとの連携パターンの詳細は [メインフレーム連携・移行](mainframe-integration.md) を参照

### 3. データレジデンシー（データ主権）

金融規制やコンプライアンス要件により、特定のデータをオンプレミスに保管する必要がある場合のアーキテクチャです。

- **Azure Local** にデータを保管し、物理的にお客様データセンター内に留置
- **Azure Policy**（Azure Arc経由）により、データのクラウドへの転送を制限するポリシーを強制適用
- **Azure Arc** はメタデータ・インベントリ情報のみを収集し、業務データの抽出は行わない
- バックアップもオンプレミス内で完結（Azure Local ストレッチクラスター）

### 4. オンプレミスDB低レイテンシアクセス

レガシーシステムのオンプレミスデータベースに対して低レイテンシアクセスが必要なアプリケーション層の配置パターンです。

- アプリケーション層を **Azure Local** 上のVMまたは AKS（Arc対応Kubernetes）で稼働
- データベース層はオンプレミスの既存DB（Oracle、SQL Server等）をそのまま利用
- **Azure Arc-enabled SQL Server** によりオンプレミスSQL Serverを Azure で統合管理
- DB移行が完了した段階で、アプリケーション層もAzureクラウドへ段階的に移行可能

### 5. ATM・店舗エッジ

銀行の支店やATM拠点におけるエッジ処理のアーキテクチャです。

- **Azure Stack Edge** または **Azure Local** 小型フォームファクターを店舗/ATM拠点に配置
- 店舗内の取引処理・キャッシュ管理をエッジで実行し、ネットワーク障害時もオフライン継続稼働
- 取引データはネットワーク復旧後にAzureクラウド側へ同期
- **Azure Arc** により全拠点のエッジデバイスを一元管理・監視・パッチ適用

## FISC基準上の位置づけ

ハイブリッド構成では、クラウド部分とオンプレミス部分で**適用されるFISC基準の範囲が異なります**。特にオンプレミス部分は、純粋なクラウド利用時にはクラウド事業者が担保する物理セキュリティ・設備管理をお客様自身が実施する必要があります。

### 責任共有モデルの差異

```
┌─────────────────────────────┬─────────────────────┬─────────────────────┐
│        責任範囲              │  Azureクラウド        │  オンプレミス         │
│                             │  (純粋クラウド利用)    │  (Azure Local等)     │
├─────────────────────────────┼─────────────────────┼─────────────────────┤
│ アプリケーション              │  お客様              │  お客様              │
│ データ                       │  お客様              │  お客様              │
│ OS・ミドルウェア              │  共有（PaaS）/       │  お客様              │
│                             │  お客様（IaaS）       │                     │
│ 仮想化基盤                   │  Microsoft           │  共有（Azure Local）  │
│ 物理サーバー                 │  Microsoft           │  お客様              │
│ ネットワーク機器              │  Microsoft           │  お客様              │
│ データセンター設備             │  Microsoft           │  お客様              │
│ （電源・空調・入退館管理）      │                     │                     │
└─────────────────────────────┴─────────────────────┴─────────────────────┘
```

### 適用される主な基準

**クラウド部分に適用（Azure統合管理）**:
- 統20〜統24: クラウドサービス利用に関するガバナンス — Azure Arc によるポリシー管理
- 実7〜実12: ネットワークセキュリティ — ExpressRoute閉域接続、Azure Firewall
- 実13〜実19: 暗号化 — Azure Key Vault / Managed HSM による鍵管理
- 実25〜実27: アクセス権限管理 — Microsoft Entra ID、PIM、RBAC

**オンプレミス部分に適用**:
- 設1〜設70: データセンター設備基準 — 物理セキュリティ、電源、空調、入退館管理は**お客様が直接管理**
- 実3: 蓄積データの保護 — Azure Local上のBitLocker暗号化 + Azure Key Vault連携
- 実7〜実12: ネットワークセキュリティ — オンプレミスネットワーク機器の管理・FW設定
- 実14: 不正アクセス防止 — Microsoft Defender for Servers（Arc経由）による脅威検知

**ハイブリッド固有の考慮事項**:
- 実34: 外部接続管理 — ExpressRoute経由のクラウド接続経路の保護
- 実39〜実45: バックアップ — オンプレミスとクラウドのバックアップ戦略の整合
- 実71, 実73: DR・コンティンジェンシープラン — ハイブリッド環境横断のDR設計

## アーキテクチャ図

### 全体アーキテクチャ（ハイブリッド構成）

```
┌─ Azure Cloud ─────────────────────────────────────────────┐  ┌─ お客様データセンター ──────────────────────────────────┐
│                                                           │  │                                                        │
│  ┌── Hub VNet (10.0.0.0/16) ──────────────────────┐       │  │  ┌── Azure Local クラスター ──────────────────────────┐ │
│  │  ExpressRoute Gateway                          │       │  │  │                                                    │ │
│  │  Azure Firewall                                │       │  │  │  Azure Arc エージェント（Azure接続）                 │ │
│  │  Azure Bastion                                 │       │  │  │  ┌────────────┐ ┌────────────┐ ┌──────────────┐   │ │
│  │  Azure Monitor (収集)                          │       │  │  │  │ VM ワーク   │ │ AKS        │ │ SQL Server   │   │ │
│  └───────────────┬────────────────────────────────┘       │  │  │  │ ロード     │ │ (Arc対応)  │ │ (Arc対応)    │   │ │
│                  │ Peering                                │  │  │  │            │ │            │ │              │   │ │
│  ┌───────────────▼──────────────────────────────┐         │  │  │  └────────────┘ └────────────┘ └──────────────┘   │ │
│  │  Spoke VNet: Hybrid Azure側 (10.37.0.0/16)   │         │  │  │  Azure Policy (Arc経由で強制適用)                   │ │
│  │  ┌─────────────────┐ ┌─────────────────────┐ │         │  │  │  Microsoft Defender for Cloud (Arc経由)              │ │
│  │  │ Frontend        │ │ Azure SQL           │ │         │  │  │  Azure Monitor Agent (Arc経由)                      │ │
│  │  │ (App Service)   │ │ (DR replica)        │ │         │  │  └────────────────────────────────────────────────────┘ │
│  │  └─────────────────┘ └─────────────────────┘ │         │  │                                                        │
│  │  ┌─────────────────┐ ┌─────────────────────┐ │         │  │  ┌── Azure Stack Edge ────────────────────────────────┐ │
│  │  │ Azure Monitor   │ │ Key Vault           │ │         │  │  │  店舗/ATMエッジ処理                                 │ │
│  │  │ Agent           │ │ (Managed HSM)       │ │         │  │  │  ローカルコンピューティング + IoT Hub Edge            │ │
│  │  └─────────────────┘ └─────────────────────┘ │         │  │  └────────────────────────────────────────────────────┘ │
│  └──────────────────────────────────────────────┘         │  │                                                        │
│                  │                                         │  │  ┌── メインフレーム ──────────────────────────────────┐ │
│                  │ ExpressRoute (冗長2回線)                 │  │  │  COBOL / PL-I アプリケーション                      │ │
│                  │ ※異なるピアリングロケーション              │  │  │  既存データベース (Oracle / DB2 等)                  │ │
│                  │◄───────────────────────────────────────►│  │  └────────────────────────────────────────────────────┘ │
│                                                           │  │                                                        │
│  ┌── Azure Arc Control Plane ─────────────────────┐       │  │  ┌── 既存ネットワーク ─────────────────────────────────┐ │
│  │  Azure Resource Manager (ARM)                  │       │  │  │  L3スイッチ / ファイアウォール                       │ │
│  │  Azure Policy (ハイブリッドポリシー)              │       │  │  │  ExpressRoute 接続ルーター                          │ │
│  │  Microsoft Defender for Cloud                  │       │  │  │  DNSサーバー                                        │ │
│  │  Azure Monitor / Log Analytics                 │       │  │  └────────────────────────────────────────────────────┘ │
│  └────────────────────────────────────────────────┘       │  │                                                        │
└───────────────────────────────────────────────────────────┘  └────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### ハイブリッドインフラ

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| オンプレミスHCI基盤 | Azure Local（旧 Azure Stack HCI） | 2〜16ノードクラスター、Azure Arc接続 | オンプレミスでAzure互換のコンピューティング・ストレージを提供。Azure管理プレーンとの統合 |
| オンプレミスサーバー管理 | Azure Arc-enabled Servers | 全オンプレミスサーバーをArcに投影 | Azure Policy・Defender・Monitorの適用対象としてオンプレミスサーバーを統合管理 |
| オンプレミスSQL管理 | Azure Arc-enabled SQL Server | 既存SQL Serverインスタンスを Arc に登録 | オンプレミスSQL Serverの脆弱性評価・パッチ管理・監視をAzureから一元実施 |
| オンプレミスKubernetes | Azure Arc-enabled Kubernetes / AKS on Azure Local | AKS クラスターを Azure Local 上にデプロイ | コンテナワークロードのオンプレミス実行。GitOps による宣言的デプロイ |
| エッジコンピューティング | Azure Stack Edge | 店舗/ATM拠点にエッジデバイス配置 | 支店・ATM拠点での局所的なコンピューティング・データ処理 |
| VM ライフサイクル管理 | Azure Arc VM management | Azure Local 上のVMをAzureポータルから管理 | VM作成・削除・サイズ変更をAzureポータル/API/IaCから統一的に操作 |

### ネットワーク

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 閉域接続（プライマリ） | ExpressRoute | 冗長2回線、Private Peering、異なるピアリングロケーション | FISC実7〜実12準拠の閉域網接続。単一障害点の排除 |
| 閉域接続（バックアップ） | Azure VPN Gateway | Site-to-Site VPN、冗長構成 | ExpressRoute障害時のバックアップ接続経路 |
| ネットワークセキュリティ | Azure Firewall Premium | Hub VNet に配置、TLS インスペクション | 東西・南北トラフィックの一元的なフィルタリング・ログ記録 |
| プライベート接続 | Azure Private Link / Private Endpoint | 全PaaSサービスにPrivate Endpoint適用 | PaaSサービスへのアクセスをVNet内に閉じ、インターネット経由を排除 |
| DNS | Azure Private DNS Zone | Hub VNet にリンク | Private Endpoint の名前解決。オンプレミスDNSとの条件付きフォワーディング |

### 管理・監視

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 統合監視 | Azure Monitor | Arc エージェントによりオンプレミスからメトリクス・ログ収集 | クラウド・オンプレミス横断の統合監視ダッシュボード |
| ログ分析 | Azure Log Analytics Workspace | 保持期間730日、データエクスポート設定 | FISC実45準拠のログ長期保持。KQLによる横断分析 |
| パッチ管理 | Azure Update Manager | Arc経由でオンプレミスサーバーのパッチ適用 | Windows/Linux サーバーのパッチコンプライアンス一元管理 |
| 自動化 | Azure Automation | Hybrid Runbook Worker をオンプレミスに配置 | オンプレミス環境の運用自動化（バックアップ、メンテナンス等） |
| 構成管理 | Azure Automanage Machine Configuration | Arc経由でOS構成のコンプライアンスチェック | FISC準拠のOS構成（パスワードポリシー、監査設定等）の継続的評価 |

### セキュリティ

| コンポーネント | Azureサービス | FISC基準 | 理由 |
|-------------|-------------|---------|------|
| 統合セキュリティ | Microsoft Defender for Cloud | 実14（不正アクセス防止） | Arc対応リソースを含むハイブリッド環境全体の脅威検知・セキュリティ態勢管理 |
| ポリシー管理 | Azure Policy（Arc経由） | 統20〜統24（ガバナンス） | オンプレミスリソースへのFISC準拠ポリシーの強制適用 |
| 暗号鍵管理 | Azure Key Vault Managed HSM | 実13（FIPS 140-2 Level 3） | Azure Local のBitLocker暗号化鍵、TDE鍵等の一元管理 |
| ID管理 | Microsoft Entra ID | 実25〜実27（アクセス管理） | ハイブリッドID基盤。オンプレミスAD DS との同期（Entra Connect） |
| 特権ID管理 | Microsoft Entra PIM | 実25（最小権限） | Azure・オンプレミス双方の特権アクセスのJIT管理 |
| サーバー保護 | Microsoft Defender for Servers | 実14（不正侵入防止） | Arc経由でオンプレミスサーバーのEDR・脆弱性評価を実現 |
| SIEM | Microsoft Sentinel | 実14（セキュリティ監視） | ハイブリッド環境横断のセキュリティイベント相関分析・異常検知 |

### バックアップ・DR

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| オンプレミスバックアップ | Azure Backup（MARS Agent） | オンプレミスサーバーに MARS Agent 導入 | オンプレミスのファイル・システム状態のバックアップ |
| DR（オンプレミス→Azure） | Azure Site Recovery | オンプレミスVMのAzureへのレプリケーション | オンプレミス環境の災害時にAzureクラウドへフェイルオーバー |
| Azure Local HA | Azure Local ストレッチクラスター | 2サイト間でのストレージレプリケーション | データセンター間の同期/非同期レプリケーションによる高可用性 |
| 不変バックアップ | Azure Backup Immutable Vault | コンプライアンスモードでボールトロック | ランサムウェア対策としてバックアップデータの改ざん・削除を防止 |

## セキュリティ設計

### ハイブリッド環境の責任共有モデル

ハイブリッド構成では、オンプレミス部分の物理セキュリティ・設備管理はお客様の責任となります。FISC設備基準（設1〜設70）に基づき、以下の管理が必要です。

| セキュリティ領域 | クラウド（Azure） | オンプレミス（Azure Local等） |
|---------------|-----------------|---------------------------|
| 物理的アクセス制御 | Microsoft（DC入退館） | **お客様**（DC入退館管理、設5〜設10） |
| 電源管理 | Microsoft（冗長電源） | **お客様**（UPS、自家発電、設21〜設25） |
| 空調・環境管理 | Microsoft | **お客様**（温湿度管理、設26〜設30） |
| ネットワーク機器管理 | Microsoft | **お客様**（スイッチ、FW、設45〜設50） |
| ハイパーバイザー | Microsoft | **共有**（Azure Local はMicrosoft提供のHyperV基盤） |
| OS パッチ適用 | 共有（PaaS: Microsoft / IaaS: お客様） | **お客様**（Azure Update Manager で支援） |

### Azure Policy によるオンプレミスガバナンス（Arc経由）

Azure Arc に投影されたオンプレミスリソースに対して、Azure Policy を適用しFISC準拠のガバナンスを実現します。

**適用するポリシー例**:

| ポリシー | 対象 | FISC基準 |
|---------|------|---------|
| Azure Monitor Agent のインストール強制 | Arc-enabled Servers | 実45（ログ記録） |
| ディスク暗号化の要求 | Azure Local VM | 実3（蓄積データ保護） |
| 脆弱性評価の有効化 | Arc-enabled Servers | 実14（脆弱性管理） |
| ゲスト構成ポリシー（パスワード複雑性等） | Arc-enabled Servers | 実25（アクセス管理） |
| タグ付け強制（システム分類、FISC重要度） | 全 Arc リソース | 統3（資産管理） |

### ネットワークセキュリティ

- **ExpressRoute Private Peering**: インターネットを経由しない閉域網接続。Microsoft Enterprise Edge (MSEE) ルーターとの BGP セッション
- **MACsec 暗号化**: ExpressRoute Direct 利用時にL2レベルでの暗号化を適用（実13準拠）
- **IPsec over ExpressRoute**: 必要に応じてExpressRoute上にIPsecトンネルを重畳し、エンドツーエンド暗号化を実現
- **Azure Firewall Premium**: TLSインスペクション、IDPS（侵入検知・防止）を有効化
- **NSG / ASG**: サブネット間の通信を最小限に制御

### 暗号化設計

| 暗号化対象 | 方式 | 管理方法 |
|-----------|------|---------|
| Azure Local ボリューム | BitLocker（ドライブ暗号化） | 暗号化キーは Azure Key Vault に保管 |
| Azure Local VM ディスク | Azure Disk Encryption（ADE） | Key Vault CMK |
| オンプレミス SQL Server | TDE + CMK | Azure Key Vault Managed HSM |
| ExpressRoute 回線 | MACsec（L2）/ IPsec（L3） | 実13準拠 |
| Azure PaaS データ | サービス側暗号化 + CMK | Key Vault Managed HSM |

## データレジデンシー設計

### 設計方針

データレジデンシー要件がある場合、以下の方針に基づきデータの保管場所を制御します。

1. **業務データ**: Azure Local 上に保管。物理的にお客様データセンター内に留置
2. **メタデータ**: Azure Arc により Azure に送信されるのはインベントリ情報（サーバー名、OS情報、タグ等）のみ
3. **バックアップデータ**: Azure Local ストレッチクラスターによるオンプレミス内バックアップ、またはAzure Backup を利用する場合は国内リージョン（東日本/西日本）に限定
4. **ログデータ**: Log Analytics Workspace のリージョンを東日本に固定

### Azure Policy によるデータ転送制限

Azure Policy を使用して、データが許可された場所以外に転送・保管されないよう制御します。

```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "location",
          "notIn": [
            "japaneast",
            "japanwest"
          ]
        },
        {
          "field": "location",
          "notEquals": "global"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  },
  "parameters": {},
  "displayName": "FISC: リソース作成を日本リージョンに限定",
  "description": "データレジデンシー要件に基づき、Azure リソースの作成を東日本・西日本リージョンに限定します。"
}
```

> **補足**: 上記ポリシーはAzureクラウド側のリソース作成を制限するものです。Azure Local 上のデータは物理的にお客様データセンター内に存在するため、ポリシーによる制限とは別に、物理的なデータ主権が確保されます。

### Azure Arc とデータ境界

Azure Arc はオンプレミスリソースをAzureに「投影」しますが、業務データ自体をクラウドに送信することはありません。Arc経由でAzureに送信される情報は以下に限定されます:

| 送信データ | 内容 | 機密性 |
|-----------|------|--------|
| インベントリメタデータ | マシン名、OS、IPアドレス、インストール済みソフトウェア | 低 |
| ポリシーコンプライアンス状態 | ポリシー評価結果（準拠/非準拠） | 低 |
| 監視データ（オプション） | パフォーマンスメトリクス、ログ（Azure Monitor Agent 経由） | 中 |
| セキュリティアラート（オプション） | Defender for Cloud のアラート情報 | 中 |

## 可用性・DR設計

### 目標値

| ワークロード層 | RTO | RPO | 構成 |
|-------------|-----|-----|------|
| Tier 1（勘定系相当） | < 5分 | ≈ 0（同期レプリケーション） | Azure Local ストレッチクラスター + Azure Site Recovery |
| Tier 2（情報系相当） | < 30分 | < 5分 | Azure Local 標準クラスター + Azure Site Recovery |
| Tier 3（内部管理系） | < 4時間 | < 1時間 | Azure Backup からの復元 |

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一ノード障害 | Azure Local クラスター自動フェイルオーバー（Storage Spaces Direct） | < 1分 | 0 |
| ストレージ障害 | Storage Spaces Direct による自動修復（3方向ミラーリング） | < 5分 | 0 |
| サイト障害（DC障害） | Azure Local ストレッチクラスターによる別サイトへの自動切替 | < 5分 | ≈ 0（同期レプリケーション時） |
| リージョン災害 | Azure Site Recovery によるAzureクラウドへのフェイルオーバー | < 30分 | レプリケーション間隔に依存 |
| ランサムウェア・データ破壊 | 不変バックアップからの復元 | 業務判断 | バックアップ世代に依存 |

### Azure Local ストレッチクラスター

Azure Local ストレッチクラスターは、2つの物理サイト間でストレージを同期/非同期レプリケーションし、サイト障害時の自動フェイルオーバーを実現します。

```
┌─ サイト A（プライマリDC）──────────┐     ┌─ サイト B（セカンダリDC）──────────┐
│                                   │     │                                   │
│  Azure Local ノード x 2〜8        │     │  Azure Local ノード x 2〜8        │
│  ┌─────┐ ┌─────┐ ┌─────┐        │     │  ┌─────┐ ┌─────┐ ┌─────┐        │
│  │Node1│ │Node2│ │Node3│ ...    │     │  │Node5│ │Node6│ │Node7│ ...    │
│  └──┬──┘ └──┬──┘ └──┬──┘        │     │  └──┬──┘ └──┬──┘ └──┬──┘        │
│     └───────┴───────┘            │     │     └───────┴───────┘            │
│        Storage Spaces Direct     │◄───►│        Storage Spaces Direct     │
│        (ローカルミラーリング)       │同期  │        (ローカルミラーリング)       │
│                                   │レプリ│                                   │
│  Witness: Azure Cloud Witness    │ケー  │                                   │
└───────────────────────────────────┘ション└───────────────────────────────────┘
```

### Azure Site Recovery によるDR

オンプレミスのVMをAzureクラウドにレプリケーションし、災害時にAzure上でVMを起動するDR構成です。

| 項目 | 設計 |
|------|------|
| レプリケーション対象 | Azure Local / Hyper-V 上のVM |
| レプリケーション先 | Azure東日本リージョン（Managed Disks） |
| レプリケーション間隔 | 30秒（ニアリアルタイム） |
| 復旧ポイント保持 | 最大72時間（アプリケーション整合性ポイントは最大24時間分） |
| フェイルオーバーテスト | 四半期毎に実施（本番影響なし） |
| ネットワーク切替 | ExpressRoute 経由のルーティング変更 |

### バックアップ設計

| 項目 | 設計 |
|------|------|
| オンプレミスVM | Azure Backup（MARS Agent）+ Azure Local ネイティブスナップショット |
| オンプレミスSQL | Azure Backup for SQL Server（Arc経由）+ ネイティブバックアップ |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| 長期保存 | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（7年保持） |
| データレジデンシー対応 | バックアップ先を東日本リージョンに限定。またはオンプレミス内完結 |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio（Arc対応）による月次実施 |
| フェイルオーバー訓練 | Azure Site Recovery のテストフェイルオーバーを四半期毎に実施 |
| ストレッチクラスター切替訓練 | サイト間フェイルオーバーの半期毎の実施 |
| 訓練環境 | 本番相当の検証環境で実施（本番リスク回避） |
| 訓練記録 | FISC実71準拠の訓練記録・改善点の文書化 |

## ネットワーク設計

### ネットワークトポロジー

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: Hybrid Azure側 (10.37.0.0/16)
│               ├── snet-frontend    (10.37.1.0/24)  — フロントエンド (App Service / AKS)
│               ├── snet-backend     (10.37.2.0/24)  — バックエンドサービス
│               ├── snet-db-pe       (10.37.3.0/24)  — DB Private Endpoint (Azure SQL等)
│               ├── snet-mgmt        (10.37.4.0/24)  — 管理用 (Bastion, Jumpbox)
│               ├── snet-monitor     (10.37.5.0/24)  — 監視 (Log Analytics PE)
│               └── snet-pe          (10.37.6.0/24)  — その他 Private Endpoint
│
├── Peering ──▶ Spoke VNet: Hybrid DR/Azure側 (10.38.0.0/16)
│               ├── snet-dr-compute  (10.38.1.0/24)  — DR コンピューティング (ASR復旧先)
│               ├── snet-dr-db       (10.38.2.0/24)  — DR データベース
│               └── snet-dr-mgmt    (10.38.3.0/24)  — DR 管理
│
└── ExpressRoute (Private Peering) ──▶ お客様データセンター
    │
    ├── Azure Local クラスター
    │   ├── 管理ネットワーク   (192.168.1.0/24)  — クラスター管理・Azure Arc通信
    │   ├── ストレージネットワーク (192.168.2.0/24)  — Storage Spaces Direct (RDMA)
    │   ├── VMネットワーク     (172.16.0.0/16)   — VM ワークロード
    │   └── ライブマイグレーション (192.168.3.0/24)  — VM ライブマイグレーション
    │
    ├── メインフレーム
    │   └── ホスト接続ネットワーク (172.17.0.0/16) — SNA/TCP-IP
    │
    └── 既存ネットワーク
        └── 社内LAN (10.x.x.x / 172.x.x.x)
```

### NSG ルール

```
NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- サブネット間: 必要最小限のポートのみ許可
- ExpressRoute経由通信: 送信元をオンプレミスCIDRに限定

Azure Local ネットワーク要件:
- 管理ネットワーク: Azure Arc エージェントが Azure への HTTPS (443) アウトバウンド通信を必要とする
- ストレージネットワーク: RDMA 対応の専用ネットワーク（SMB Direct）
- Azure Local → Azure 通信: ExpressRoute 経由に限定（インターネット経由の代替も構成可能だが非推奨）
```

### ExpressRoute 設計

| 項目 | 設計 |
|------|------|
| 回線構成 | 冗長2回線（異なるピアリングロケーション） |
| ピアリング | Private Peering のみ（Microsoft Peering は必要に応じて追加） |
| 帯域幅 | 1Gbps以上（ワークロード要件に応じて選定） |
| 暗号化 | ExpressRoute Direct + MACsec（L2暗号化） |
| BFD | Bidirectional Forwarding Detection 有効化（障害検知高速化） |
| VPN バックアップ | Site-to-Site VPN Gateway をExpressRoute障害時のフォールバックとして構成 |
| Global Reach | 不使用（国内DC間接続は専用線を利用） |

## 監視・オブザーバビリティ

### ハイブリッド統合監視

| コンポーネント | ツール | 対象 |
|-------------|-------|------|
| メトリクス収集 | Azure Monitor（Arc Agent） | オンプレミスサーバー・Azure Local VM |
| ログ収集 | Azure Monitor Agent → Log Analytics | 全コンポーネント（クラウド + オンプレミス） |
| Azure Local 監視 | Azure Monitor Insights for Azure Local | クラスターの健全性・パフォーマンス・容量 |
| アプリケーション監視 | Application Insights | フロントエンド・バックエンドアプリケーション |
| ネットワーク監視 | Network Watcher / ExpressRoute Monitor | ExpressRoute回線・VNet通信 |
| SIEM | Microsoft Sentinel | ハイブリッド環境横断のセキュリティイベント分析 |

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| Azure Local クラスター健全性 | Azure Monitor | ノード障害、ストレージ劣化 |
| ExpressRoute 回線状態 | Azure Monitor | BGPセッション断、帯域使用率 > 80% |
| Arc エージェント接続状態 | Azure Monitor | エージェント未接続 > 5分 |
| オンプレミスサーバー CPU/メモリ | Azure Monitor (Arc) | CPU > 80%、メモリ > 85% |
| ストレージ容量 | Azure Monitor | Azure Local 容量 > 80% |
| セキュリティアラート | Microsoft Defender for Cloud | 高・中・低重要度アラート |
| ポリシーコンプライアンス | Azure Policy | 非準拠リソースの検出 |
| DR レプリケーション状態 | Azure Site Recovery | レプリケーション遅延 > 30分 |

## 運用設計

### パッチ管理

| 対象 | ツール | 運用方法 |
|------|-------|---------|
| Azure Local OS | Azure Update Manager | 月次定期パッチ適用（クラスター対応ローリングアップデート） |
| Azure Local ソリューションアップデート | Azure Local Lifecycle Manager | ファームウェア・ドライバーを含む統合アップデート |
| Arc-enabled Servers（Windows/Linux） | Azure Update Manager | 月次定期パッチ適用、緊急パッチは随時 |
| Arc-enabled SQL Server | Azure Update Manager | 累積更新プログラムの計画適用 |
| Azure Stack Edge | Azure Stack Edge 管理ポータル | Microsoft管理のアップデート適用 |

### Azure Automation Hybrid Runbook Worker

オンプレミス環境の運用自動化のため、Azure Automation の Hybrid Runbook Worker をオンプレミスサーバーに配置します。

| 自動化タスク | 実行環境 | 頻度 |
|------------|---------|------|
| バックアップ検証 | Hybrid Runbook Worker | 日次 |
| ログローテーション | Hybrid Runbook Worker | 日次 |
| 証明書有効期限チェック | Hybrid Runbook Worker | 週次 |
| コンプライアンスレポート生成 | Azure Automation（クラウド） | 月次 |
| DR 整合性チェック | Azure Automation（クラウド） | 週次 |

### Azure Local ライフサイクル管理

| 操作 | 方法 | 頻度 |
|------|------|------|
| クラスターアップデート | Azure Local Lifecycle Manager | 月次〜四半期 |
| ノード追加・スケールアウト | Azureポータル / ARM API | 随時（容量計画に基づく） |
| ノード退役 | Azure Local 管理ツール | 計画的に実施 |
| ハードウェア交換 | OEM ベンダー連携 | 障害発生時 |
| 容量計画レビュー | Azure Monitor Insights | 四半期 |

## コスト最適化

### コスト構成

| コスト要素 | 内容 | 備考 |
|-----------|------|------|
| Azure Local ライセンス | Azure サブスクリプション課金（コア単位） | ハードウェアは別途OEMから購入 |
| Azure Arc | 管理機能は無料 | Defender、Update Manager等の付加サービスは有料 |
| ExpressRoute | 回線費用 + データ転送費用 | 冗長2回線分を計上 |
| Azure クラウドリソース | 通常のAzure課金 | VM、PaaS、ストレージ等 |
| オンプレミスハードウェア | サーバー、ネットワーク機器、ストレージ | 減価償却（5年） |
| データセンター設備 | 電力、空調、ラック、回線引込み | 月額固定費 |

### コスト比較: フルクラウド vs ハイブリッド

| 項目 | フルクラウド | ハイブリッド（Azure Local） |
|------|-----------|------------------------|
| 初期投資 | 低（OPEX中心） | 高（ハードウェア購入） |
| 月額運用費 | 従量課金 | 固定費（HW）+ 従量課金（Azure） |
| 低レイテンシ要件 | 対応困難 | **最適**（オンプレミス配置） |
| データレジデンシー | リージョン制限のみ | **最適**（物理的にDC内） |
| スケーラビリティ | **最適**（即時スケール） | 制限あり（HW追加が必要） |
| 運用負荷 | 低（マネージド） | 中（HW管理が追加） |

### コスト最適化の手法

- **Azure Hybrid Benefit**: Windows Server / SQL Server のオンプレミスライセンスをAzureで再利用
- **Azure Reserved Instances**: Azure Local の長期コミットメントによる割引
- **Azure Arc の無料管理機能の活用**: インベントリ管理、ポリシー適用、タグ管理は無料
- **適切なワークロード配置**: 低レイテンシ/データレジデンシーが不要なワークロードはクラウドに配置し、Azure Local のリソースを最適化

## デプロイ・IaC

### Azure側リソースのIaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| 状態管理 | Terraform State は Azure Blob Storage（暗号化 + RBAC） |

### オンプレミスリソースのIaC

| 項目 | 内容 |
|------|------|
| Azure Local デプロイ | Azure Resource Manager テンプレート / Bicep |
| VM プロビジョニング | Azure Arc VM management API / Bicep |
| Kubernetes | Azure Arc-enabled Kubernetes + GitOps（Flux v2） |
| 構成管理 | Azure Automanage Machine Configuration |
| セルフホストランナー | Azure DevOps / GitHub Actions のセルフホストエージェントをオンプレミスに配置 |

### GitOps によるKubernetes管理

Azure Arc-enabled Kubernetes では、GitOps（Flux v2）による宣言的なアプリケーションデプロイを推奨します。

```
┌─ Git リポジトリ ──────────────┐
│  ├── clusters/                │
│  │   ├── production/          │
│  │   │   ├── kustomization.yaml│
│  │   │   └── apps/            │
│  │   └── staging/             │
│  └── base/                    │
│      ├── deployment.yaml      │
│      └── service.yaml         │
└──────────────┬────────────────┘
               │ Flux v2 (自動同期)
               ▼
┌─ Azure Arc-enabled Kubernetes ─┐
│  AKS on Azure Local             │
│  (オンプレミス)                   │
└─────────────────────────────────┘
```

## 次のステップ

- [リファレンスアーキテクチャ全体像](reference-architecture.md) — ランディングゾーン全体の構成と管理グループ設計
- [メインフレーム連携・移行](mainframe-integration.md) — メインフレームとの連携パターン（データレプリケーション / メッセージング / ファイル転送）
- [勘定系システム](core-banking.md) — ハイブリッド構成上で勘定系を稼働する場合の設計ガイダンス
- [サイバーレジリエンス](cyber-resilience.md) — ハイブリッド環境のDR・ランサムウェア対策
- [ガバナンス基盤](../governance/README.md) — Azure Policy・管理グループの基盤デプロイ
- [FISC基準マッピング](../mapping/azure-policy-fisc-mapping.md) — Azure Policy と FISC基準の対応表

## 関連リソース

- [Azure Local documentation](https://learn.microsoft.com/azure/azure-local/)
- [Azure Arc overview](https://learn.microsoft.com/azure/azure-arc/overview)
- [Azure hybrid and multicloud landing zone accelerator (CAF)](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/hybrid/enterprise-scale-landing-zone)
- [ExpressRoute documentation](https://learn.microsoft.com/azure/expressroute/)
- [Azure Stack Edge documentation](https://learn.microsoft.com/azure/databox-online/)
- [Azure Arc-enabled servers](https://learn.microsoft.com/azure/azure-arc/servers/overview)
- [Azure Arc-enabled SQL Server](https://learn.microsoft.com/azure/azure-arc/data-services/overview)
- [Azure Arc-enabled Kubernetes](https://learn.microsoft.com/azure/azure-arc/kubernetes/overview)
- [AKS enabled by Azure Arc on Azure Local](https://learn.microsoft.com/azure/aks/hybrid/)
- [Azure Site Recovery for Hyper-V](https://learn.microsoft.com/azure/site-recovery/hyper-v-azure-architecture)
- [Azure Backup MARS agent](https://learn.microsoft.com/azure/backup/backup-architecture#architecture-direct-backup-of-on-premises-windows-server-machines-or-azure-vm-files-or-folders)
- [Azure Update Manager](https://learn.microsoft.com/azure/update-manager/overview)
- [Azure Automation Hybrid Runbook Worker](https://learn.microsoft.com/azure/automation/automation-hybrid-runbook-worker)
- [Azure Policy guest configuration](https://learn.microsoft.com/azure/governance/machine-configuration/overview)
- [Microsoft Defender for Cloud — hybrid and multicloud](https://learn.microsoft.com/azure/defender-for-cloud/plan-multicloud-security-get-started)
- [ExpressRoute encryption — MACsec and IPsec](https://learn.microsoft.com/azure/expressroute/expressroute-about-encryption)
- [Architecture strategies for availability zones and regions](https://learn.microsoft.com/azure/well-architected/design-guides/regions-availability-zones)
