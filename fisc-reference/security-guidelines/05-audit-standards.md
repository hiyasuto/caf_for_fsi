---
title: FISC安全対策基準 第13版 — 監査基準 索引
type: fisc-reference
status: draft
tags: [fisc, audit-standards, compliance, governance]
updated: 2026-04-30
---

# FISC安全対策基準 第13版 — 監査基準 (監x) 索引

> **出典・著作権**: 「金融機関等コンピュータシステムの安全対策基準・解説書（第13版）」は公益財団法人 FISC が著作権を保有する有償刊行物です。本ページは章番号・基準番号と本リポジトリ内のAzure対応分析を索引化したもので、FISC原文の転載ではありません。正式な基準内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## このページの位置づけ

- 監査基準は金融機関等のシステム監査の実施に関する基準（**全2項目**）。
- 第13版で **監1-1（サイバーセキュリティを対象とした内部監査）** が新設。
- Azure では組み込み監査機能・コンプライアンスツール・第三者監査報告書を組み合わせて継続的監査体制を構築。
- 本リポジトリの詳細解説: [`docs/09-audit.md`](../../docs/09-audit.md)

## 責任共有モデルにおける監査

| 領域 | 責任 | 説明 |
|---|---|---|
| Azure 基盤の第三者監査（SOC 1/2/3, ISO 27001, PCI DSS 等） | Microsoft | Service Trust Portal で報告書を提供 |
| 顧客テナント／ワークロードのシステム監査 | 顧客 | Defender for Cloud / Azure Policy / Activity Log 等を活用 |
| サイバーセキュリティ内部監査 | 顧客 | Defender for Cloud CSPM / Microsoft Sentinel 等を活用 |

## 基準別 索引

### 監1: システム監査の実施
- **概要**: 金融機関等のシステムに対する監査の実施。
- **Azure対応**: 顧客側対応。Microsoft Defender for Cloud（規制コンプライアンス・セキュアスコア）、Azure Policy（Audit 効果）、Azure Activity Log、Azure Resource Graph / Change Analysis、Azure Well-Architected Review を組み合わせて継続的に実施。Microsoft 側の基盤監査は Service Trust Portal の SOC 1/2/3、ISO 27001、PCI DSS、ISMAP 等で充足。
- **関連**: → [docs/09-audit.md §1](../../docs/09-audit.md), [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md)

### 監1-1 🆕: サイバーセキュリティを対象とした内部監査（第13版新設）
- **概要**: サイバーセキュリティを対象とした内部監査の実施。
- **Azure対応**: 顧客側対応。Microsoft Defender for Cloud CSPM（クラウドセキュリティポスチャ管理）、攻撃パス分析、Microsoft Entra Access Reviews、Microsoft Sentinel（Hunting Queries）、Microsoft Defender 脆弱性管理、Azure Network Watcher を組み合わせて実施。
- **関連**: → [docs/09-audit.md §2](../../docs/09-audit.md)

## 推奨監査サイクル（顧客側）

| 監査領域 | Azure ツール | 推奨頻度 |
|---|---|---|
| アクセス権限レビュー | Microsoft Entra Access Reviews | 四半期ごと |
| セキュリティ態勢評価 | Defender for Cloud セキュアスコア | 月次 |
| コンプライアンス評価 | Defender for Cloud 規制コンプライアンス | 月次 |
| ログ分析・異常検知 | Microsoft Sentinel | 継続的 |
| 設定変更監査 | Azure Activity Log / Change Analysis | 継続的 |
| 脆弱性評価 | Microsoft Defender 脆弱性管理 | 月次 |
| DR訓練結果 | Azure Site Recovery テストフェイルオーバー | 年次以上 |

## 関連リンク

- [安対基準 README](./README.md)
- [docs/09-audit.md](../../docs/09-audit.md) — 監査領域の詳細解説
- [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md)
- [Microsoft Defender for Cloud — 規制コンプライアンス](https://learn.microsoft.com/azure/defender-for-cloud/regulatory-compliance-dashboard)
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [Azure Policy — コンプライアンスデータの取得](https://learn.microsoft.com/azure/governance/policy/how-to/get-compliance-data)
- [Microsoft Entra Access Reviews](https://learn.microsoft.com/entra/id-governance/access-reviews-overview)
- [Azure コンプライアンス（FISC Japan）](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
