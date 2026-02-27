# 09 — 監査

> FISC監査基準（監1, 監1-1）→ Azure Audit & Compliance

## 概要

FISC監査基準は、金融機関等のシステムに対する監査の実施を求めています。Azure上では、組み込みの監査機能、コンプライアンスツール、および第三者監査報告書を活用して、継続的な監査体制を構築します。

## 1. 監1: システム監査の実施

**FISC要件**: システム監査を実施すること。

### Azure対応

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| コンプライアンス評価 | Microsoft Defender for Cloud（規制コンプライアンス） | 各種規制基準への準拠状況を継続的に評価 |
| セキュアスコア | Microsoft Defender for Cloud | セキュリティ態勢の定量的スコアリング |
| 構成監査 | Azure Policy（Audit効果） | リソース構成の基準準拠を監査 |
| 活動ログ | Azure Activity Log | すべての管理操作の監査証跡 |
| リソース変更追跡 | Azure Resource Graph / Change Analysis | リソース構成の変更履歴の追跡 |
| Well-Architected Assessment | Azure Well-Architected Review | ワークロードのアーキテクチャレビュー |

### 継続的コンプライアンス監査

```
┌──────────────────────────────────────────────────┐
│         継続的コンプライアンス監査                    │
│                                                  │
│  ┌──────────┐   ┌──────────────┐   ┌──────────┐ │
│  │ Azure     │   │ Microsoft    │   │ Azure    │ │
│  │ Policy    │──▶│ Defender for │──▶│ Monitor  │ │
│  │ (定義)    │   │ Cloud (評価)  │   │ (レポート)│ │
│  └──────────┘   └──────────────┘   └──────────┘ │
│       │               │                │        │
│       ▼               ▼                ▼        │
│  ガードレール     セキュアスコア      ダッシュボード │
│  (Deny/Audit)    コンプライアンス%   アラート通知   │
│                  推奨事項                         │
└──────────────────────────────────────────────────┘
```

## 2. 監1-1: サイバーセキュリティ内部監査（第13版新設）

**FISC要件**: サイバーセキュリティを対象とした内部監査を行うこと。

### Azure対応

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| セキュリティ態勢 | Microsoft Defender for Cloud CSPM | クラウドセキュリティポスチャ管理 |
| 攻撃経路分析 | Microsoft Defender for Cloud（攻撃パス分析） | 潜在的な攻撃経路の可視化 |
| ID監査 | Microsoft Entra Access Reviews | アクセス権限の定期的な棚卸し |
| ログ監査 | Microsoft Sentinel（Hunting Queries） | セキュリティイベントのプロアクティブ調査 |
| 脆弱性評価 | Microsoft Defender 脆弱性管理 | 資産全体の脆弱性レポート |
| ネットワーク監査 | Azure Network Watcher | ネットワーク構成・接続性の検証 |

## 3. 監査報告・レポート

### Microsoft が提供する第三者監査報告書

| 報告書 | 入手先 | 内容 |
|-------|-------|------|
| SOC 1/2/3 報告書 | Microsoft Service Trust Portal | 独立監査法人によるAzure統制の監査報告 |
| ISO 27001 証明書 | Microsoft Service Trust Portal | 情報セキュリティ管理の認証 |
| PCI DSS 認定書 | Microsoft Service Trust Portal | 決済カードデータセキュリティ認定 |
| ペネトレーションテスト結果 | Microsoft Service Trust Portal | Azureインフラの第三者ペネトレーションテスト結果 |
| ISMAP 登録 | ISMAP ポータル | 政府情報システムのセキュリティ評価 |

### 顧客自身の監査

| 監査領域 | Azure ツール | 推奨頻度 |
|---------|------------|---------|
| アクセス権限レビュー | Microsoft Entra Access Reviews | 四半期ごと |
| セキュリティ態勢評価 | Defender for Cloud セキュアスコア | 月次 |
| コンプライアンス評価 | Defender for Cloud 規制コンプライアンス | 月次 |
| ログ分析・異常検知 | Microsoft Sentinel | 継続的 |
| 設定変更監査 | Azure Activity Log / Change Analysis | 継続的 |
| 脆弱性評価 | Microsoft Defender 脆弱性管理 | 月次 |
| DR訓練結果 | Azure Site Recovery テストフェイルオーバー | 年次以上 |

## 参考リンク

- [Microsoft Defender for Cloud — 規制コンプライアンス](https://learn.microsoft.com/azure/defender-for-cloud/regulatory-compliance-dashboard)
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [Azure Policy — コンプライアンス](https://learn.microsoft.com/azure/governance/policy/how-to/get-compliance-data)
- [Microsoft Entra Access Reviews](https://learn.microsoft.com/entra/id-governance/access-reviews-overview)
