---
title: CP手引書5版 — サンプル編 索引
type: fisc-reference
status: draft
updated: 2026-04-30
---

# サンプル編 — 索引

> **出典・著作権**: 「金融機関等におけるコンティンジェンシープラン策定のための手引書（第5版）」は公益財団法人 FISC が著作権を保有します。本ページは手引書サンプル類に対応する Azure 上のテンプレート / IaC / Runbook 例の索引であり、FISC原文の転載ではありません。正式なサンプル様式は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## ねらい
手引書のサンプル類（CP文書ひな形・チェックリスト・連絡網・Runbook 等）に対応して、本リポジトリで提供している Azure 実装テンプレート・IaC・運用ドキュメントを索引化します。

## 対応マップ

### CP文書ひな形
- 章立てテンプレート: [docs/12-contingency-plan.md §4.1 文書構成テンプレート](../../docs/12-contingency-plan.md#41-文書構成テンプレート)
- 各項目の Azure 裏付け: [docs/12-contingency-plan.md §4.2](../../docs/12-contingency-plan.md#42-各項目の-azure-による裏付け)

### RTO/RPO 一覧（システム別）
- 金融システム別 RTO/RPO マッピング: [docs/12-contingency-plan.md §2.2](../../docs/12-contingency-plan.md#22-金融システム別-rtorpo-マッピング)
- ランディングゾーン別の DR 構成:
  - [landing-zone/core-banking.md](../../landing-zone/core-banking.md)
  - [landing-zone/payment-settlement.md](../../landing-zone/payment-settlement.md)
  - [landing-zone/internet-banking.md](../../landing-zone/internet-banking.md)
  - [landing-zone/external-connectivity.md](../../landing-zone/external-connectivity.md)
  - [landing-zone/](../../landing-zone/)（一覧）

### 障害シナリオ一覧
- 自然災害・大規模障害・サイバー攻撃シナリオ: [docs/10-disaster-exercise.md §1 障害シナリオの策定](../../docs/10-disaster-exercise.md#1-障害シナリオの策定)
- リスク別対応方針: [docs/12-contingency-plan.md §3](../../docs/12-contingency-plan.md#3-リスク別対応方針)

### 復旧手順 Runbook
- Azure Automation Runbook（DR 切替・縮退運転・リストア）: [docs/12-contingency-plan.md §1.2 工程3 / §5](../../docs/12-contingency-plan.md#工程3-具体的プランの立案)
- IaC ロールバック: [governance/](../../governance/), [governance/main.bicep](../../governance/main.bicep)
- サイバー攻撃別プレイブック: [docs/11-incident-response.md §4.2](../../docs/11-incident-response.md#42-攻撃タイプ別-対応プレイブック)
- Break Glass 手順: [docs/11-incident-response.md §6](../../docs/11-incident-response.md#6-break-glass-手順)

### 演習計画・実施記録
- 年間演習計画ひな形: [docs/10-disaster-exercise.md §4 年間演習計画](../../docs/10-disaster-exercise.md#4-年間演習計画推奨)
- 机上演習シナリオ例（リージョン障害）: [docs/10-disaster-exercise.md §3.1](../../docs/10-disaster-exercise.md#31-l1-机上演習tabletop-exercise)
- 非本番実機演習手順テンプレート: [docs/10-disaster-exercise.md §3.2](../../docs/10-disaster-exercise.md#32-l2-非本番実機演習non-production-drill)
- カオス実験設計（Azure Chaos Studio）: [docs/10-disaster-exercise.md §3.3](../../docs/10-disaster-exercise.md#33-l3-本番カオスエンジニアリングproduction-chaos)

### 連絡網・対応体制
- 対応組織・エスカレーションフロー: [docs/11-incident-response.md §1](../../docs/11-incident-response.md#1-インシデント対応体制)
- 通信計画（Teams / Azure Communication Services）: [docs/12-contingency-plan.md §1.2 工程3](../../docs/12-contingency-plan.md#工程3-具体的プランの立案)
- CSP 連携窓口: [docs/11-incident-response.md §8](../../docs/11-incident-response.md#8-cspmicrosoftとの連携)

### 規制当局報告様式
- 報告基準と Azure データソース: [docs/12-contingency-plan.md §7](../../docs/12-contingency-plan.md#7-規制当局への報告)
- 障害記録要件・報告フロー: [docs/11-incident-response.md §5](../../docs/11-incident-response.md#5-障害の記録報告実59)

### サイバーレジリエンス・ランディングゾーン
- 不変バックアップ・隔離環境・Sentinel/Defender 中央化: [landing-zone/cyber-resilience.md](../../landing-zone/cyber-resilience.md)

## 未網羅領域（本リポジトリでの扱い）
以下の領域は手引書サンプル編に含まれる可能性があるが、本リポジトリでは Azure 観点に絞った索引として直接のひな形は提供していません。導入時は FISC 原本サンプルと組織内既存テンプレートを併用してください。

- 顧客通知文面・報道対応文面の具体テンプレート（※本リポジトリでは未網羅）
- 紙運用を前提とした連絡網様式（※本リポジトリでは未網羅）
- 業界共同訓練の様式（※本リポジトリでは未網羅。共同演習の枠組みは [docs/10-disaster-exercise.md §3.1 複数金融機関による共同演習](../../docs/10-disaster-exercise.md#31-l1-机上演習tabletop-exercise) を参照）

## 関連
- [README.md](./README.md)（CP手引書5版 索引トップ）
- [01-planning.md](./01-planning.md)（策定編）
- [02-response.md](./02-response.md)（災害発生時対応編）
