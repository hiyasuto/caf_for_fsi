# 08 — AI安全対策

> FISC実務基準（実150〜実153、第13版新設）→ Azure AI Governance

## 概要

FISC第13版で新設されたAI安全対策基準（実150〜実153）は、金融機関等におけるAI・生成AIの利用拡大に伴うリスクへの対応を求めています。Azure AIサービスとMicrosoftのResponsible AI（責任あるAI）の原則に基づく対策を示します。

## 1. 実150: AI利用に係る方針策定・態勢整備

**FISC要件**: AIの利用に係る方針の策定と態勢の整備を行うこと。

### Azure対応

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| AI利用ポリシー | Azure Policy + カスタムポリシー | AI サービスの利用制限・ガードレール |
| AIガバナンス | Azure AI Content Safety | 有害コンテンツの検出・フィルタリング |
| アクセス制御 | Microsoft Entra ID + RBAC | AIサービスへのアクセス権限管理 |
| 利用状況監視 | Azure Monitor + AI サービスログ | AI利用の監査ログ・利用状況レポート |

### Microsoft Responsible AI の6原則

| 原則 | 説明 | FISC対応 |
|------|------|---------|
| 公平性 | バイアスの最小化 | 実150（方針策定） |
| 信頼性と安全性 | 信頼できるAIの構築 | 実152（安全対策） |
| プライバシーとセキュリティ | データの保護 | 実152（安全対策） |
| 包括性 | すべてのユーザーへの配慮 | 実150（方針策定） |
| 透明性 | AIの判断の説明可能性 | 実151（運用管理） |
| アカウンタビリティ | 責任の明確化 | 実150（態勢整備） |

## 2. 実151: AI適切な運用管理方法

**FISC要件**: AIの適切な運用管理方法を定めること。

### Azure対応

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| モデル管理 | Azure Machine Learning | モデルのバージョン管理・デプロイ管理 |
| プロンプト管理 | Azure AI Foundry | プロンプトテンプレートの管理・テスト |
| モニタリング | Azure AI Foundry（評価機能） | モデル出力の品質監視・ドリフト検出 |
| 監査ログ | Azure OpenAI 診断ログ | API呼び出し・入出力の監査ログ |
| データガバナンス | Microsoft Purview | AI学習データの分類・リネージ管理 |

### 生成AI利用のリスク管理

```
┌──────────────────────────────────────────────┐
│           生成AI利用のリスク管理               │
│                                              │
│  入力制御           処理制御          出力制御  │
│  ┌──────┐         ┌──────┐        ┌──────┐  │
│  │プロンプ│         │モデル │        │コンテ │  │
│  │トイン │         │選択・ │        │ンツフ │  │
│  │ジェク │         │設定   │        │ィルタ │  │
│  │ション │         │       │        │リング │  │
│  │対策   │         │       │        │       │  │
│  └──────┘         └──────┘        └──────┘  │
│     │                │               │       │
│     ▼                ▼               ▼       │
│  Azure AI           Azure OpenAI    Azure AI  │
│  Content Safety     (APIキー制御)   Content   │
│  (入力フィルタ)      (トークン制限)  Safety   │
│                                    (出力フィルタ)│
└──────────────────────────────────────────────┘
```

## 3. 実152: AIに係る安全対策

**FISC要件**: AIに係る安全対策を講ずること。

### Azure対応

| リスク | 対策 | Azureサービス |
|-------|------|-------------|
| データ漏えい | AIへの機密データ入力制御 | Azure AI Content Safety、Microsoft Purview DLP |
| ハルシネーション | RAG（検索拡張生成）による根拠付け | Azure AI Search + Azure OpenAI |
| プロンプトインジェクション | 入力検証・サニタイズ | Azure AI Content Safety（Prompt Shields） |
| モデルの悪用 | アクセス制御・利用制限 | Microsoft Entra ID、Azure API Management（レート制限） |
| バイアス・公平性 | モデル評価・テスト | Azure AI Foundry（評価機能） |
| 知的財産リスク | 著作権フィルタリング | Azure OpenAI（著作権フィルター） |

### Azure OpenAI のセキュリティ機能

| 機能 | 説明 |
|------|------|
| データプライバシー | 入力データはモデル学習に使用されない |
| データ所在地 | 日本リージョンでのデータ処理 |
| コンテンツフィルタリング | 有害コンテンツの自動フィルタリング |
| 不正利用監視 | Microsoft による不正利用モニタリング |
| カスタマーロックボックス | Microsoftサポートによるデータアクセス時の顧客承認 |

## 4. 実153: AI利用に係る教育・注意喚起

**FISC要件**: AIの利用に係る教育、注意喚起等を行うこと。

### Azure対応

| 対策 | 内容 |
|------|------|
| 教育コンテンツ | Microsoft Learn - Responsible AI モジュール |
| 利用ガイドライン | Azure OpenAI利用ガイドライン・ベストプラクティス |
| 注意喚起 | 生成AI出力の検証義務の周知（ハルシネーションリスク） |
| 利用規約 | Azure OpenAI 利用規約の組織内周知 |

## 参考リンク

- [Azure AI サービス](https://learn.microsoft.com/azure/ai-services/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
- [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/)
- [Microsoft Responsible AI](https://www.microsoft.com/ai/responsible-ai)
- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/)


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [09. 監査](09-audit.md) | システム監査・サイバーセキュリティ監査 |
| → | [AI・生成AI基盤 ランディングゾーン](../landing-zone/ai-platform.md) | AI基盤の詳細アーキテクチャ・Azure AI Foundry の設計 |
| → | [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md) | 各ランディングゾーンへの FISC 基準適用要件 |