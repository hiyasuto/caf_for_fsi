---
title: CP手引書5版 — 災害発生時対応編 索引
type: fisc-reference
status: draft
updated: 2026-04-30
---

# 災害発生時対応編 — 索引

> **出典・著作権**: 「金融機関等におけるコンティンジェンシープラン策定のための手引書（第5版）」は公益財団法人 FISC が著作権を保有します。本ページは災害発生時対応の構造と Azure 対応観点の索引であり、FISC原文の転載ではありません。正式な内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## 概要
災害発生時対応編は、発災検知から平常化までのフェーズ別に組織・手順・通信・対外対応を整理します。本ページは各フェーズのねらいを要約し、本リポジトリの Azure 対応分析へリンクします。

- インシデント対応詳細: [docs/11-incident-response.md](../../docs/11-incident-response.md)
- 障害シナリオ・演習: [docs/10-disaster-exercise.md](../../docs/10-disaster-exercise.md)

## フェーズ別索引

### Phase 1: 発災検知（Detect）
- **趣旨（要約）**: 障害・サイバー攻撃・自然災害等の事象を早期に検知し、対応プロセスを起動するフェーズ。
- **Azure 対応観点**:
  - 監視・検知: Azure Monitor / Application Insights / Microsoft Sentinel / Microsoft Defender for Cloud
  - 自動エスカレーション: Action Group / Logic Apps
- **相互リンク**: [docs/11-incident-response.md §3.2 Phase 1: 検知](../../docs/11-incident-response.md#phase-1-検知detect), [docs/11-incident-response.md §1.3 エスカレーション自動化](../../docs/11-incident-response.md#13-azure-によるエスカレーション自動化)

### Phase 2: 初動（Triage / Contain）
- **趣旨（要約）**: 重大度判定・対応体制起動・影響範囲の封じ込めを行い、被害拡大を防ぐフェーズ。
- **Azure 対応観点**:
  - 重大度判定: [docs/11-incident-response.md §2.1](../../docs/11-incident-response.md#21-重大度レベルの定義)
  - 封じ込め: NSG/Firewall ルール変更、Conditional Access、隔離サブスクリプション、Defender for Endpoint 隔離
  - サイバー攻撃別プレイブック: ランサムウェア / 不正アクセス / DDoS（[docs/11-incident-response.md §4.2](../../docs/11-incident-response.md#42-攻撃タイプ別-対応プレイブック)）
- **相互リンク**: [docs/11-incident-response.md §3.2 Phase 2 トリアージ](../../docs/11-incident-response.md#phase-2-トリアージtriage), [Phase 3 封じ込め](../../docs/11-incident-response.md#phase-3-封じ込めcontain)

### Phase 3: 復旧（Recover）
- **趣旨（要約）**: 縮退運転・優先順位に従った復旧・全面復旧・データ整合性確認を行うフェーズ。
- **Azure 対応観点**:
  - DR 切替: Azure Site Recovery / Azure SQL Failover Group / Front Door ルーティング切替
  - 縮退運転モード: [docs/12-contingency-plan.md §5](../../docs/12-contingency-plan.md#5-縮退運転の設計)
  - 不変バックアップからのリストア（ランサムウェア時）: Immutable Vault
  - フォレンジック・証拠保全: [docs/11-incident-response.md §7](../../docs/11-incident-response.md#7-フォレンジック証拠保全)
  - Break Glass 手順: [docs/11-incident-response.md §6](../../docs/11-incident-response.md#6-break-glass-手順)
- **相互リンク**: [docs/11-incident-response.md §3.2 Phase 4 復旧](../../docs/11-incident-response.md#phase-4-復旧recover)

### Phase 4: 平常化（Retrospective / Report）
- **趣旨（要約）**: 事後レビュー・記録・規制当局への報告・CP更新トリガー判定を行うフェーズ。
- **Azure 対応観点**:
  - 事後レビュー（RCA）: Azure DevOps Work Items / Wiki
  - 記録・報告自動化: Sentinel インシデント / Log Analytics クエリ / 自動レポート（[docs/11-incident-response.md §5.3](../../docs/11-incident-response.md#53-azure-によるレポート自動生成)）
  - 規制当局報告: [docs/12-contingency-plan.md §7](../../docs/12-contingency-plan.md#7-規制当局への報告), [docs/11-incident-response.md §5 障害の記録・報告](../../docs/11-incident-response.md#5-障害の記録報告実59)
  - CP 更新: [docs/12-contingency-plan.md §6.2 更新トリガー](../../docs/12-contingency-plan.md#62-更新トリガー)
- **相互リンク**: [docs/11-incident-response.md §3.2 Phase 5 事後レビュー](../../docs/11-incident-response.md#phase-5-事後レビューretrospective)

## 体制・通信・CSP連携
- **対応体制・エスカレーション**: [docs/11-incident-response.md §1](../../docs/11-incident-response.md#1-インシデント対応体制)
- **通信計画（主系・代替系）**: Microsoft Teams / Azure Communication Services（[docs/12-contingency-plan.md §1.2 工程3](../../docs/12-contingency-plan.md#工程3-具体的プランの立案)）
- **CSP（Microsoft）連携**: Service Health / サポートリクエスト / Microsoft DART（[docs/11-incident-response.md §8](../../docs/11-incident-response.md#8-cspmicrosoftとの連携), [§4.3 DART 連携](../../docs/11-incident-response.md#43-microsoft-dart-との連携)）
- **障害時の情報取扱い・共有**: [docs/10-disaster-exercise.md §5](../../docs/10-disaster-exercise.md#5-障害時の情報の取扱い)

## 関連
- [README.md](./README.md)（CP手引書5版 索引トップ）
- [01-planning.md](./01-planning.md)（策定編）
- [03-samples.md](./03-samples.md)（サンプル編）
