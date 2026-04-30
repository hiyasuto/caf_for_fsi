---
title: FISC安全対策基準 第13版 — 索引
type: fisc-reference
status: draft
updated: 2026-04-30
---

# FISC 安全対策基準 第13版（2025年3月） — 索引

> **出典・著作権**: 「金融機関等コンピュータシステムの安全対策基準・解説書（第13版）」は公益財団法人 FISC が著作権を保有する有償刊行物です。本ディレクトリは章番号・基準番号と本リポジトリ内のAzure対応分析を索引化したもので、FISC原文の転載ではありません。正式な基準内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## ねらい

本ディレクトリは、FISC 安全対策基準 第13版を **基準番号順** にナビゲートし、本リポジトリ内のAzure対応分析（[`docs/`](../../docs/)）と相互参照するための索引です。全 **324 項目**（統制基準36 + 実務基準152 + 設備基準134 + 監査基準2）を 5 つの索引ページに分割しています。

## 全体構造

| # | カテゴリ | 項目数 | 索引 | Azure 側ドキュメント |
|---|---|---|---|---|
| 1 | 統制基準 (統x) | 36 | [01-control-standards.md](./01-control-standards.md) | [docs/02 ITガバナンス](../../docs/02-governance.md), [docs/07 クラウドガバナンス](../../docs/07-cloud-governance.md) |
| 2 | 実務基準 (実x) Part A | 実1〜実74 | [02-practice-standards-security-ops.md](./02-practice-standards-security-ops.md) | [docs/03 セキュリティ](../../docs/03-security.md), [docs/04 信頼性](../../docs/04-reliability.md), [docs/05 運用](../../docs/05-operations.md) |
| 3 | 実務基準 (実x) Part B | 実75〜実153 | [03-practice-standards-development-ai.md](./03-practice-standards-development-ai.md) | [docs/06 セキュア開発](../../docs/06-development.md), [docs/08 AI安全対策](../../docs/08-ai-safety.md) |
| 4 | 設備基準 (設x) | 134 | [04-facility-standards.md](./04-facility-standards.md) | (Microsoft 側責任が中心) |
| 5 | 監査基準 (監x) | 2 | [05-audit-standards.md](./05-audit-standards.md) | [docs/09 監査](../../docs/09-audit.md) |

## 第13版 主な改訂ポイント（2025年3月）

| # | 改訂項目 | 概要 |
|---|---|---|
| 1 | **経済安全保障推進法への対応** | 特定社会基盤事業者としての義務 |
| 2 | **オペレーショナル・レジリエンス** | 金融庁ガイドラインへの対応 |
| 3 | **サイバーセキュリティガイドライン** | 金融庁2024年10月公表ガイドライン |
| 4 | **AI安全対策** | 生成AI利用のリスク管理基準を新設（実150〜実153） |
| 5 | **サプライチェーンセキュリティ** | 統28を新設 |

## 横断ビュー

- [基準→Azureサービス マッピング全表](../../mapping/fisc-to-azure-services.md)
- [Azure Policy × FISC マッピング](../../mapping/azure-policy-fisc-mapping.md)
- [システム別 FISC実務基準マッピング](../../mapping/fisc-workload-mapping.md)

## 関連リンク

- [リポジトリ README](../../README.md)
- [Azure コンプライアンス（FISC Japan）](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [FISC 公式サイト](https://www.fisc.or.jp/)
