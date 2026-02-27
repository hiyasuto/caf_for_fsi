# 05 — 運用管理

> FISC実務基準（実34〜実62）→ Azure Operational Excellence

## 概要

FISC実務基準における運用管理要件を、Azure WAFの**オペレーショナルエクセレンスの柱**に基づいて実現します。システム運用、アクセス管理、設備管理、外部接続管理をカバーします。

## 1. 外部接続管理（実34）

### 実34: 外部接続の運用管理

**FISC要件**: 外部接続における運用管理方法を明確にすること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 接続制御 | Azure ExpressRoute | 専用線接続による安全な外部接続 |
| VPN管理 | Azure VPN Gateway | サイト間VPN・ポイント対サイトVPNの管理 |
| APIゲートウェイ | Azure API Management | 外部API接続の一元管理・認証・レート制限 |
| ネットワーク監視 | Azure Network Watcher | 接続状態・トラフィックの監視 |

## 2. オペレーション管理（実36）

### 実36: オペレーションの依頼・承認手続き

**FISC要件**: オペレーションの依頼・承認手続きを明確にすること。

**Azure対応**:
- **Microsoft Entra PIM** — 特権操作のJust-In-Time承認ワークフロー
- **Azure DevOps（承認ゲート）** — デプロイ前の承認プロセス
- **Azure Activity Log** — すべての管理操作の監査証跡
- **Azure Policy（Deny効果）** — 未承認リソース作成の防止

## 3. バックアップ管理（実39〜実45）

→ [04-reliability.md](04-reliability.md) を参照

## 4. ハードウェア・ソフトウェア管理（実48〜実53）

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

## 5. 入退管理・物理セキュリティ（実56〜実57）

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

## 6. 監視・アラート

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
