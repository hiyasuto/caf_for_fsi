# 04 — 信頼性・事業継続

> FISC実務基準（実39〜実45, 実71〜実73-1）＋ コンティンジェンシープラン手引書 → Azure Reliability

## 概要

FISC基準における障害対策・災害対策・バックアップ・コンティンジェンシープラン要件を、Azure WAFの**信頼性の柱**（Reliability Pillar）に基づいて実現します。FISCコンティンジェンシープラン策定手引書（第5版）のプロセスもAzureの機能にマッピングします。

## 1. バックアップ（実39〜実45）

### 実39: データファイルのバックアップ

**FISC要件**: データファイルのバックアップを確保すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 統合バックアップ | Azure Backup | VM、SQL、ファイル、BLOBの統合バックアップ |
| Geo冗長 | GRS/RA-GRS | ペアリージョンへのデータレプリケーション |
| 不変バックアップ | 不変ボールト | ランサムウェア対策：バックアップの改ざん防止 |
| 長期保存 | Azure Backup 長期保持 | 最長10年間のバックアップ保持 |
| データベースバックアップ | Azure SQL 自動バックアップ | PITR（ポイントインタイムリストア）最大35日 |

### 実41: プログラムファイルのバックアップ

**FISC要件**: プログラムファイルのバックアップを確保すること。

**Azure対応**:
- **Azure DevOps / GitHub** — ソースコードのバージョン管理・Geoレプリケーション
- **Azure Container Registry（Geo-replication）** — コンテナイメージの複数リージョン保持
- **Infrastructure as Code（IaC）** — Bicep/Terraformによるインフラ定義のコード管理

### 実45: ドキュメントのバックアップ

**FISC要件**: 災害時の復旧対応に必要なドキュメントのバックアップを確保すること。

**Azure対応**:
- **SharePoint Online / OneDrive** — ドキュメントのクラウドバックアップ・バージョン管理
- **Azure Blob Storage（GRS）** — Geo冗長ストレージによる災害対策
- **IaC リポジトリ** — 復旧手順書のコード化・バージョン管理

## 2. 障害・災害対策（実71〜実73-1）

### 実71: 障害時・災害時復旧手順

**FISC要件**: 障害時・災害時復旧手順を明確にすること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| DR自動化 | Azure Site Recovery (ASR) | VM・物理サーバーのDRレプリケーション |
| 可用性ゾーン | Azure Availability Zones | 同一リージョン内の3つの独立ゾーン（99.99% SLA） |
| 可用性セット | Azure Availability Sets | 障害ドメイン・更新ドメインによる冗長化 |
| リージョンペア | Azure リージョンペア | 東日本⇔西日本のペアリージョン |
| 自動フェイルオーバー | Azure SQL Auto-failover Groups | データベースの自動フェイルオーバー |
| グローバル負荷分散 | Azure Front Door / Traffic Manager | リージョン間のトラフィック切替 |

### 実73: コンティンジェンシープランの策定

**FISC要件**: コンティンジェンシープランを策定すること。

#### FISCコンティンジェンシープラン策定プロセスとAzure

FISCコンティンジェンシープラン策定手引書（第5版）のプロセスに沿ったAzure活用：

```
工程                               Azure活用
─────────────────────────────────────────────
工程1: 必要性認識・推進組織編成   → Azure Advisor / Defender for Cloud
                                   リスク評価レポートの活用
工程2: 予備調査・基本方針決定     → Azure リージョン・可用性ゾーン設計
                                   RTO/RPO目標の設定
工程3: 具体的プラン立案           → Azure Site Recovery 設計
                                   Azure Chaos Studio によるカオスエンジニアリング
工程4: プラン決定                 → Azure DevOps でのプラン文書管理
工程5: 維持管理                   → 定期的なDR訓練の実施
                                   Azure Chaos Studio による定期テスト
```

#### RTO/RPO設計ガイダンス

