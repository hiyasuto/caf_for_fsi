---
title: CP手引書5版 — 策定編 索引
type: fisc-reference
status: draft
updated: 2026-04-30
---

# 策定編 — 索引

> **出典・著作権**: 「金融機関等におけるコンティンジェンシープラン策定のための手引書（第5版）」は公益財団法人 FISC が著作権を保有します。本ページはCP策定プロセスの構造と Azure 対応観点の索引であり、FISC原文の転載ではありません。正式な内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## 概要
策定編はCPを新規に策定（または全面改定）する際の標準的な5工程プロセスを定義します。本ページは各工程のねらいを要約し、本リポジトリの Azure 対応分析へリンクします。

- Azure 対応の詳細: [docs/12-contingency-plan.md セクション1](../../docs/12-contingency-plan.md#1-fisc-コンティンジェンシープラン策定プロセス)
- 信頼性アーキテクチャ: [docs/04-reliability.md](../../docs/04-reliability.md)

## 工程1: 必要性の認識・推進組織の編成
- **趣旨（要約）**: クラウド利用に伴うリスクを経営層が認識し、CP策定を推進する組織体制（責任者・メンバー・スコープ）を整える段階。
- **Azure 対応観点**:
  - スコープ定義のためのリソースインベントリ取得（Azure Resource Graph）
  - リスクの可視化（Azure Advisor / Microsoft Defender for Cloud セキュアスコア）
- **相互リンク**: [docs/12-contingency-plan.md §1.2 工程1](../../docs/12-contingency-plan.md#工程1-必要性の認識推進組織の編成)

## 工程2: 予備調査・基本方針の決定
- **趣旨（要約）**: 現状調査・リスク評価・業務影響分析（BIA）を行い、復旧目標（RTO/RPO）と DR 戦略の基本方針を決定する段階。
- **Azure 対応観点**:
  - 構成・依存関係の調査: Azure Resource Graph / Application Insights アプリマップ
  - BIA のクリティカリティ管理: タグ運用 + Resource Graph
  - RTO/RPO 目標と Azure 構成パターン: [docs/12-contingency-plan.md §2](../../docs/12-contingency-plan.md#2-rtorpo-設計ガイダンス)
  - 障害シナリオ分析: [docs/10-disaster-exercise.md §1](../../docs/10-disaster-exercise.md#1-障害シナリオの策定)
- **相互リンク**: [docs/12-contingency-plan.md §1.2 工程2](../../docs/12-contingency-plan.md#工程2-予備調査基本方針の決定), [docs/04-reliability.md](../../docs/04-reliability.md)

## 工程3: 具体的プランの立案
- **趣旨（要約）**: DR アーキテクチャ・対応手順・対応体制・通信計画・対外対応計画など、CPに含める具体内容を立案する段階。
- **Azure 対応観点**:
  - DR アーキテクチャ: マルチリージョン / 可用性ゾーン / Azure Site Recovery / Azure SQL Failover Group
  - 対応手順の自動化: Azure Automation Runbook / Bicep・Terraform の IaC ロールバック
  - 対応体制・エスカレーション: [docs/11-incident-response.md §1](../../docs/11-incident-response.md#1-インシデント対応体制)
  - 通信計画: Microsoft Teams / Azure Communication Services（主系・代替系）
  - 対外対応・規制報告: [docs/11-incident-response.md §5](../../docs/11-incident-response.md#5-障害の記録報告実59), [docs/12-contingency-plan.md §7](../../docs/12-contingency-plan.md#7-規制当局への報告)
- **相互リンク**: [docs/12-contingency-plan.md §1.2 工程3](../../docs/12-contingency-plan.md#工程3-具体的プランの立案), [docs/12-contingency-plan.md §4 文書構成テンプレート](../../docs/12-contingency-plan.md#4-コンティンジェンシープラン文書の構成), [docs/12-contingency-plan.md §5 縮退運転](../../docs/12-contingency-plan.md#5-縮退運転の設計)

## 工程4: プランの決定
- **趣旨（要約）**: CP 文書を作成・レビューし、経営層の承認を得て関係者へ周知・教育・文書管理を行う段階。
- **Azure 対応観点**:
  - 文書管理: Azure DevOps Wiki / SharePoint（バージョン管理・Information Protection）
  - 教育: Microsoft Learn / Teams 録画
- **相互リンク**: [docs/12-contingency-plan.md §1.2 工程4](../../docs/12-contingency-plan.md#工程4-プランの決定), [docs/12-contingency-plan.md §4.1 文書構成テンプレート](../../docs/12-contingency-plan.md#41-文書構成テンプレート)

## 工程5: 維持管理
- **趣旨（要約）**: 定期演習・結果評価・更新・変更管理を通じてCPを継続的に有効に保つ段階。
- **Azure 対応観点**:
  - 演習: L1 机上 / L2 非本番実機 / L3 本番カオス（Azure Chaos Studio）
  - 結果評価: Azure Monitor / Chaos Studio レポート
  - 更新トリガー: 演習結果・実障害・環境変更・規制改定 等（[docs/12-contingency-plan.md §6.2](../../docs/12-contingency-plan.md#62-更新トリガー)）
  - 変更検知: Azure Activity Log / Resource Graph 変更クエリ
- **相互リンク**: [docs/12-contingency-plan.md §1.2 工程5](../../docs/12-contingency-plan.md#工程5-維持管理), [docs/12-contingency-plan.md §6 PDCA](../../docs/12-contingency-plan.md#6-コンティンジェンシープランの更新プロセス), [docs/10-disaster-exercise.md](../../docs/10-disaster-exercise.md)

## 関連
- [README.md](./README.md)（CP手引書5版 索引トップ）
- [02-response.md](./02-response.md)（災害発生時対応編）
- [03-samples.md](./03-samples.md)（サンプル編）