| 重要度 | FISC分類 | RTO目標 | RPO目標 | Azure構成例 |
|-------|---------|---------|---------|------------|
| 最高 | 重大な外部性を有するシステム | < 1時間 | ほぼゼロ | 可用性ゾーン + リージョンペア + 同期レプリケーション |
| 高 | 基幹業務系 | < 4時間 | < 1時間 | 可用性ゾーン + ASR（リージョン間） |
| 中 | 基幹業務系以外（重要） | < 24時間 | < 4時間 | 可用性セット + Azure Backup（GRS） |
| 標準 | 一般業務系 | < 72時間 | < 24時間 | Azure Backup（LRS/GRS） |

#### 想定リスクへの対応

##### 自然災害対応
| リスク | Azure対応 |
|-------|----------|
| 地震（南海トラフ等） | 東日本・西日本リージョンの活用、リージョンペアによるDR |
| 台風・水害 | 可用性ゾーン（同一リージョン内3ゾーン）による冗長化 |
| 広域災害 | マルチリージョン構成、Azure Front Door による自動切替 |

##### 大規模システム障害対応
| リスク | Azure対応 |
|-------|----------|
| ハードウェア障害 | 可用性セット・可用性ゾーンによる自動フェイルオーバー |
| ソフトウェア障害 | Blue-Green デプロイ、ロールバック機能 |
| データ破損 | PITR（ポイントインタイムリストア）、不変バックアップ |

##### サイバー攻撃対応
| リスク | Azure対応 |
|-------|----------|
| ランサムウェア | 不変バックアップ、Azure Backup の論理削除 |
| DDoS攻撃 | Azure DDoS Protection、Azure Front Door |
| データ漏えい | Microsoft Purview DLP、暗号化 |

### 実73-1: サイバー攻撃想定のインシデント対応計画（第13版新設）

**FISC要件**: サイバー攻撃を想定したインシデント対応計画及びコンティンジェンシープランを策定すること。

**Azure対応**:
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| インシデント対応 | Microsoft Sentinel | SOAR（Security Orchestration, Automation and Response） |
| 自動対応 | Microsoft Sentinel Playbook | Logic Appsベースの自動インシデント対応 |
| フォレンジック | Azure Disk Snapshot | インシデント発生時のディスクスナップショット保全 |
| カオステスト | Azure Chaos Studio | 障害注入テストによる回復力検証 |
| DR訓練 | Azure Site Recovery テストフェイルオーバー | 本番影響なしのDR訓練 |

## 3. オペレーショナル・レジリエンス

FISC第13版では、金融庁「オペレーショナル・レジリエンス確保に向けた基本的な考え方」を反映しています。

### Azureでのオペレーショナル・レジリエンス実現

```
┌──────────────────────────────────────────────────────┐
│          オペレーショナル・レジリエンス                    │
│                                                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐      │
│  │ 予防        │  │ 検知        │  │ 復旧        │      │
│  │             │  │             │  │             │      │
│  │ Azure Policy│  │ Sentinel    │  │ Site Recovery│     │
│  │ Defender    │  │ Monitor     │  │ Backup       │     │
│  │ WAF/FW      │  │ Defender XDR│  │ Chaos Studio │     │
│  └────────────┘  └────────────┘  └────────────┘      │
│                                                      │
│  ┌─────────────────────────────────────────────┐      │
│  │ 継続的改善: Azure Advisor / Well-Architected │      │
│  │ Assessment / Defender for Cloud セキュアスコア │     │
│  └─────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────┘
```

## 参考リンク

- [Azure Well-Architected Framework — Reliability](https://learn.microsoft.com/azure/well-architected/reliability/)
- [Azure Site Recovery](https://learn.microsoft.com/azure/site-recovery/)
- [Azure Backup](https://learn.microsoft.com/azure/backup/)
- [Azure Chaos Studio](https://learn.microsoft.com/azure/chaos-studio/)
- [Azure リージョンと可用性ゾーン](https://learn.microsoft.com/azure/reliability/availability-zones-overview)
- [金融サービスのためのAzure](https://learn.microsoft.com/industry/financial-services/)


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [05. 運用管理](05-operations.md) | システム運用・監視・変更管理の設計 |
| → | [サイバーレジリエンス ランディングゾーン](../landing-zone/cyber-resilience.md) | サイバー攻撃からの防御・検知・復旧の詳細設計 |
| → | [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md) | 各ランディングゾーンへの FISC 基準適用要件 |